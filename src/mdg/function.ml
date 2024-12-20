open Graphjs_base
open Graphjs_shared
open Graphjs_ast

let set_call_arguments (state : State.t) (l_params : (int * Node.t) list)
    (ls_args : Node.Set.t option list) : unit =
  Fun.flip List.iter l_params (fun (idx, l_param) ->
      match List.nth_opt ls_args idx with
      | Some (Some ls_arg) ->
        Node.Set.iter (State.add_ref_argument_edge state l_param) ls_arg
      | _ -> () )

let set_function_call : State.func_handler =
 fun state _ l_func l_call _ ls_args _ ->
  let l_params = Mdg.get_parameters state.mdg l_func in
  State.add_call_edge state l_call l_func;
  set_call_arguments state l_params ls_args

let set_sink_call : State.func_handler =
 fun state _ l_func l_call _ ls_args _ ->
  let l_params = List.mapi (fun idx _ -> (idx, l_func)) ls_args in
  State.add_call_edge state l_call l_func;
  set_call_arguments state l_params ls_args

let set_require_call : State.func_handler =
 fun state cid l_func l_call l_retn _ args ->
  let open Metadata in
  let open Literal in
  match args with
  | { el = `Literal { value = String arg; _ }; _ } :: _ ->
    State.add_call_edge state l_call l_func;
    let l_export = State.add_module_node state cid arg in
    State.add_dependency_edge state l_export l_retn
  | _ ->
    State.raise "Function %S requires a string argument." (Node.name l_func)

let set_call (state : State.t) (cid : State.CodeCache.id)
    (ls_funcs : Node.Set.t) (l_call : Node.t) (l_retn : Node.t)
    (l_this : Node.Set.t option) (ls_args : Node.Set.t list)
    (args : 'm Expression.t list) : unit =
  let ls_args' = l_this :: List.map Option.some ls_args in
  Fun.flip Node.Set.iter ls_funcs (fun l_func ->
      match Hashtbl.find_opt state.stdlib_funcs l_func with
      | None -> set_function_call state cid l_func l_call l_retn ls_args' args
      | Some func_handler_f ->
        func_handler_f state cid l_func l_call l_retn ls_args' args )

let add_tainted_sink (make_generic_sink_f : 'a -> Tainted.sink)
    (state : State.t) (generic_sink : 'a) : unit =
  let sink = make_generic_sink_f generic_sink in
  let sink_name = Tainted.(name !sink) in
  let sink_node = Node.create_sink sink in
  Store.replace state.store sink_name (Node.Set.singleton sink_node);
  Hashtbl.replace state.stdlib_funcs sink_node set_sink_call

let initialize_tainted_sinks (state : State.t) (tconf : Taint_config.t) : unit =
  let make_fun_sink_f sink = `FunctionSink sink in
  let make_new_sink_f sink = `NewSink sink in
  List.iter (add_tainted_sink make_fun_sink_f state) tconf.function_sinks;
  List.iter (add_tainted_sink make_new_sink_f state) tconf.new_sinks

let initialize_require (state : State.t) : unit =
  let region = Region.default () in
  let require_name = "require" in
  let require_node = Node.create_function require_name None region in
  Store.replace state.store require_name (Node.Set.singleton require_node);
  Hashtbl.replace state.stdlib_funcs require_node set_require_call

let initialize_stdlib (state : State.t) (taint_config : Taint_config.t) :
    State.t =
  initialize_tainted_sinks state taint_config;
  initialize_require state;
  state

let set_stdlib_functions (state : State.t) (ls_funcs : Node.Set.t) : unit =
  Fun.flip Node.Set.iter ls_funcs (fun l_func ->
      if State.is_stdlib_func state l_func then Mdg.add_node state.mdg l_func )
