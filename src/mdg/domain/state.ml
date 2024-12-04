open Graphjs_base
open Graphjs_ast

module CodeCache = struct
  type id = Region.t Statement.t * int
  type t = (id, Node.t) Hashtbl.t

  let cid (stmt : Region.t Statement.t) : id = (stmt, 0)
  let offset (id : id) (offset : int) : id = (fst id, offset)
  let at (id : id) : Region.t = Metadata.md (fst id)
  let create () : t = Hashtbl.create Config.(!dflt_htbl_sz)
  let copy (cache : t) : t = Hashtbl.copy cache
  let find (cache : t) (id : id) : Node.t option = Hashtbl.find_opt cache id

  let add (cache : t) (id : id) (node : Node.t) : unit =
    Hashtbl.replace cache id node

  let lub (cache1 : t) (cache2 : t) : unit =
    Fun.flip Hashtbl.iter cache2 @@ fun stmt node_2 ->
    let node_1 = Hashtbl.find_opt cache1 stmt in
    if Option.is_none node_1 then Hashtbl.replace cache1 stmt node_2
end

type t =
  { mdg : Mdg.t
  ; store : Store.t
  ; literal : Node.t
  ; code_cache : CodeCache.t
  ; curr_func : Node.t option
  }

let create () : t =
  let mdg = Mdg.create () in
  let store = Store.create () in
  let literal = Node.create_literal () in
  let code_cache = CodeCache.create () in
  let curr_func = None in
  { mdg; store; literal; code_cache; curr_func }

let copy (state : t) : t =
  let mdg = Mdg.copy state.mdg in
  let store = Store.copy state.store in
  let literal = state.literal in
  let code_cache = Hashtbl.copy state.code_cache in
  let curr_func = state.curr_func in
  { mdg; store; literal; code_cache; curr_func }

let lub (state1 : t) (state2 : t) : t =
  Mdg.lub state1.mdg state2.mdg;
  Store.lub state1.store state2.store;
  CodeCache.lub state1.code_cache state2.code_cache;
  state1

let add_node (state : t) (create_node_f : Region.t -> Node.t option -> Node.t)
    (region : Region.t) (id : CodeCache.id) : Node.t =
  match CodeCache.find state.code_cache id with
  | Some node -> node
  | None ->
    let node = create_node_f region state.curr_func in
    Mdg.add_node state.mdg node;
    CodeCache.add state.code_cache id node;
    node

let add_edge (state : t) (create_edge_f : Node.t -> Node.t -> Edge.t)
    (src : Node.t) (tar : Node.t) : unit =
  let edge = create_edge_f src tar in
  Mdg.add_edge state.mdg src edge

let add_object_node (state : t) (id : CodeCache.id) (name : string) : Node.t =
  add_node state (Node.create_object name) (CodeCache.at id) id
[@@inline]

let add_function_node (state : t) (id : CodeCache.id) (name : string) : Node.t =
  add_node state (Node.create_function name) (CodeCache.at id) id
[@@inline]

let add_parameter_node (state : t) (id : CodeCache.id) (idx : int)
    (name : string) : Node.t =
  add_node state (Node.create_parameter idx name) (CodeCache.at id) id
[@@inline]

let add_call_node (state : t) (id : CodeCache.id) (name : string) : Node.t =
  add_node state (Node.create_call name) (CodeCache.at id) id
[@@inline]

let add_return_node (state : t) (id : CodeCache.id) (name : string) : Node.t =
  add_node state (Node.create_return name) (CodeCache.at id) id
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
