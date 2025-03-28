open Graphjs_base
open Graphjs_ast

module Env = struct
  type t = { unsafe_literal_properties : bool }

  let default =
    let dflt = { unsafe_literal_properties = false } in
    fun () -> dflt
end

type t =
  { env : Env.t
  ; mdg : Mdg.t
  ; store : Store.t
  ; registry : Node.t Registry.t
  ; lookup_interceptors : (Location.t, lookup_interceptor) Hashtbl.t
  ; call_interceptors : (Location.t, call_interceptor) Hashtbl.t
  ; curr_func : Node.t option
  }

and lookup_interceptor =
  t -> Node.t -> string -> Node.Set.t -> Property.t -> Node.Set.t -> t

and call_interceptor =
     t
  -> Node.t
  -> Node.t
  -> Node.t
  -> Node.Set.t list
  -> Region.t Expression.t list
  -> Registry.cid
  -> t

let create (env' : Env.t) : t =
  { env = env'
  ; mdg = Mdg.create ()
  ; store = Store.create ()
  ; registry = Registry.create Config.(!dflt_htbl_sz)
  ; lookup_interceptors = Hashtbl.create Config.(!dflt_htbl_sz)
  ; call_interceptors = Hashtbl.create Config.(!dflt_htbl_sz)
  ; curr_func = None
  }

let initialize (state : t) : t =
  let mdg = Mdg.copy state.mdg in
  let store = Store.copy state.store in
  let registry = Registry.copy state.registry in
  let curr_func = None in
  { state with mdg; store; registry; curr_func }

let copy (state : t) : t =
  let mdg = Mdg.copy state.mdg in
  let store = Store.copy state.store in
  let registry = Registry.copy state.registry in
  { state with mdg; store; registry }

let join (state1 : t) (state2 : t) : t =
  let mdg = Mdg.join state1.mdg state2.mdg in
  let registry = Registry.lub state1.registry state2.registry in
  { state1 with mdg; registry }

let lub (state1 : t) (state2 : t) : t =
  let mdg = Mdg.lub state1.mdg state2.mdg in
  let store = Store.lub state1.store state2.store in
  let registry = Registry.lub state1.registry state2.registry in
  { state1 with mdg; store; registry }

let get_node (state : t) (id : Registry.cid) : Node.t =
  match Registry.find_opt state.registry id with
  | None ->
    let at = Registry.at id in
    Log.fail "expecting node of region '%a' in registry" Region.pp at
  | Some node -> node

let add_node (state : t) (id : Registry.cid)
    (create_node_f : Node.t option -> Region.t -> Node.t) : Node.t =
  match Registry.find_opt state.registry id with
  | Some node -> node
  | None ->
    let node = create_node_f state.curr_func (Registry.at id) in
    Registry.replace state.registry id node;
    Mdg.add_node state.mdg node;
    node

let add_edge (state : t) (src : Node.t) (tar : Node.t)
    (create_edge_f : Node.t -> Node.t -> Edge.t) : Edge.t =
  let edge = create_edge_f src tar in
  Mdg.add_edge state.mdg edge;
  edge

let add_object_node (st : t) (id : Registry.cid) (name : string) : Node.t =
  add_node st id (Node.create_object name)

let add_literal_object_node (state : t) (id : Registry.cid) (name : string) :
    Node.t =
  add_node state id (Node.create_literal_object name)

let add_function_node (state : t) (id : Registry.cid) (name : string) : Node.t =
  add_node state id (Node.create_function name)

let add_parameter_node (state : t) (id : Registry.cid) (idx : int)
    (name : string) : Node.t =
  add_node state id (Node.create_parameter idx name)

let add_call_node (state : t) (id : Registry.cid) (name : string) : Node.t =
  add_node state id (Node.create_call name)

let add_return_node (st : t) (id : Registry.cid) (name : string) : Node.t =
  add_node st id (Node.create_return name)

let add_import_node (state : t) (id : Registry.cid) (name : string) : t * Node.t
    =
  let node = add_node state id (Node.create_import name) in
  ({ state with mdg = Mdg.add_imports state.mdg node }, node)

let add_dependency_edge (state : t) (src : Node.t) (tar : Node.t) : unit =
  add_edge state src tar (Edge.create_dependency ()) |> ignore

let add_property_edge (state : t) (src : Node.t) (tar : Node.t)
    (prop : Property.t) : unit =
  add_edge state src tar (Edge.create_property prop) |> ignore

let add_version_edge (state : t) (src : Node.t) (tar : Node.t)
    (prop : Property.t) : unit =
  add_edge state src tar (Edge.create_version prop) |> ignore

let add_parameter_edge (state : t) (src : Node.t) (tar : Node.t) (idx : int) :
    unit =
  add_edge state src tar (Edge.create_parameter idx) |> ignore

let add_argument_edge (state : t) (src : Node.t) (tar : Node.t) (idx : int) :
    unit =
  add_edge state src tar (Edge.create_argument idx) |> ignore

let add_caller_edge (state : t) (src : Node.t) (tar : Node.t) : unit =
  add_edge state src tar (Edge.create_caller ()) |> ignore

let add_return_edge (state : t) (src : Node.t) (tar : Node.t) : unit =
  add_edge state src tar (Edge.create_return ()) |> ignore

let concretize_node (state : t) (id : string) (node : Node.t) : Node.t =
  let node' = Node.concretize node in
  Mdg.add_node state.mdg node';
  Store.replace state.store id (Node.Set.singleton node');
  node'

let get_lookup_interceptor (state : t) (node : Node.t) :
    lookup_interceptor option =
  Hashtbl.find_opt state.lookup_interceptors node.uid

let set_lookup_interceptor (state : t) (node : Node.t)
    (interceptor : lookup_interceptor) : unit =
  Hashtbl.replace state.lookup_interceptors node.uid interceptor

let get_call_interceptor (state : t) (node : Node.t) : call_interceptor option =
  Hashtbl.find_opt state.call_interceptors node.uid

let set_call_interceptor (state : t) (node : Node.t)
    (interceptor : call_interceptor) : unit =
  Hashtbl.replace state.call_interceptors node.uid interceptor
