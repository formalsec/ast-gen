open Graphjs_base
open Graphjs_share
open Graphjs_ast

module Handler = struct
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

  let require_call (state : State.t) (cid : State.CodeCache.id)
      (l_func : Node.t) (l_call : Node.t) (l_retn : Node.t)
      (_ : Node.Set.t option list) : 'm Expression.t list -> unit = function
    | Metadata.{ el = `Literal Literal.{ value = String arg; _ }; _ } :: _ ->
      State.add_call_edge state l_call l_func;
      let l_export = State.add_module_node state cid arg in
      State.add_dependency_edge state l_export l_retn
    | _ -> State.add_call_edge state l_call l_func
end

let add_call (state : State.t) (cid : State.CodeCache.id)
    (ls_funcs : Node.Set.t) (l_call : Node.t) (l_retn : Node.t)
    (l_this : Node.Set.t option) (ls_args : Node.Set.t list)
    (args : 'm Expression.t list) : unit =
  let ls_args' = l_this :: List.map Option.some ls_args in
  Fun.flip Node.Set.iter ls_funcs @@ fun l_func ->
  match State.has_custom_func_handler state l_func with
  | None -> Handler.function_call state cid l_func l_call l_retn ls_args' args
  | Some func_handler_f ->
    func_handler_f state cid l_func l_call l_retn ls_args' args

let add_tainted_sink (make_generic_sink_f : 'a -> Tainted.sink)
    (state : State.t) (generic_sink : 'a) : unit =
  let sink = make_generic_sink_f generic_sink in
  let sink_name = Tainted.(name !sink) in
  let sink_node = Node.create_candidate_sink sink in
  Store.replace state.store sink_name (Node.Set.singleton sink_node);
  State.set_custom_func_handler state sink_node Handler.sink_call

let initialize_tainted_sinks (state : State.t) (tconf : Taint_config.t) : unit =
  let make_fun_sink_f sink = `FunctionSink sink in
  let make_new_sink_f sink = `NewSink sink in
  List.iter (add_tainted_sink make_fun_sink_f state) tconf.function_sinks;
  List.iter (add_tainted_sink make_new_sink_f state) tconf.new_sinks

let initialize_require (state : State.t) : unit =
  let require_name = "require" in
  let require_node = Node.create_candidate_function require_name in
  Store.replace state.store require_name (Node.Set.singleton require_node);
  State.set_custom_func_handler state require_node Handler.require_call

let initialize_stdlib (state : State.t) (taint_config : Taint_config.t) :
    State.t =
  initialize_tainted_sinks state taint_config;
  initialize_require state;
  state
