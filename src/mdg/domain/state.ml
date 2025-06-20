open Graphjs_ast

module Env = struct
  type t =
    { unfold_depth : int
    ; reset_locations : bool
    ; run_exported_analysis : bool
    ; run_tainted_analysis : bool
    ; run_cleaner_analysis : bool
    ; cb_mdg_file : Fpath.t -> unit
    }

  let default =
    let dflt =
      { unfold_depth = 1
      ; reset_locations = true
      ; run_exported_analysis = true
      ; run_tainted_analysis = true
      ; run_cleaner_analysis = true
      ; cb_mdg_file = (fun _ -> ())
      } in
    fun () -> dflt
end

type t =
  { env : Env.t
  ; mdg : Mdg.t
  ; store : Store.t
  ; pcontext : Region.t Pcontext.t
  ; allocator : Node.t Allocator.t
  ; jslib : Jslib.t
  ; npmlib : Npmlib.t
  ; function_interceptors : (Location.t, call_interceptor) Hashtbl.t
  ; method_interceptors : method_interceptor list ref
  ; curr_floc : Pcontext.Floc.t
  ; curr_stack : Node.t list
  ; curr_parent : Node.t option
  ; curr_return : Node.Set.t
  }

and call_interceptor =
     t
  -> Region.t LeftValue.t
  -> Region.t Expression.t list
  -> string
  -> Allocator.cid
  -> Node.t
  -> Node.Set.t list
  -> t

and method_interceptor_matcher =
  t -> Node.t -> Node.Set.t list -> Property.t -> bool

and method_interceptor = method_interceptor_matcher * call_interceptor

let create (env' : Env.t) (jsmodel : Jsmodel.t) (prog : 'm Prog.t) : t =
  let mdg' = Mdg.create () in
  let store' = Store.create () in
  let pcontext' = Pcontext.create prog in
  { env = env'
  ; mdg = mdg'
  ; store = store'
  ; pcontext = pcontext'
  ; allocator = Allocator.create Config.(!dflt_htbl_sz)
  ; jslib = Jslib.create mdg' store' pcontext' jsmodel
  ; npmlib = Npmlib.create jsmodel
  ; function_interceptors = Hashtbl.create Config.(!dflt_htbl_sz)
  ; method_interceptors = ref []
  ; curr_floc = Pcontext.Floc.default ()
  ; curr_stack = []
  ; curr_parent = None
  ; curr_return = Node.Set.empty
  }

let initialize (state : t) (path : Fpath.t) (mrel : Fpath.t) (main : bool)
    (l_parent : Node.t option) : t =
  let file = if main then None else Some mrel in
  let store' = Store.extend_block state.store in
  Jslib.initialize state.mdg store' state.jslib file l_parent;
  { state with
    store = store'
  ; curr_floc = Pcontext.Floc.create path mrel main
  ; curr_stack = []
  ; curr_parent = l_parent
  ; curr_return = Node.Set.empty
  }

let extend_block (state : t) : t =
  { state with store = Store.extend_block state.store }

let extend_func (state : t) (store : Store.t) : t =
  let store' = if Store.within store state.store then state.store else store in
  { state with store = Store.extend_func store' }

let reduce_func (state : t) (state1 : t) : t =
  let store = Store.reduce_func state.store state1.store in
  { state with store }

let reduce_option (state : t) (state1 : t) : t =
  let store = Store.reduce_option state.store state1.store in
  let curr_return = Node.Set.union state.curr_return state1.curr_return in
  { state with store; curr_return }

let reduce_branch (state : t) (state1 : t) (state2 : t) : t =
  let store = Store.reduce_branch state.store state1.store state2.store in
  let curr_return = Node.Set.union state1.curr_return state2.curr_return in
  { state with store; curr_return }

type cid = Allocator.cid

let get_node (state : t) (cid : cid) : Node.t =
  match Allocator.find_opt state.allocator cid with
  | Some node -> node
  | None ->
    let at = Allocator.at cid in
    Log.fail "expecting node of region '%a' in allocator" Region.pp at

let add_node (state : t) (cid : cid)
    (create_node_f : Node.t option -> Region.t -> Node.t) : Node.t =
  match Allocator.find_opt state.allocator cid with
  | Some node -> node
  | None ->
    let node = create_node_f state.curr_parent (Allocator.at cid) in
    Allocator.replace state.allocator cid node;
    Mdg.add_node state.mdg node;
    node

let add_edge (state : t) (src : Node.t) (tar : Node.t)
    (create_edge_f : Node.t -> Node.t -> Edge.t) : Edge.t =
  let edge = create_edge_f src tar in
  Mdg.add_edge state.mdg edge;
  edge

let add_literal_node (state : t) (cid : cid) (literal : Literal.t) : Node.t =
  add_node state cid (Node.create_literal literal)

let add_blank_node (state : t) (cid : cid) (name : string) : Node.t =
  add_node state cid (Node.create_blank name)

let add_object_node (state : t) (cid : cid) (name : string) : Node.t =
  add_node state cid (Node.create_object name)

let add_function_node (state : t) (cid : cid) (name : string) : Node.t =
  add_node state cid (Node.create_function name)

let add_parameter_node (state : t) (cid : cid) (name : string) : Node.t =
  add_node state cid (Node.create_parameter name)

let add_call_node (state : t) (cid : cid) (name : string) : Node.t =
  add_node state cid (Node.create_call name)

let add_return_node (state : t) (cid : cid) (name : string) : Node.t =
  add_node state cid (Node.create_return name)

let add_module_node (state : t) (cid : cid) (name : string) : Node.t =
  add_node state cid (Node.create_module name)

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

let add_meta_edge (state : t) (src : Node.t) (tar : Node.t) (meta : string) :
    unit =
  add_edge state src tar (Edge.create_meta meta) |> ignore

let get_function_interceptor (state : t) (node : Node.t) :
    call_interceptor option =
  Hashtbl.find_opt state.function_interceptors node.loc

let set_function_interceptor (state : t) (node : Node.t)
    (interceptor : call_interceptor) : unit =
  Hashtbl.replace state.function_interceptors node.loc interceptor

let get_method_interceptor (state : t) (l_func : Node.t)
    (ls_args : Node.Set.t list) (prop : Property.t) : call_interceptor option =
  let matcher_f (matcher, _) = matcher state l_func ls_args prop in
  List.find_opt matcher_f !(state.method_interceptors) |> Option.map snd

let set_method_interceptor (state : t) (matcher : method_interceptor_matcher)
    (interceptor : call_interceptor) : unit =
  let interceptor' = (matcher, interceptor) in
  state.method_interceptors := interceptor' :: !(state.method_interceptors)
