open Graphjs_base
open Graphjs_share
open Graphjs_ast

module Env = struct
  type func_eval_mode =
    | Opaque
    | Unfold
    | UnfoldRec
    | UnfoldDepth of int

  type t =
    { func_eval_mode : func_eval_mode
    ; run_cleaner_analysis : bool
    ; run_tainted_analysis : bool
    ; cb_mdg_file : Fpath.t -> unit
    }

  let default =
    let dflt =
      { func_eval_mode = Opaque
      ; run_cleaner_analysis = true
      ; run_tainted_analysis = true
      ; cb_mdg_file = (fun _ -> ())
      } in
    fun () -> dflt
end

type t =
  { env : Env.t
  ; mdg : Mdg.t
  ; store : Store.t
  ; allocator : Node.t Allocator.t
  ; pcontext : Region.t Pcontext.t
  ; jslib : Jslib.t
  ; npmlib : Npmlib.t
  ; call_interceptors : (Location.t, call_interceptor) Hashtbl.t
  ; curr_floc : Pcontext.Floc.t
  ; curr_stack : Node.t list
  ; curr_parent : Node.t option
  ; curr_return : Node.Set.t
  }

and call_interceptor = t -> string -> Node.t -> Node.Set.t list -> t

let create (env' : Env.t) (tconf : Taint_config.t) (prog : 'm Prog.t) : t =
  let mdg' = Mdg.create () in
  let store' = Store.create () in
  { env = env'
  ; mdg = mdg'
  ; store = store'
  ; allocator = Allocator.create Config.(!dflt_htbl_sz)
  ; pcontext = Pcontext.create prog store'
  ; jslib = Jslib.create tconf mdg' store'
  ; npmlib = Npmlib.create tconf
  ; call_interceptors = Hashtbl.create Config.(!dflt_htbl_sz)
  ; curr_floc = Pcontext.Floc.default ()
  ; curr_stack = []
  ; curr_parent = None
  ; curr_return = Node.Set.empty
  }

let initialize (state : t) (path : Fpath.t) (mrel : Fpath.t) (main : bool)
    (l_parent : Node.t option) : t =
  let file = if main then None else Some mrel in
  let store' = Store.copy state.pcontext.initial_store in
  Jslib.initialize state.mdg store' state.jslib file l_parent;
  { state with
    store = store'
  ; curr_floc = Pcontext.Floc.create path mrel main
  ; curr_stack = []
  ; curr_parent = l_parent
  ; curr_return = Node.Set.empty
  }

let copy (state : t) : t =
  let mdg = Mdg.copy state.mdg in
  let store = Store.copy state.store in
  { state with mdg; store }

let lub (state1 : t) (state2 : t) : t =
  let mdg = Mdg.lub state1.mdg state2.mdg in
  let store = Store.lub state1.store state2.store in
  let curr_return = Node.Set.union state1.curr_return state2.curr_return in
  { state1 with mdg; store; curr_return }

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

let get_call_interceptor (state : t) (node : Node.t) : call_interceptor option =
  Hashtbl.find_opt state.call_interceptors node.loc

let set_call_interceptor (state : t) (node : Node.t)
    (interceptor : call_interceptor) : unit =
  Hashtbl.replace state.call_interceptors node.loc interceptor
