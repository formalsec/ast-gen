open Graphjs_base

exception Exn of (Fmt.t -> unit)
exception Timeout

let raise (fmt : ('b, Fmt.t, unit, 'a) format4) : 'b =
  let raise_f acc = raise (Exn acc) in
  Fmt.kdly (fun acc -> raise_f (fun ppf -> Log.fmt_error ppf "%t" acc)) fmt

let timeout () : 'a = Stdlib.raise Timeout

module Env = struct
  type t =
    { subgraphs : bool
    ; timeout : int
    }

  let default =
    let dflt = { subgraphs = true; timeout = 30 } in
    fun () -> dflt
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

module G =
  Graph.Persistent.Digraph.ConcreteBidirectionalLabeled (DotNode) (DotEdge)

module Dot = struct
  let env = ref (Env.default ())
  let mdg = ref (Mdg.create ())
  let set_env (env' : Env.t) : unit = env := env'
  let set_mdg (mdg' : Mdg.t) : unit = mdg := mdg'

  let node_label (node : Node.t) : string =
    match node.kind with
    | Literal -> Fmt.str "{ Literal Object }"
    | Object name -> Fmt.str "%s" (String.escaped name)
    | Function name -> Fmt.str "function %s" (String.escaped name)
    | Parameter name -> Fmt.str "%s" (String.escaped name)
    | Call name -> Fmt.str "%s(...)" (String.escaped name)
    | Return name -> Fmt.str "%s" (String.escaped name)
    | Import name -> Fmt.str "import %s" (String.escaped name)
    | TaintSource -> Fmt.str "{ Taint Source }"
    | TaintSink sink -> Fmt.str "sink %s" Tainted.(name !sink)

  let edge_label (edge : Edge.t) : string =
    match edge.kind with
    | Dependency -> Fmt.str "D"
    | Property prop -> Fmt.str "P(%s)" (String.escaped (Property.str prop))
    | Version prop -> Fmt.str "V(%s)" (String.escaped (Property.str prop))
    | Parameter 0 -> Fmt.str "this"
    | Parameter idx -> Fmt.str "Param:%d" idx
    | Argument idx -> Fmt.str "Arg:%d" idx
    | Caller -> Fmt.str "Call"
    | Return -> Fmt.str "Return"

  let get_func (node : Node.t) : Node.t option =
    Option.bind (Node.func node) (fun l_func ->
        if Edge.Set.is_empty (Mdg.get_edges !mdg l_func.uid) then None
        else Some l_func )

  let rec func_depth (l_func : Node.t) : int =
    match l_func.parent with
    | None -> 1
    | Some l_func' -> func_depth l_func' + 1

  include Graph.Graphviz.Dot (struct
    include G

    type graph_attrs = Graph.Graphviz.DotAttributes.graph list
    type vertex_attrs = Graph.Graphviz.DotAttributes.vertex list
    type edge_attrs = Graph.Graphviz.DotAttributes.edge list
    type subgraph = Graph.Graphviz.DotAttributes.subgraph

    let graph_attributes (_ : t) : graph_attrs = []

    let default_vertex_attributes (_ : t) : vertex_attrs =
      [ `Shape `Box; `Style `Rounded; `Style `Filled; `Penwidth 1.3
      ; `Fontsize 18; `Fontname "Times-Roman" ]

    let default_edge_attributes (_ : t) : edge_attrs =
      [ `Arrowhead `Normal; `Fontsize 16; `Fontname "Times-Roman" ]

    let vertex_attributes (node : V.t) : vertex_attrs =
      `Label (node_label node)
      ::
      ( match node.kind with
      | Literal -> [ `Color 26214; `Fillcolor 13434879 ]
      | Object _ when Node.is_literal_object node ->
        [ `Color 26214; `Fillcolor 13434879 ]
      | Object _ -> [ `Color 2105376; `Fillcolor 12632256 ]
      | Function _ -> [ `Color 26112; `Fillcolor 52224 ]
      | Parameter "this" -> [ `Color 6684723; `Fillcolor 16764133 ]
      | Parameter _ -> [ `Color 26112; `Fillcolor 13434828 ]
      | Call _ -> [ `Color 6697728; `Fillcolor 13395456 ]
      | Return _ -> [ `Color 6697728; `Fillcolor 16770508 ]
      | Import _ -> [ `Color 3342438; `Fillcolor 15060223 ]
      | TaintSource -> [ `Color 6684672; `Fillcolor 16764108 ]
      | TaintSink _ -> [ `Color 6684672; `Fillcolor 16724787 ] )

    let edge_attributes ((_, edge, _) : Node.t * Edge.t * Node.t) : edge_attrs =
      `Label (edge_label edge)
      ::
      ( match edge.kind with
      | (Dependency | Argument _) when Node.is_literal edge.src ->
        [ `Style `Dotted; `Color 26214; `Fontcolor 26214 ]
      | Dependency when Node.is_return edge.tar ->
        [ `Style `Dotted; `Color 6697728; `Fontcolor 6697728 ]
      | Dependency when Node.is_import edge.src ->
        [ `Style `Dotted; `Color 3342438; `Fontcolor 3342438 ]
      | Dependency when Node.is_taint_source edge.src ->
        [ `Style `Dotted; `Color 6684672; `Fontcolor 6684672 ]
      | Parameter 0 -> [ `Color 6684723; `Fontcolor 6684723 ]
      | Parameter _ -> [ `Color 26112; `Fontcolor 26112 ]
      | Caller -> [ `Color 6697728; `Fontcolor 6697728 ]
      | Return -> [ `Style `Dotted; `Color 26112; `Fontcolor 26112 ]
      | _ -> [ `Color 2105376 ] )

    let vertex_name (node : V.t) : string = Location.str node.uid
    let subgraph_name (l_func : V.t) : string = Fmt.str "%d" (Node.uid l_func)

    let subgraph_color (l_func : V.t) : int =
      let depth = func_depth l_func in
      let factor = 0.2 +. (0.497 *. log (float_of_int depth)) in
      let light = 255.0 in
      let dark = 192.0 in
      let range = light -. dark in
      let color = int_of_float (light -. (range *. factor)) in
      (color lsl 16) + (color lsl 8) + color

    let subgraph_attrs (l_func : V.t) =
      [ `Shape `Box; `Style `Rounded; `Style `Filled; `Penwidth 1.3
      ; `Fillcolor (subgraph_color l_func) ]

    let get_subgraph (node : V.t) : subgraph option =
      match (!env.subgraphs, get_func node) with
      | (false, _) | (true, None) -> None
      | (true, Some l_func) ->
        let sg_name = subgraph_name l_func in
        let sg_attributes = subgraph_attrs l_func in
        let sg_parent = Option.map subgraph_name l_func.parent in
        Some { sg_name; sg_attributes; sg_parent }
  end)
end

let build_graph_edges (edge : Edge.t) (graph : G.t) : G.t =
  match edge.kind with
  | Argument 0 -> graph
  | _ ->
    let e = G.E.create edge.src edge edge.tar in
    G.add_edge_e graph e

let build_graph_nodes (mdg : Mdg.t) (loc : Location.t) (node : Node.t)
    (graph : G.t) : G.t =
  let graph' = G.add_vertex graph node in
  let edges = Mdg.get_edges mdg loc in
  Edge.Set.fold build_graph_edges edges graph'

let build_graph (mdg : Mdg.t) : G.t =
  Hashtbl.fold (build_graph_nodes mdg) mdg.nodes G.empty

let svg_cmd (env : Env.t) (svg : string) (dot : string) : string =
  Fmt.str "timeout %d dot -Tsvg %s -o %s 2>/dev/null" env.timeout dot svg

let output_dot (env : Env.t) (mdg : Mdg.t) (dot : string) (graph : G.t) : unit =
  let oc = open_out_bin dot in
  Dot.set_env env;
  Dot.set_mdg mdg;
  Dot.output_graph oc graph;
  close_out_noerr oc

let output_svg (env : Env.t) (svg : string) (dot : string) : unit =
  let cmd = svg_cmd env svg dot in
  match Sys.command cmd with
  | 0 -> ()
  | 124 -> timeout ()
  | _ -> raise "Unable to generate the %S file." svg

let export_dot ?(env = Env.default ()) (dot : Fpath.t) (mdg : Mdg.t) : unit =
  let graph = build_graph mdg in
  output_dot env mdg (Fpath.to_string dot) graph

let export_svg ?(env = Env.default ()) (svg : Fpath.t) :
    [> `Dot of Fpath.t | `Mdg of Mdg.t ] -> unit = function
  | `Dot dot -> output_svg env (Fpath.to_string svg) (Fpath.to_string dot)
  | `Mdg mdg ->
    let dot = Filename.temp_file "graphjs" "dot" in
    let graph = build_graph mdg in
    output_dot env mdg dot graph;
    output_svg env (Fpath.to_string svg) dot
