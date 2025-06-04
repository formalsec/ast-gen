exception Exn of (Fmt.t -> unit)

let raise (fmt : ('b, Fmt.t, unit, 'a) format4) : 'b =
  let raise_f acc = raise (Exn acc) in
  let err_f acc = fun ppf -> Log.fmt_error ppf "%t for export view." acc in
  Fmt.kdly (fun acc -> raise_f (err_f acc)) fmt

let get_node (mdg : Mdg.t) (loc : Location.t) : Node.t =
  try Mdg.get_node mdg loc
  with _ -> raise "Non-existing node location '%a'" Location.pp loc

module GraphNode = struct
  type t = Node.t

  let hash = Node.hash
  let equal = Node.equal
  let compare = Node.compare
end

module GraphEdge = struct
  type t = Edge.t

  let default = Edge.default ()
  let compare = Edge.compare
end

module G =
  Graph.Persistent.Digraph.ConcreteBidirectionalLabeled (GraphNode) (GraphEdge)

type t =
  | Full
  | Calls
  | Object of Location.t
  | Parent of Location.t
  | Reaches of Location.t
  | Sinks
  | Tainted of Node.Set.t

module Full = struct
  let build_graph_node (node : Node.t) (graph : G.t) : G.t =
    G.add_vertex graph node

  let build_graph_edge (edge : Edge.t) (graph : G.t) : G.t =
    G.add_edge_e graph (G.E.create edge.src edge edge.tar)

  let build_graph (mdg : Mdg.t) : G.t =
    Hashtbl.fold (fun _ -> build_graph_node) mdg.nodes G.empty
    |> Hashtbl.fold (fun _ -> Edge.Set.fold build_graph_edge) mdg.edges
end

module Calls = struct
  let build_graph_node (node : Node.t) (graph : G.t) : G.t =
    match node.kind with
    | Function _ | Call _ -> G.add_vertex graph node
    | _ -> graph

  let build_graph_edge (edge : Edge.t) (graph : G.t) : G.t =
    match edge.kind with
    | Caller -> G.add_edge_e graph (G.E.create edge.src edge edge.tar)
    | _ -> graph

  let build_graph (mdg : Mdg.t) : G.t =
    Hashtbl.fold (fun _ -> build_graph_node) mdg.nodes G.empty
    |> Hashtbl.fold (fun _ -> Edge.Set.fold build_graph_edge) mdg.edges
end

module Object = struct
  let get_object (mdg : Mdg.t) (loc : Location.t) : Node.t =
    let l_obj = get_node mdg loc in
    match l_obj.kind with
    | Call _ | TaintSink _ | TaintSource ->
      raise "Unexpected non-object node '%a'" Node.pp l_obj
    | _ -> l_obj

  let visit_f (edge : Edge.t) : bool =
    match edge.kind with Property _ | Version _ -> true | _ -> false

  let node_f (node : Node.t) (graph : G.t) : G.t = G.add_vertex graph node

  let edge_f (edge : Edge.t) (graph : G.t) : G.t =
    G.add_edge_e graph (G.E.create edge.src edge edge.tar)

  let build_graph (mdg : Mdg.t) (loc : Location.t) : G.t =
    let node = get_object mdg loc in
    Mdg.visit_forwards visit_f node_f edge_f mdg node G.empty
end

module Parent = struct
  let get_parent (mdg : Mdg.t) (loc : Location.t) : Node.t =
    let l_parent = get_node mdg loc in
    match l_parent.kind with
    | Function _ -> l_parent
    | Module _ -> l_parent
    | _ -> raise "Unexpected non-parent node '%a'" Node.pp l_parent

  let rec is_parent (l_parent : Node.t) (node : Node.t) : bool =
    if not (Node.equal l_parent node) then
      match node.parent with
      | None -> false
      | Some l_parent' when Node.equal l_parent l_parent' -> true
      | Some l_parent' -> is_parent l_parent' node
    else true

  let build_graph_node (l_func : Node.t) (node : Node.t) (graph : G.t) : G.t =
    if is_parent l_func node then G.add_vertex graph node else graph

  let build_graph_edge (l_func : Node.t) (edge : Edge.t) (graph : G.t) : G.t =
    if is_parent l_func edge.src || is_parent l_func edge.tar then
      G.add_edge_e graph (G.E.create edge.src edge edge.tar)
    else graph

  let build_graph (mdg : Mdg.t) (loc : Location.t) : G.t =
    let node = get_parent mdg loc in
    Hashtbl.fold (fun _ -> build_graph_node node) mdg.nodes G.empty
    |> Hashtbl.fold (fun _ -> Edge.Set.fold (build_graph_edge node)) mdg.edges
end

module Reaches = struct
  let visit_f (_ : Edge.t) : bool = true
  let node_f (node : Node.t) (graph : G.t) : G.t = G.add_vertex graph node

  let edge_f (tran : Edge.t) (graph : G.t) : G.t =
    let edge = Edge.transpose tran in
    G.add_edge_e graph (G.E.create edge.src edge edge.tar)

  let build_graph (mdg : Mdg.t) (loc : Location.t) : G.t =
    let node = get_node mdg loc in
    Mdg.visit_backwards visit_f node_f edge_f mdg node G.empty
end

module Sinks = struct
  let get_sinks (mdg : Mdg.t) : Node.t list =
    Fun.flip2 Hashtbl.fold mdg.nodes [] (fun _ node acc ->
        if Node.is_taint_sink node then node :: acc else acc )

  let visit_f (_ : Edge.t) : bool = true
  let node_f (node : Node.t) (graph : G.t) : G.t = G.add_vertex graph node

  let edge_f (tran : Edge.t) (graph : G.t) : G.t =
    let edge = Edge.transpose tran in
    G.add_edge_e graph (G.E.create edge.src edge edge.tar)

  let build_graph (mdg : Mdg.t) : G.t =
    let nodes = get_sinks mdg in
    Mdg.visit_multiple_backwards visit_f node_f edge_f mdg nodes G.empty
end

module Tainted = struct
  let get_tainted (mdg : Mdg.t) (ls_tainted : Node.Set.t) : Node.Set.t =
    Node.Set.filter (fun l_tainted -> Mdg.has_node mdg l_tainted.loc) ls_tainted

  let build_graph_node (node : Node.t) (graph : G.t) : G.t =
    G.add_vertex graph node

  let build_graph_edge (mdg : Mdg.t) (node : Node.t) (graph : G.t) : G.t =
    let edges = Mdg.get_edges mdg node.loc in
    Fun.flip2 Edge.Set.fold edges graph (fun edge graph ->
        G.add_edge_e graph (G.E.create edge.src edge edge.tar) )

  let build_graph (mdg : Mdg.t) (ls_tainted : Node.Set.t) : G.t =
    let ls_tainted' = get_tainted mdg ls_tainted in
    Node.Set.fold build_graph_node ls_tainted' G.empty
    |> Node.Set.fold (build_graph_edge mdg) ls_tainted'
end
