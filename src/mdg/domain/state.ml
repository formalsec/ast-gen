open Graphjs_base
open Graphjs_ast

module Env = struct
  type t =
    { literal_mode : Literal.mode
    ; cb_mdg : Fpath.t -> unit
    }

  let default =
    let dflt = { literal_mode = Multiple; cb_mdg = (fun _ -> ()) } in
    fun () -> dflt
end

type t =
  { env : Env.t
  ; mdg : Mdg.t
  ; store : Store.t
  ; allocator : Node.t Allocator.t
  ; pcontext : Region.t Pcontext.t
  ; lookup_interceptors : (Location.t, lookup_interceptor) Hashtbl.t
  ; call_interceptors : (Location.t, call_interceptor) Hashtbl.t
  ; curr_path : Fpath.t
  ; curr_file : Fpath.t option
  ; curr_func : Node.t option
  ; literal_ctx : literal_ctx
  }

and lookup_interceptor =
  t -> Node.t -> string -> Node.Set.t -> Property.t -> Node.Set.t -> t

and call_interceptor =
  t -> string -> Node.t -> Node.t -> Node.t -> Node.Set.t list -> t

and literal_ctx =
  | Skip
  | Make
  | MakeProp

let create (env' : Env.t) (prog : 'm Prog.t) : t =
  let store' = Store.create () in
  { env = env'
  ; store = store'
  ; mdg = Mdg.create ()
  ; allocator = Allocator.create Config.(!dflt_htbl_sz)
  ; pcontext = Pcontext.create prog store'
  ; lookup_interceptors = Hashtbl.create Config.(!dflt_htbl_sz)
  ; call_interceptors = Hashtbl.create Config.(!dflt_htbl_sz)
  ; curr_path = Fpath.v "."
  ; curr_file = None
  ; curr_func = None
  ; literal_ctx = Make
  }

let initialize (state : t) (path : Fpath.t) (mrel : Fpath.t option) : t =
  let store = Store.copy state.pcontext.initial_store in
  let curr_path = path in
  let curr_file = mrel in
  let curr_func = None in
  let literal_ctx = Make in
  { state with store; curr_path; curr_file; curr_func; literal_ctx }

let copy (state : t) : t =
  let mdg = Mdg.copy state.mdg in
  let store = Store.copy state.store in
  { state with mdg; store }

let lub (state1 : t) (state2 : t) : t =
  let mdg = Mdg.lub state1.mdg state2.mdg in
  let store = Store.lub state1.store state2.store in
  let allocator = Allocator.lub state1.allocator state2.allocator in
  { state1 with mdg; store; allocator }

let skip_literal (state : t) : t = { state with literal_ctx = Skip }
let make_literal (state : t) : t = { state with literal_ctx = Make }
let make_literal_prop (state : t) : t = { state with literal_ctx = MakeProp }

type cid = Allocator.cid

let get_node (state : t) (cid : cid) : Node.t =
  match Allocator.find_opt state.allocator cid with
  | None ->
    let at = Allocator.at cid in
    Log.fail "expecting node of region '%a' in allocator" Region.pp at
  | Some node -> node

let add_node (state : t) (cid : cid)
    (create_node_f : Node.t option -> Region.t -> Node.t) : Node.t =
  match Allocator.find_opt state.allocator cid with
  | Some node -> node
  | None ->
    let node = create_node_f state.curr_func (Allocator.at cid) in
    Allocator.replace state.allocator cid node;
    Mdg.add_node state.mdg node;
    node

let add_candidate_node (state : t) (cid : cid)
    (create_node_f : Node.t option -> Region.t -> Node.t) : Node.t =
  match Allocator.find_opt state.allocator cid with
  | Some node -> node
  | None ->
    let node = create_node_f state.curr_func (Allocator.at cid) in
    Allocator.replace state.allocator cid node;
    node

let add_edge (state : t) (src : Node.t) (tar : Node.t)
    (create_edge_f : Node.t -> Node.t -> Edge.t) : Edge.t =
  let edge = create_edge_f src tar in
  Mdg.add_edge state.mdg edge;
  edge

let add_object_node (st : t) (cid : cid) (name : string) : Node.t =
  add_node st cid (Node.create_object name)

let add_literal_node (state : t) (cid : cid) (literal : Literal.t) : Node.t =
  add_node state cid (Node.create_literal literal)

let add_function_node (state : t) (cid : cid) (name : string) : Node.t =
  add_node state cid (Node.create_function name)

let add_parameter_node (state : t) (cid : cid) (idx : int) (name : string) :
    Node.t =
  add_node state cid (Node.create_parameter idx name)

let add_call_node (state : t) (cid : cid) (name : string) : Node.t =
  add_node state cid (Node.create_call name)

let add_return_node (st : t) (cid : cid) (name : string) : Node.t =
  add_node st cid (Node.create_return name)

let add_candidate_literal_node (state : t) (cid : cid) (literal : Literal.t) :
    Node.t =
  add_candidate_node state cid (Node.create_candidate_literal literal)

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
