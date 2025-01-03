open Graphjs_base

exception Timeout
exception Exn of (Fmt.t -> unit)

open struct
  let raise (fmt : ('b, Fmt.t, unit, 'a) format4) : 'b =
    let raise_f acc = raise (Exn acc) in
    Fmt.kdly (fun acc -> raise_f (fun ppf -> Log.fmt_error ppf "%t" acc)) fmt
end

module DotNode = struct
  type t = Node.t

  let hash = Node.hash
  let equal = Node.equal
  let compare = Node.compare
end

module DotEdge = struct
  type t = Edge.t

  let default = Edge.default ()
  let compare = Edge.compare
end

module GraphBuilder =
  Graph.Persistent.Digraph.ConcreteBidirectionalLabeled (DotNode) (DotEdge)

module Dot = struct
  let mdg : Mdg.t option ref = ref None
  let set_info (mdg' : Mdg.t) : unit = mdg := Some mdg'
  let ( ! ) (mdg : Mdg.t option ref) : Mdg.t = Option.get !mdg

  let node_label (node : Node.t) : string =
    match node.kind with
    | Literal -> Fmt.str "{ Literal Object }"
    | TaintSource -> Fmt.str "{ Taint Source }"
    | Object name -> Fmt.str "%s" (String.escaped name)
    | Function name -> Fmt.str "function %s" (String.escaped name)
    | Parameter name -> Fmt.str "%s" (String.escaped name)
    | Call name -> Fmt.str "%s(...)" (String.escaped name)
    | Return name -> Fmt.str "%s" (String.escaped name)
    | Require name -> Fmt.str "require '%s'" (String.escaped name)
    | TaintSink sink -> Fmt.str "%s sink" Tainted.(name !sink)

  let edge_label (edge : Edge.t) : string =
    let prop_f = Option.fold ~none:"*" ~some:String.escaped in
    match edge.kind with
    | Dependency -> Fmt.str "D"
    | Property prop -> Fmt.str "P(%s)" (prop_f prop)
    | Version prop -> Fmt.str "V(%s)" (prop_f prop)
    | Parameter 0 -> Fmt.str "this"
    | Parameter idx -> Fmt.str "Param:%d" idx
    | Argument 0 -> Fmt.str "[[this]]"
    | Argument idx -> Fmt.str "Arg:%d" idx
    | Return -> Fmt.str "Ret"
    | Returns -> Fmt.str "Returns"
    | Call -> Fmt.str "Call"

  include Graph.Graphviz.Dot (struct
    include GraphBuilder

    let graph_attributes (_ : t) = []

    let default_vertex_attributes (_ : t) =
      [ `Shape `Box; `Style `Rounded; `Style `Filled; `Penwidth 1.3
      ; `Fontsize 18; `Fontname "Garamond" ]

    let default_edge_attributes (_ : t) =
      [ `Arrowhead `Normal; `Fontsize 16; `Fontname "Times-Roman" ]

    let vertex_attributes (node : V.t) : 'a list =
      `Label (node_label node)
      ::
      ( match node.kind with
      | Literal -> [ `Color 26214; `Fillcolor 13434879 ]
      | TaintSource -> [ `Color 6684672; `Fillcolor 16764108 ]
      | Object _ when Node.is_literal_object node ->
        [ `Color 26214; `Fillcolor 13434879 ]
      | Object _ -> [ `Color 2105376; `Fillcolor 14737632 ]
      | Function _ -> [ `Color 26112; `Fillcolor 52224 ]
      | Parameter "this" -> [ `Color 6684774; `Fillcolor 16764159 ]
      | Parameter _ -> [ `Color 26112; `Fillcolor 13434828 ]
      | Call _ -> [ `Color 6697728; `Fillcolor 13395456 ]
      | Return _ -> [ `Color 6697728; `Fillcolor 16770508 ]
      | Require _ -> [ `Color 3342438; `Fillcolor 15060223 ]
      | TaintSink _ -> [ `Color 6684672; `Fillcolor 16724787 ] )

    let edge_attributes ((_, edge, _) : Node.t * Edge.t * Node.t) : 'a list =
      `Label (edge_label edge)
      ::
      ( match edge.kind with
      | (Dependency | Argument _) when Node.is_literal edge.src ->
        [ `Style `Dotted; `Color 26214; `Fontcolor 26214 ]
      | Dependency when Node.is_taint_source edge.src ->
        [ `Style `Dotted; `Color 6684672; `Fontcolor 6684672 ]
      | Dependency when Node.is_require edge.src ->
        [ `Style `Dotted; `Color 3342438; `Fontcolor 3342438 ]
      | Parameter 0 -> [ `Color 6684774; `Fontcolor 6684774 ]
      | Parameter _ -> [ `Color 26112; `Fontcolor 26112 ]
      | Returns -> [ `Style `Dotted; `Color 26112; `Fontcolor 26112 ]
      | Return -> [ `Color 6697728; `Fontcolor 6697728 ]
      | Call -> [ `Color 6697728; `Fontcolor 6697728 ]
      | _ -> [ `Color 2105376 ] )

    let vertex_name (node : V.t) = Location.str node.uid

    (* TODO: set each function to its own subgraph *)
    let get_subgraph _ = None
  end)
end

open struct
  let build_graph_edges_f (edge : Edge.t) (graph : GraphBuilder.t) :
      GraphBuilder.t =
    match edge.kind with
    | Dependency when Node.is_parameter edge.tar -> graph
    | Argument 0 -> graph
    | _ ->
      let e = GraphBuilder.E.create edge.src edge edge.tar in
      GraphBuilder.add_edge_e graph e

  let build_graph_nodes_f (mdg : Mdg.t) (loc : Location.t) (node : Node.t)
      (graph : GraphBuilder.t) : GraphBuilder.t =
    let graph' = GraphBuilder.add_vertex graph node in
    let edges = Mdg.get_edges mdg loc in
    Edge.Set.fold build_graph_edges_f edges graph'
end

let build_graph (mdg : Mdg.t) : GraphBuilder.t =
  Dot.set_info mdg;
  Hashtbl.fold (build_graph_nodes_f mdg) mdg.nodes GraphBuilder.empty

let output_dot (path : string) (graph : GraphBuilder.t) : unit =
  let dot_file = open_out_bin path in
  Dot.output_graph dot_file graph;
  close_out_noerr dot_file

let output_svg (path : string) (dot_path : string) : unit =
  try
    if Sys.command ("timeout 20 dot -Tsvg " ^ dot_path ^ " -o " ^ path) != 0
    then raise "Unable to generate the %S file." path
  with _ -> Stdlib.raise Timeout

let export_dot (path : Fpath.t) (mdg : Mdg.t) : unit =
  let graph = build_graph mdg in
  output_dot (Fpath.to_string path) graph

let export_svg (path : Fpath.t) : [> `Dot of Fpath.t | `Mdg of Mdg.t ] -> unit =
  function
  | `Dot dot_path ->
    output_svg (Fpath.to_string path) (Fpath.to_string dot_path)
  | `Mdg mdg ->
    let dot_path = Filename.temp_file "graphjs" "dot" in
    let graph = build_graph mdg in
    output_dot dot_path graph;
    output_svg (Fpath.to_string path) dot_path
