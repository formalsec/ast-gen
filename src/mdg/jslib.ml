open Graphjs_base
open Graphjs_share

let add_tainted_sink (make_generic_sink_f : 'a -> Tainted.sink)
    (state : State.t) (generic_sink : 'a) : State.t =
  let sink = make_generic_sink_f generic_sink in
  let sink_lval = Tainted.(name !sink) in
  let sink_node = Node.create_candidate_sink sink in
  Store.replace state.store sink_lval (Node.Set.singleton sink_node);
  State.set_fun_handler state sink_node Function.sink_call;
  { state with mdg = Mdg.add_jslib state.mdg sink_node }

let initialize_tainted_sinks (state : State.t) (tconf : Taint_config.t) :
    State.t =
  let make_fun_sink_f = add_tainted_sink (fun sink -> `FunctionSink sink) in
  let make_new_sink_f = add_tainted_sink (fun sink -> `NewSink sink) in
  let state' = List.fold_left make_fun_sink_f state tconf.function_sinks in
  let state'' = List.fold_left make_new_sink_f state' tconf.new_sinks in
  state''

let initialize_require (state : State.t) : State.t =
  let require_name = "require" in
  let require_node = Node.create_candidate_function require_name in
  Store.replace state.store require_name (Node.Set.singleton require_node);
  State.set_fun_handler state require_node Function.require_call;
  { state with mdg = Mdg.add_jslib state.mdg require_node }

let initialize_module (state : State.t) : State.t =
  let module_name = "module" in
  let module_node = Node.create_candidate_object module_name in
  Store.replace state.store module_name (Node.Set.singleton module_node);
  { state with mdg = Mdg.add_exported state.mdg module_node }

let initialize_builder (state : State.t) (taint_config : Taint_config.t) :
    State.t =
  let state' = initialize_tainted_sinks state taint_config in
  let state'' = initialize_require state' in
  state''

let initialize_state (state : State.t) : State.t = initialize_module state
