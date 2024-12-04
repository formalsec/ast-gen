open Graphjs_base
open Graphjs_ast

type t =
  { mdg : Mdg.t
  ; store : Store.t
  ; literal : Node.t
  ; cached_nodes : (Region.t, Node.t) Hashtbl.t
  ; curr_func : Node.t option
  }

let create () : t =
  let mdg = Mdg.create () in
  let store = Store.create () in
  let literal = Node.create_literal () in
  let cached_nodes = Hashtbl.create Config.(!dflt_htbl_sz) in
  let curr_func = None in
  { mdg; store; literal; cached_nodes; curr_func }

let copy (state : t) : t =
  let mdg = Mdg.copy state.mdg in
  let store = Store.copy state.store in
  let literal = state.literal in
  let cached_nodes = Hashtbl.copy state.cached_nodes in
  let curr_func = state.curr_func in
  { mdg; store; literal; cached_nodes; curr_func }

let lub_cached_nodes (cache1 : (Region.t, Node.t) Hashtbl.t)
    (cache2 : (Region.t, Node.t) Hashtbl.t) : unit =
  Fun.flip Hashtbl.iter cache2 @@ fun stmt node_2 ->
  let node_1 = Hashtbl.find_opt cache1 stmt in
  if Option.is_none node_1 then Hashtbl.replace cache1 stmt node_2

let lub (state1 : t) (state2 : t) : t =
  lub_cached_nodes state1.cached_nodes state2.cached_nodes;
  Mdg.lub state1.mdg state2.mdg;
  Store.lub state1.store state2.store;
  state1

let add_node (state : t) (create_node_f : Region.t -> Node.t option -> Node.t)
    (region : Region.t) : Node.t =
  match Hashtbl.find_opt state.cached_nodes region with
  | Some node -> node
  | None ->
    let node = create_node_f region state.curr_func in
    Mdg.add_node state.mdg node;
    Hashtbl.replace state.cached_nodes region node;
    node

let add_edge (state : t) (create_edge_f : Node.t -> Node.t -> Edge.t)
    (src : Node.t) (tar : Node.t) : unit =
  let edge = create_edge_f src tar in
  Mdg.add_edge state.mdg src edge

let add_object_node (state : t) (region : Region.t) (name : string) : Node.t =
  add_node state (Node.create_object name) region
[@@inline]

let add_function_node (state : t) (region : Region.t) (name : string)
    (params : string list) : Node.t =
  add_node state (Node.create_function name params) region
[@@inline]

let add_parameter_node (state : t) (region : Region.t) (idx : int)
    (name : string) : Node.t =
  add_node state (Node.create_parameter idx name) region
[@@inline]

let add_call_node (state : t) (region : Region.t) (name : string) : Node.t =
  add_node state (Node.create_call name) region
[@@inline]

let add_return_node (state : t) (region : Region.t) (name : string) : Node.t =
  add_node state (Node.create_return name) region
[@@inline]

let add_dependency_edge (state : t) (src : Node.t) (tar : Node.t) : unit =
  add_edge state (Edge.create_dependency ()) src tar
[@@inline]

let add_property_edge (state : t) (src : Node.t) (tar : Node.t)
    (prop : string option) : unit =
  add_edge state (Edge.create_property prop) src tar
[@@inline]

let add_version_edge (state : t) (src : Node.t) (tar : Node.t)
    (prop : string option) : unit =
  add_edge state (Edge.create_version prop) src tar;
  add_edge state (Edge.create_ref_parent prop) tar src
[@@inline]

let add_parameter_edge (state : t) (idx : int) (src : Node.t) (tar : Node.t) :
    unit =
  add_edge state (Edge.create_parameter idx) src tar
[@@inline]

let add_argument_edge (state : t) (idx : int) (src : Node.t) (tar : Node.t) :
    unit =
  add_edge state (Edge.create_argument idx) src tar
[@@inline]

let add_ref_argument_edge (state : t) (src : Node.t) (tar : Node.t) : unit =
  add_edge state (Edge.create_ref_argument ()) src tar
[@@inline]

let add_return_edge (state : t) (src : Node.t) (tar : Node.t) : unit =
  add_edge state (Edge.create_return ()) src tar
[@@inline]

let add_ref_return_edge (state : t) (src : Node.t) (tar : Node.t) : unit =
  add_edge state (Edge.create_ref_return ()) src tar
[@@inline]

let add_call_edge (state : t) (src : Node.t) (tar : Node.t) : unit =
  add_edge state (Edge.create_call ()) src tar
[@@inline]
