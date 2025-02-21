open Graphjs_base
open Graphjs_ast

exception Exn of (Fmt.t -> unit)

let raise (fmt : ('b, Fmt.t, unit, 'a) format4) : 'b =
  let raise_f acc = raise (Exn acc) in
  Fmt.kdly (fun acc -> raise_f (fun ppf -> Log.fmt_error ppf "%t" acc)) fmt

module CodeCache = struct
  type id = Region.t Statement.t * int
  type t = (id, Node.t) Hashtbl.t

  let cid (stmt : Region.t Statement.t) : id = (stmt, 0)
  let offset (cid : id) (offset : int) : id = (fst cid, offset)
  let at (cid : id) : Region.t = Metadata.md (fst cid)
  let create () : t = Hashtbl.create Config.(!dflt_htbl_sz)
  let copy (cache : t) : t = Hashtbl.copy cache
  let find (cache : t) (id : id) : Node.t option = Hashtbl.find_opt cache id

  let add (cache : t) (id : id) (node : Node.t) : unit =
    Hashtbl.replace cache id node

  let lub (cache1 : t) (cache2 : t) : t =
    Fun.flip Hashtbl.iter cache2 (fun stmt node_2 ->
        let node_1 = Hashtbl.find_opt cache1 stmt in
        if Option.is_none node_1 then Hashtbl.replace cache1 stmt node_2 );
    cache1
end

type t =
  { mdg : Mdg.t
  ; store : Store.t
  ; code_cache : CodeCache.t
  ; fun_handlers : (Location.t, fun_handler) Hashtbl.t
  ; curr_func : Node.t option
  }

and fun_handler =
     t
  -> CodeCache.id
  -> Node.t
  -> Node.t
  -> Node.t
  -> Node.Set.t option list
  -> Region.t Expression.t list
  -> t

let create () : t =
  let mdg = Mdg.create () in
  let store = Store.create () in
  let code_cache = CodeCache.create () in
  let fun_handlers = Hashtbl.create Config.(!dflt_htbl_sz) in
  let curr_func = None in
  { mdg; store; code_cache; fun_handlers; curr_func }

let extend (state : t) : t =
  let mdg = Mdg.copy state.mdg in
  let store = Store.copy state.store in
  let code_cache = CodeCache.copy state.code_cache in
  let curr_func = None in
  { state with mdg; store; code_cache; curr_func }

let copy (state : t) : t =
  let mdg = Mdg.copy state.mdg in
  let store = Store.copy state.store in
  let code_cache = CodeCache.copy state.code_cache in
  { state with mdg; store; code_cache }

let join (state1 : t) (state2 : t) : t =
  let mdg = Mdg.join state1.mdg state2.mdg in
  let code_cache = CodeCache.lub state1.code_cache state2.code_cache in
  { state1 with mdg; code_cache }

let lub (state1 : t) (state2 : t) : t =
  let mdg = Mdg.lub state1.mdg state2.mdg in
  let store = Store.lub state1.store state2.store in
  let code_cache = CodeCache.lub state1.code_cache state2.code_cache in
  { state1 with mdg; store; code_cache }

let add_node (state : t) (create_node_f : Node.t option -> Region.t -> Node.t)
    (id : CodeCache.id) : Node.t =
  match CodeCache.find state.code_cache id with
  | Some node -> node
  | None ->
    let node = create_node_f state.curr_func (CodeCache.at id) in
    CodeCache.add state.code_cache id node;
    Mdg.add_node state.mdg node;
    node

let add_edge (state : t) (create_edge_f : Node.t -> Node.t -> Edge.t)
    (src : Node.t) (tar : Node.t) : Edge.t =
  let edge = create_edge_f src tar in
  Mdg.add_edge state.mdg edge;
  edge

let add_literal_object_node (state : t) (id : CodeCache.id) (name : string) :
    Node.t =
  add_node state (Node.create_literal_object name) id

let add_object_node (state : t) (id : CodeCache.id) (name : string) : Node.t =
  add_node state (Node.create_object name) id

let add_function_node (state : t) (id : CodeCache.id) (name : string) : Node.t =
  add_node state (Node.create_function name) id

let add_parameter_node (state : t) (id : CodeCache.id) (idx : int)
    (name : string) : Node.t =
  add_node state (Node.create_parameter idx name) id

let add_call_node (state : t) (id : CodeCache.id) (name : string) : Node.t =
  add_node state (Node.create_call name) id

let add_return_node (state : t) (id : CodeCache.id) (name : string) : Node.t =
  add_node state (Node.create_return name) id

let add_module_node (state : t) (id : CodeCache.id) (m : string) : t * Node.t =
  let node = add_node state (Node.create_require m) id in
  ({ state with mdg = Mdg.add_requires state.mdg node }, node)

let add_dependency_edge (state : t) (src : Node.t) (tar : Node.t) : unit =
  ignore (add_edge state (Edge.create_dependency ()) src tar)

let add_property_edge (state : t) (src : Node.t) (tar : Node.t)
    (prop : string option) : unit =
  ignore (add_edge state (Edge.create_property prop) src tar)

let add_version_edge (state : t) (src : Node.t) (tar : Node.t)
    (prop : string option) : unit =
  ignore (add_edge state (Edge.create_version prop) src tar)

let add_parameter_edge (state : t) (src : Node.t) (tar : Node.t) (idx : int) :
    unit =
  ignore (add_edge state (Edge.create_parameter idx) src tar)

let add_argument_edge (state : t) (src : Node.t) (tar : Node.t) (idx : int) :
    unit =
  ignore (add_edge state (Edge.create_argument idx) src tar)

let add_call_edge (state : t) (src : Node.t) (tar : Node.t) : unit =
  ignore (add_edge state (Edge.create_call ()) src tar)

let add_return_edge (state : t) (src : Node.t) (tar : Node.t) : unit =
  ignore (add_edge state (Edge.create_return ()) src tar)

let add_returns_edge (state : t) (src : Node.t) (tar : Node.t) : unit =
  ignore (add_edge state (Edge.create_returns ()) src tar)

let concretize_node (state : t) (id : string) (node : Node.t) : Node.t =
  let node' = Node.concretize node in
  Mdg.add_node state.mdg node';
  Store.replace state.store id (Node.Set.singleton node');
  node'

let has_fun_handler (state : t) (func : Node.t) : fun_handler option =
  Hashtbl.find_opt state.fun_handlers func.uid

let set_fun_handler (state : t) (func : Node.t) (handler : fun_handler) : unit =
  Hashtbl.replace state.fun_handlers func.uid handler

module FunHandler = struct
  let function_call (state : t) (_ : CodeCache.id) (l_func : Node.t)
      (l_call : Node.t) (_ : Node.t) (_ : Node.Set.t option list)
      (_ : 'm Expression.t list) : t =
    add_call_edge state l_call l_func;
    { state with mdg = Mdg.add_call state.mdg l_call }

  let call (state : t) (cid : CodeCache.id) (ls_funcs : Node.Set.t)
      (l_call : Node.t) (l_retn : Node.t) (l_this : Node.Set.t option)
      (ls_args : Node.Set.t list) (args : 'm Expression.t list) : t =
    let ls_args' = l_this :: List.map Option.some ls_args in
    Fun.flip2 Node.Set.fold ls_funcs state @@ fun l_func state' ->
    match has_fun_handler state' l_func with
    | None -> function_call state' cid l_func l_call l_retn ls_args' args
    | Some func_handler_f ->
      func_handler_f state' cid l_func l_call l_retn ls_args' args
end
