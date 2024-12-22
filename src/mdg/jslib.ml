open Graphjs_base
open Graphjs_share

let jslib_name (lval : string) : string = "JS::" ^ lval

let add_tainted_sink (make_generic_sink_f : 'a -> Tainted.sink)
    (state : State.t) (generic_sink : 'a) : unit =
  let sink = make_generic_sink_f generic_sink in
  let sink_lval = Tainted.(name !sink) in
  let sink_node = Node.create_candidate_sink sink in
  Store.replace state.store sink_lval (Node.Set.singleton sink_node);
  State.set_custom_func_handler state sink_node Function.sink_call

let initialize_tainted_sinks (state : State.t) (tconf : Taint_config.t) : unit =
  let make_fun_sink_f sink = `FunctionSink sink in
  let make_new_sink_f sink = `NewSink sink in
  List.iter (add_tainted_sink make_fun_sink_f state) tconf.function_sinks;
  List.iter (add_tainted_sink make_new_sink_f state) tconf.new_sinks

let initialize_require (state : State.t) : unit =
  let require_lval = "require" in
  let require_name = jslib_name require_lval in
  let require_node = Node.create_candidate_function require_name in
  Store.replace state.store require_lval (Node.Set.singleton require_node);
  State.set_custom_func_handler state require_node Function.require_call

let initialize_module (state : State.t) : unit =
  let module_lval = "module" in
  let module_name = jslib_name module_lval in
  let module_node = Node.create_candidate_object module_name in
  Store.replace state.store module_lval (Node.Set.singleton module_node)

let initialize (state : State.t) (taint_config : Taint_config.t) : State.t =
  initialize_tainted_sinks state taint_config;
  initialize_require state;
  initialize_module state;
  state
