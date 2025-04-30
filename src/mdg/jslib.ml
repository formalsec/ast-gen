open Graphjs_base
open Graphjs_share
open Graphjs_ast

type cb_build_file = State.t -> Region.t File.t -> bool -> State.t
type cbs_builder = { build_file : cb_build_file }

let builder_cbs (build_file : cb_build_file) : cbs_builder = { build_file }

let module_name' (prefix : string) (mrel : Fpath.t option) : string =
  prefix ^ Option.fold ~none:"" ~some:(Fmt.str "#%a" Fpath.pp) mrel

let module_name (state : State.t) (prefix : string) : string =
  if state.curr_floc.main then prefix
  else module_name' prefix (Some state.curr_floc.mrel)

let exported_object ?(mrel : Fpath.t option) (mdg : Mdg.t) : Node.Set.t =
  match Mdg.get_jslib_node mdg (module_name' "module" mrel) with
  | Some l_module' -> Mdg.object_static_lookup mdg l_module' "exports"
  | None -> (
    match Mdg.get_jslib_node mdg (module_name' "exports" mrel) with
    | Some l_exports' -> Node.Set.singleton l_exports'
    | None -> Node.Set.empty )

module LookupInterceptor = struct
  let get_temp_exports (state : State.t) (l_exports : Node.t option)
      (l_module : Node.t) (ls_lookup : Node.Set.t) : Node.t option =
    let prop = Property.Static "exports" in
    let l_temp = List.hd_opt (Mdg.get_property state.mdg l_module prop) in
    Fun.flip Node.Set.filter ls_lookup (fun l_node ->
        let l_node' = Some l_node in
        Option.equal Node.equal l_temp l_node'
        && not (Option.equal Node.equal l_exports l_node') )
    |> Node.Set.choose_opt

  let update_temp_exports (state : State.t) (l_exports : Node.t)
      (l_module : Node.t) (l_temp : Node.t option) : State.t =
    let remove_f l_node = Mdg.remove_node state.mdg l_node in
    let prop = Property.Static "exports" in
    let edge = Edge.create_property prop l_module l_exports in
    let mdg = Option.fold ~none:state.mdg ~some:remove_f l_temp in
    Mdg.add_edge mdg edge;
    { state with mdg }

  let update_jslib_exports (state : State.t) : Node.t option -> Node.t =
    function
    | Some l_exports -> l_exports
    | None ->
      let exports_jslib = module_name state "exports" in
      let l_exports = Mdg.get_jslib_template state.mdg exports_jslib in
      let l_exports' = Node.concretize l_exports in
      let js_exports_stored = Store.find state.store "exports" in
      Mdg.add_node state.mdg l_exports';
      if Node.Set.equal js_exports_stored (Node.Set.singleton l_exports) then
        Store.replace state.store "exports" (Node.Set.singleton l_exports');
      l_exports'

  let update_exports_store (state : State.t) (l_exports : Node.t)
      (name : string) (ls_lookup : Node.Set.t) : Node.t option -> State.t =
    function
    | None -> state
    | Some l_temp ->
      let ls_lookup' = Node.Set.remove l_temp ls_lookup in
      let ls_lookup'' = Node.Set.add l_exports ls_lookup' in
      Store.replace state.store name ls_lookup'';
      state

  let nodejs (state : State.t) (l_module : Node.t) (name : string)
      (_ : Node.Set.t) (prop : Property.t) (ls_lookup : Node.Set.t) : State.t =
    match prop with
    | Static "exports" | Dynamic ->
      let exports_jslib = module_name state "exports" in
      let l_exports = Mdg.get_jslib_node state.mdg exports_jslib in
      let l_temp = get_temp_exports state l_exports l_module ls_lookup in
      let l_exports' = update_jslib_exports state l_exports in
      let state' = update_temp_exports state l_exports' l_module l_temp in
      update_exports_store state' l_exports' name ls_lookup l_temp
    | _ -> state
end

module CallInterceptor = struct
  let get_module_path (state : State.t) (ls_args : Node.Set.t list) :
      Fpath.t option =
    let root = fst (Fpath.split_base state.curr_floc.path) in
    match ls_args with
    | [ _; ls_name ] when Node.Set.cardinal ls_name == 1 -> (
      match (Node.Set.choose ls_name).kind with
      | Literal { kind = String; raw } ->
        let name = String.sub raw 1 (String.length raw - 2) in
        Some Fpath.(root // v name |> rem_ext |> normalize)
      | _ -> None )
    | _ -> None

  let process_module (cb_build_file : cb_build_file) (state : State.t)
      (path : Fpath.t) : Node.Set.t =
    match Pcontext.file state.pcontext path with
    | None ->
      Log.warn "TODO: check for npm modules";
      Node.Set.empty
    | Some file when file.built ->
      exported_object ~mrel:file.file.mrel state.mdg
    | Some file ->
      let state' = cb_build_file state file.file false in
      exported_object ~mrel:file.file.mrel state'.mdg

  let require (cb_build_file : cb_build_file) (state : State.t)
      (retn_name : string) (_ : Node.t) (ls_args : Node.Set.t list) : State.t =
    match get_module_path state ls_args with
    | None -> state
    | Some path ->
      let ls_exports = process_module cb_build_file state path in
      Store.replace state.store retn_name ls_exports;
      state
end

let add_tainted_sink (make_generic_sink_f : 'a -> Tainted.sink)
    (state : State.t) (generic_sink : 'a) : State.t =
  let sink = make_generic_sink_f generic_sink in
  let name = Tainted.(name !sink) in
  let l_sink = Node.create_candidate_sink sink None (Region.default ()) in
  Mdg.set_jslib state.mdg name l_sink;
  Store.replace state.store name (Node.Set.singleton l_sink);
  state

let initialize_tainted_sinks (state : State.t) (tconf : Taint_config.t) :
    State.t =
  let make_fun_sink_f = add_tainted_sink (fun sink -> `FunctionSink sink) in
  (* let make_new_sink_f = add_tainted_sink (fun sink -> `NewSink sink) in *)
  let state' = List.fold_left make_fun_sink_f state tconf.function_sinks in
  (* let state'' = List.fold_left make_new_sink_f state' tconf.new_sinks in *)
  state'

let initialize_require (state : State.t) (cb : cb_build_file) : State.t =
  let name = "require" in
  let l_require = Node.create_candidate_function name None (Region.default ()) in
  Mdg.set_jslib state.mdg name l_require;
  Store.replace state.store name (Node.Set.singleton l_require);
  State.set_call_interceptor state l_require (CallInterceptor.require cb);
  state

let initialize_module (state : State.t) : State.t =
  let name = "module" in
  let name_jslib = module_name state "module" in
  let l_module = Node.create_candidate_object name None (Region.default ()) in
  Mdg.set_jslib state.mdg name_jslib l_module;
  Store.replace state.store name (Node.Set.singleton l_module);
  State.set_lookup_interceptor state l_module LookupInterceptor.nodejs;
  state

let initialize_exports (state : State.t) : State.t =
  let name = "exports" in
  let name_jslib = module_name state "exports" in
  let l_exports = Node.create_candidate_object name None (Region.default ()) in
  let ls_exports = Node.Set.singleton l_exports in
  Mdg.set_jslib state.mdg name_jslib l_exports;
  Store.replace state.store name ls_exports;
  state

let initialize_builder (state : State.t) (tconf : Taint_config.t)
    (cbs_builder : cbs_builder) : State.t =
  let state' = initialize_tainted_sinks state tconf in
  let state'' = initialize_require state' cbs_builder.build_file in
  state''

let initialize_file (state : State.t) : State.t =
  let state' = initialize_module state in
  let state'' = initialize_exports state' in
  state''
