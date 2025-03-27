open Graphjs_base
open Graphjs_share
open Graphjs_ast

type cid = Registry.cid

module LookupInterceptor = struct
  let get_temp_exports (state : State.t) (l_exports : Node.t option)
      (l_module : Node.t) (ls_lookup : Node.Set.t) : Node.t option =
    let prop = Property.Static "exports" in
    let ls_temp = Mdg.get_property state.mdg l_module prop in
    let l_temp = List.hd_opt ls_temp in
    Fun.flip Node.Set.filter ls_lookup (fun node ->
        let node' = Some node in
        Option.equal Node.equal l_temp node'
        && not (Option.equal Node.equal l_exports node') )
    |> Node.Set.choose_opt

  let update_nodejs_exports (state : State.t) : Node.t option -> Node.t =
    function
    | Some l_exports -> l_exports
    | None ->
      let l_exports = Mdg.get_jslib_template state.mdg "exports" in
      let l_exports' = Node.concretize l_exports in
      let ls_stored_exports = Store.find state.store "exports" in
      Mdg.add_node state.mdg l_exports';
      if Node.Set.equal ls_stored_exports (Node.Set.singleton l_exports) then
        Store.replace state.store "exports" (Node.Set.singleton l_exports');
      l_exports'

  let update_temp_exports (state : State.t) (l_exports : Node.t)
      (l_module : Node.t) (l_temp : Node.t option) : State.t =
    let remove_f node = Mdg.remove_node state.mdg node in
    let prop = Property.Static "exports" in
    let edge = Edge.create_property prop l_module l_exports in
    Mdg.add_edge state.mdg edge;
    { state with mdg = Option.fold ~none:state.mdg ~some:remove_f l_temp }

  let update_exports_store (state : State.t) (l_exports : Node.t)
      (name : string) (ls_lookup : Node.Set.t) (l_temp : Node.t option) :
      State.t =
    match l_temp with
    | None -> state
    | Some l_temp' ->
      let ls_lookup' = Node.Set.remove l_temp' ls_lookup in
      let ls_lookup'' = Node.Set.add l_exports ls_lookup' in
      Store.replace state.store name ls_lookup'';
      state

  let nodejs (state : State.t) (l_module : Node.t) (name : string)
      (_ : Node.Set.t) (prop : Property.t) (ls_lookup : Node.Set.t) : State.t =
    match prop with
    | Static "exports" | Dynamic ->
      let l_exports = Mdg.get_jslib_node state.mdg "exports" in
      let l_temp = get_temp_exports state l_exports l_module ls_lookup in
      let l_exports' = update_nodejs_exports state l_exports in
      let state' = update_temp_exports state l_exports' l_module l_temp in
      update_exports_store state' l_exports' name ls_lookup l_temp
    | _ -> state
end

module CallInterceptor = struct
  let require (state : State.t) (_ : Node.t) (_ : Node.t) (l_retn : Node.t)
      (_ : Node.Set.t list) (es : 'm Expression.t list) (cid : cid) : State.t =
    let open Metadata in
    match es with
    | { el = `LiteralValue LiteralValue.{ value = String arg; _ }; _ } :: _ ->
      let (state', l_require) = State.add_import_node state cid arg in
      State.add_dependency_edge state' l_require l_retn;
      state'
    | _ -> state
end

let add_tainted_sink (make_generic_sink_f : 'a -> Tainted.sink)
    (state : State.t) (generic_sink : 'a) : State.t =
  let sink = make_generic_sink_f generic_sink in
  let name = Tainted.(name !sink) in
  let l_sink = Node.create_candidate_sink sink None (Region.default ()) in
  Mdg.add_jslib state.mdg name l_sink;
  Store.replace state.store name (Node.Set.singleton l_sink);
  state

let initialize_tainted_sinks (state : State.t) (tconf : Taint_config.t) :
    State.t =
  let make_fun_sink_f = add_tainted_sink (fun sink -> `FunctionSink sink) in
  let make_new_sink_f = add_tainted_sink (fun sink -> `NewSink sink) in
  let state' = List.fold_left make_fun_sink_f state tconf.function_sinks in
  let state'' = List.fold_left make_new_sink_f state' tconf.new_sinks in
  state''

let initialize_require (state : State.t) : State.t =
  let name = "require" in
  let l_require = Node.create_candidate_function name None (Region.default ()) in
  Mdg.add_jslib state.mdg name l_require;
  Store.replace state.store name (Node.Set.singleton l_require);
  State.set_call_interceptor state l_require CallInterceptor.require;
  state

let initialize_module (state : State.t) : State.t =
  let name = "module" in
  let l_module = Node.create_candidate_object name None (Region.default ()) in
  Mdg.add_jslib state.mdg name l_module;
  Store.replace state.store name (Node.Set.singleton l_module);
  State.set_lookup_interceptor state l_module LookupInterceptor.nodejs;
  state

let initialize_exports (state : State.t) : State.t =
  let name = "exports" in
  let name' = "module.exports" in
  let l_exports = Node.create_candidate_object name' None (Region.default ()) in
  let ls_exports = Node.Set.singleton l_exports in
  Mdg.add_jslib state.mdg name l_exports;
  Store.replace state.store name ls_exports;
  state

let initialize_builder (state : State.t) (tconf : Taint_config.t) : State.t =
  let state' = initialize_tainted_sinks state tconf in
  let state'' = initialize_require state' in
  state''

let initialize_state (state : State.t) : State.t =
  let state' = initialize_module state in
  let state'' = initialize_exports state' in
  state''

let exported_object (mdg : Mdg.t) : Node.Set.t =
  match Mdg.get_jslib_node mdg "module" with
  | Some l_module' -> Mdg.object_static_lookup mdg l_module' "exports"
  | None -> (
    match Mdg.get_jslib_node mdg "exports" with
    | Some l_exports' -> Node.Set.singleton l_exports'
    | None -> Node.Set.empty )
