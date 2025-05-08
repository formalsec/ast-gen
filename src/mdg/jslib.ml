open Graphjs_base
open Graphjs_share
open Graphjs_ast

type cb_build_file = State.t -> Region.t File.t -> bool -> State.t
type cbs_builder = { build_file : cb_build_file }

let cbs_builder (build_file : cb_build_file) : cbs_builder = { build_file }

module NameResolver = struct
  let pp_module_name (ppf : Fmt.t) (mrel : Fpath.t option) : unit =
    Fmt.pp_opt (fun ppf -> Fmt.fmt ppf "#%a" Fpath.pp) ppf mrel

  let sink (name : string) : string = Fmt.str "s#%s" name
  let func (name : string) : string = Fmt.str "f#%s" name

  let file (name : string) (mrel : Fpath.t option) : string =
    Fmt.str "m#%s%a" name pp_module_name mrel

  let curr_file (name : string) (state : State.t) : string =
    if state.curr_floc.main then file name None
    else file name (Some state.curr_floc.mrel)
end

let exported_object ?(mrel : Fpath.t option) (mdg : Mdg.t) : Node.Set.t =
  match Mdg.get_jslib_node mdg (NameResolver.file "module" mrel) with
  | Some l_module' -> Mdg.object_static_lookup mdg l_module' "exports"
  | None -> (
    match Mdg.get_jslib_node mdg (NameResolver.file "exports" mrel) with
    | Some l_exports' -> Node.Set.singleton l_exports'
    | None -> Node.Set.empty )

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

  let resolve_npm (state : State.t) (retn_name : string) (package : string) :
      Node.Set.t =
    match Npm.resolve state.npm state.mdg package with
    | Some l_npm -> Node.Set.singleton l_npm
    | None -> Store.find state.store retn_name

  let process_module (cb_build_file : cb_build_file) (state : State.t)
      (retn_name : string) (path : Fpath.t) : Node.Set.t =
    match Pcontext.file state.pcontext path with
    | None ->
      let package = Fpath.filename path in
      resolve_npm state retn_name package
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
      let ls_exports = process_module cb_build_file state retn_name path in
      Store.replace state.store retn_name ls_exports;
      state
end

let add_tainted_sink (make_generic_sink_f : 'a -> Taint.sink) (state : State.t)
    (generic_sink : 'a) : State.t =
  let sink = make_generic_sink_f generic_sink in
  let name_jslib = NameResolver.sink sink.name in
  let l_sink = Node.create_taint_sink sink None (Region.default ()) in
  Mdg.add_jslib state.mdg name_jslib l_sink;
  Store.replace state.store sink.name (Node.Set.singleton l_sink);
  state

let initialize_tainted_sinks (state : State.t) (tconf : Taint_config.t) :
    State.t =
  let make_fun_sink_f = add_tainted_sink Taint.function_sink in
  (* let make_new_sink_f = add_tainted_sink Taint.new_sink in *)
  let state' = List.fold_left make_fun_sink_f state tconf.f_sinks in
  (* let state'' = List.fold_left make_new_sink_f state' tconf.new_sinks in *)
  state'

let initialize_require (state : State.t) (cb : cb_build_file) : State.t =
  let name = "require" in
  let name_jslib = NameResolver.func name in
  let l_require = Node.create_function name None (Region.default ()) in
  Mdg.add_jslib state.mdg name_jslib l_require;
  Store.replace state.store name (Node.Set.singleton l_require);
  State.set_call_interceptor state l_require (CallInterceptor.require cb);
  state

let initialize_module (state : State.t) : State.t =
  let name = "module" in
  let name_jslib = NameResolver.curr_file "module" state in
  let l_parent = state.curr_parent in
  let l_module = Node.create_object name l_parent (Region.default ()) in
  let module_dep_f = Fun.flip (State.add_dependency_edge state) l_module in
  Mdg.add_jslib state.mdg name_jslib l_module;
  Store.replace state.store name (Node.Set.singleton l_module);
  Option.iter module_dep_f state.curr_parent;
  state

let initialize_exports (state : State.t) : State.t =
  let name = "exports" in
  let name_jslib = NameResolver.curr_file "exports" state in
  let name_module = NameResolver.curr_file "module" state in
  let l_parent = state.curr_parent in
  let l_exports = Node.create_object name l_parent (Region.default ()) in
  let ls_exports = Node.Set.singleton l_exports in
  let l_module = Option.get (Mdg.get_jslib_node state.mdg name_module) in
  Mdg.add_jslib state.mdg name_jslib l_exports;
  State.add_property_edge state l_module l_exports (Property.Static "exports");
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
