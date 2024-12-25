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
    (l_call : Node.t) (_ : Node.t) (ls_args : Node.Set.t option list)
    (_ : 'm Expression.t list) : unit =
  let l_params = Mdg.get_parameters state.mdg l_func in
  State.add_call_edge state l_call l_func;
  function_arguments state l_params ls_args

let sink_call (state : State.t) (_ : State.CodeCache.id) (l_func : Node.t)
    (l_call : Node.t) (_ : Node.t) (ls_args : Node.Set.t option list)
    (_ : 'm Expression.t list) : unit =
  let l_params = List.mapi (fun idx _ -> (idx, l_func)) ls_args in
  State.add_call_edge state l_call l_func;
  function_arguments state l_params ls_args

let require_call (state : State.t) (cid : State.CodeCache.id) (l_func : Node.t)
    (l_call : Node.t) (l_retn : Node.t) (_ : Node.Set.t option list) :
    'm Expression.t list -> unit = function
  | Metadata.{ el = `Literal Literal.{ value = String arg; _ }; _ } :: _ ->
    State.add_call_edge state l_call l_func;
    let l_export = State.add_module_node state cid arg in
    State.add_dependency_edge state l_export l_retn
  | _ -> State.add_call_edge state l_call l_func

let add_call (state : State.t) (cid : State.CodeCache.id)
    (ls_funcs : Node.Set.t) (l_call : Node.t) (l_retn : Node.t)
    (l_this : Node.Set.t option) (ls_args : Node.Set.t list)
    (args : 'm Expression.t list) : unit =
  let ls_args' = l_this :: List.map Option.some ls_args in
  Fun.flip Node.Set.iter ls_funcs @@ fun l_func ->
  match State.has_fun_handler state l_func with
  | None -> function_call state cid l_func l_call l_retn ls_args' args
  | Some func_handler_f ->
    func_handler_f state cid l_func l_call l_retn ls_args' args
