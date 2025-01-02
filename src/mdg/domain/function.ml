open Graphjs_base
open Graphjs_ast

let function_arguments (state : State.t) (l_params : (int * Node.t) list)
    (ls_args : Node.Set.t option list) : unit =
  Fun.flip List.iter l_params (fun (idx, l_param) ->
      match List.nth_opt ls_args idx with
      | Some (Some ls_arg) ->
        Node.Set.iter (State.add_ref_argument_edge state l_param) ls_arg
      | _ -> () )

let function_call (state : State.t) (_ : State.CodeCache.id) (l_func : Node.t)
    (l_call : Node.t) (ls_args : Node.Set.t option list)
    (_ : 'm Expression.t list) : State.t =
  let l_params = Mdg.get_parameters state.mdg l_func in
  State.add_call_edge state l_call l_func;
  function_arguments state l_params ls_args;
  state

let sink_call (state : State.t) (_ : State.CodeCache.id) (l_func : Node.t)
    (l_call : Node.t) (ls_args : Node.Set.t option list)
    (_ : 'm Expression.t list) : State.t =
  let l_params = List.mapi (fun idx _ -> (idx, l_func)) ls_args in
  State.add_call_edge state l_call l_func;
  function_arguments state l_params ls_args;
  state

let require_call (state : State.t) (cid : State.CodeCache.id) (l_func : Node.t)
    (l_call : Node.t) (_ : Node.Set.t option list) :
    'm Expression.t list -> State.t = function
  | Metadata.{ el = `Literal Literal.{ value = String arg; _ }; _ } :: _ ->
    State.add_call_edge state l_call l_func;
    let (state', l_require) = State.add_module_node state cid arg in
    State.add_dependency_edge state' l_require l_call;
    state'
  | _ ->
    State.add_call_edge state l_call l_func;
    state

let add_call (state : State.t) (cid : State.CodeCache.id)
    (ls_funcs : Node.Set.t) (l_call : Node.t) (l_this : Node.Set.t option)
    (ls_args : Node.Set.t list) (args : 'm Expression.t list) : State.t =
  let ls_args' = l_this :: List.map Option.some ls_args in
  Fun.flip2 Node.Set.fold ls_funcs state @@ fun l_func state' ->
  match State.has_fun_handler state' l_func with
  | None -> function_call state' cid l_func l_call ls_args' args
  | Some func_handler_f -> func_handler_f state' cid l_func l_call ls_args' args
