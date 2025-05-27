open Graphjs_ast

type cb_build_file =
  State.t -> Region.t File.t -> bool -> Node.t option -> State.t

type cbs_builder = { build_file : cb_build_file }

let cbs_builder (build_file : cb_build_file) : cbs_builder = { build_file }

module RequireInterceptor = struct
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

  let build_module (state : State.t) (mrel : Fpath.t) : Node.t =
    let l_module = Node.create_module (Fpath.to_string mrel) in
    Mdg.add_node state.mdg l_module;
    l_module

  let process_module (cb_build_file : cb_build_file) (state : State.t)
      (path : Fpath.t) : Node.Set.t =
    match Pcontext.file state.pcontext path with
    | None ->
      let name = Fpath.filename path in
      let l_npmlib = Npmlib.resolve_package state.mdg state.npmlib name in
      Node.Set.singleton l_npmlib
    | Some file when file.built ->
      Jslib.exported_object ~mrel:file.file.mrel state.mdg state.jslib
    | Some file ->
      let l_module = build_module state file.file.mrel in
      let state' = cb_build_file state file.file false (Some l_module) in
      Jslib.exported_object ~mrel:file.file.mrel state'.mdg state.jslib

  let run (cb_build_file : cb_build_file) (state : State.t) (retn_name : string)
      (_ : Node.t) (ls_args : Node.Set.t list) : State.t =
    match get_module_path state ls_args with
    | None -> state
    | Some path ->
      let ls_exports = process_module cb_build_file state path in
      Store.replace state.store retn_name ls_exports;
      state
end

let initialize (state : State.t) (cbs_builder : cbs_builder) : unit =
  let l_require = Jslib.find state.mdg state.jslib "require" in
  let cb_require = RequireInterceptor.run cbs_builder.build_file in
  State.set_call_interceptor state l_require cb_require
