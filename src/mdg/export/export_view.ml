open Graphjs_base

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

module Default = struct
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

module Function = struct
  let get_function (mdg : Mdg.t) (uid : Location.t) : Node.t =
    let l_func = get_node mdg uid in
    match l_func.kind with
    | Function _ -> l_func
    | _ -> raise "Unexpected non-function node '%a'" Node.pp l_func

  let in_function (l_func : Node.t) (node : Node.t) : bool =
    Node.equal l_func node || Option.equal Node.equal (Some l_func) node.parent

  let build_graph_node (l_func : Node.t) (node : Node.t) (graph : G.t) : G.t =
    if in_function l_func node then G.add_vertex graph node else graph

  let build_graph_edge (l_func : Node.t) (edge : Edge.t) (graph : G.t) : G.t =
    if in_function l_func edge.src || in_function l_func edge.tar then
      G.add_edge_e graph (G.E.create edge.src edge edge.tar)
    else graph

  let build_graph (mdg : Mdg.t) (loc : Location.t) : G.t =
    let l_node = get_function mdg loc in
    Hashtbl.fold (fun _ -> build_graph_node l_node) mdg.nodes G.empty
    |> Hashtbl.fold (fun _ -> Edge.Set.fold (build_graph_edge l_node)) mdg.edges
end

module Flow = struct
  type worklist = Node.t Queue.t
  type visited = (Location.t, unit) Hashtbl.t

  let visit_f (_ : Edge.t) : bool = true
  let node_f (node : Node.t) (graph : G.t) : G.t = G.add_vertex graph node

  let edge_f (tran : Edge.t) (graph : G.t) : G.t =
    let edge = Edge.transpose tran in
    G.add_edge_e graph (G.E.create edge.src edge edge.tar)

  let build_graph (mdg : Mdg.t) (loc : Location.t) : G.t =
    let node = get_node mdg loc in
    Mdg.visit_backwards visit_f node_f edge_f mdg node G.empty
end

module Object = struct
  type worklist = Node.t Queue.t
  type visited = (Location.t, unit) Hashtbl.t

  let get_object (mdg : Mdg.t) (uid : Location.t) : Node.t =
    let l_obj = get_node mdg uid in
    match l_obj.kind with
    | Object _ | Function _ | Parameter _ | Return _ -> l_obj
    | _ -> raise "Unexpected non-object node '%a'" Node.pp l_obj

  let visit_f (edge : Edge.t) : bool =
    match edge.kind with Property _ | Version _ -> true | _ -> false

  let node_f (node : Node.t) (graph : G.t) : G.t = G.add_vertex graph node

  let edge_f (edge : Edge.t) (graph : G.t) : G.t =
    G.add_edge_e graph (G.E.create edge.src edge edge.tar)

  let build_graph (mdg : Mdg.t) (loc : Location.t) : G.t =
    let node = get_object mdg loc in
    Mdg.visit_forwards visit_f node_f edge_f mdg node G.empty
end
