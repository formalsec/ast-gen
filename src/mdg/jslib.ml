open Graphjs_base
open Graphjs_share

let add_tainted_sink (make_generic_sink_f : 'a -> Tainted.sink)
    (state : State.t) (generic_sink : 'a) : unit =
  let sink = make_generic_sink_f generic_sink in
  let sink_lval = Tainted.(name !sink) in
  let sink_node = Node.create_candidate_sink sink in
  Store.replace state.store sink_lval (Node.Set.singleton sink_node);
  State.set_fun_handler state sink_node Function.sink_call

let initialize_tainted_sinks (state : State.t) (tconf : Taint_config.t) : unit =
  let make_fun_sink_f sink = `FunctionSink sink in
  let make_new_sink_f sink = `NewSink sink in
  List.iter (add_tainted_sink make_fun_sink_f state) tconf.function_sinks;
  List.iter (add_tainted_sink make_new_sink_f state) tconf.new_sinks

let initialize_require (state : State.t) : unit =
  let require_name = "require" in
  let require_node = Node.create_candidate_function require_name in
  Store.replace state.store require_name (Node.Set.singleton require_node);
  State.set_fun_handler state require_node Function.require_call

let initialize_module (state : State.t) : State.t =
  let module_name = "module" in
  let module_node = Node.create_candidate_object module_name in
  let mdg = { state.mdg with exported = module_node.uid } in
  Store.replace state.store module_name (Node.Set.singleton module_node);
  { state with mdg }

let initialize (state : State.t) (taint_config : Taint_config.t) : State.t =
  initialize_tainted_sinks state taint_config;
  initialize_require state;
  initialize_module state
