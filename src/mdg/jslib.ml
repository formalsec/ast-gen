open Graphjs_base
open Graphjs_share
open Graphjs_ast

type cid = State.GraphRegistry.id

module CallInterceptor = struct
  let require (state : State.t) (_ : Node.t) (_ : Node.t) (l_retn : Node.t)
      (_ : Node.Set.t list) (es : 'm Expression.t list) (cid : cid) : State.t =
    match es with
    | Metadata.{ el = `Literal Literal.{ value = String arg; _ }; _ } :: _ ->
      let (state', l_require) = State.add_import_node state cid arg in
      State.add_dependency_edge state' l_require l_retn;
      state'
    | _ -> state
end

let add_tainted_sink (make_generic_sink_f : 'a -> Tainted.sink)
    (state : State.t) (generic_sink : 'a) : State.t =
  let sink = make_generic_sink_f generic_sink in
  let name = Tainted.(name !sink) in
  let l_sink = Node.create_candidate_sink sink in
  Store.replace state.store name (Node.Set.singleton l_sink);
  { state with mdg = Mdg.add_jslib state.mdg l_sink }

let initialize_tainted_sinks (state : State.t) (tconf : Taint_config.t) :
    State.t =
  let make_fun_sink_f = add_tainted_sink (fun sink -> `FunctionSink sink) in
  let make_new_sink_f = add_tainted_sink (fun sink -> `NewSink sink) in
  let state' = List.fold_left make_fun_sink_f state tconf.function_sinks in
  let state'' = List.fold_left make_new_sink_f state' tconf.new_sinks in
  state''

let initialize_require (state : State.t) : State.t =
  let name = "require" in
  let l_require = Node.create_candidate_function name in
  Store.replace state.store name (Node.Set.singleton l_require);
  State.set_call_interceptor state l_require CallInterceptor.require;
  { state with mdg = Mdg.add_jslib state.mdg l_require }

let initialize_module (state : State.t) : State.t =
  let name = "module" in
  let l_module = Node.create_candidate_object name in
  Store.replace state.store name (Node.Set.singleton l_module);
  state

let initialize_builder (state : State.t) (tconf : Taint_config.t) : State.t =
  let state' = initialize_tainted_sinks state tconf in
  let state'' = initialize_require state' in
  state''

let initialize_state (state : State.t) : State.t =
  let state' = initialize_module state in
  state'
