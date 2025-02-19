open Graphjs_base
open Graphjs_share
open Graphjs_parser
open Graphjs_ast
open Graphjs_mdg
open Result

module Options = struct
  type env =
    { taint_config : Fpath.t
    ; export_svg : bool
    ; wrap_literal_property_updates : bool
    ; parse_env : Cmd_parse.Options.env
    }

  type t =
    { inputs : Fpath.t list
    ; output : Fpath.t option
    ; env : env
    }

  let parse_taint_config (taint_config : Fpath.t option) : Fpath.t =
    match taint_config with
    | Some taint_config' -> taint_config'
    | None -> Properties.default_taint_config ()

  let env (taint_config' : Fpath.t option) (no_svg : bool)
      (no_literal_prop_wrap : bool) (parse_env : Cmd_parse.Options.env) : env =
    let taint_config = parse_taint_config taint_config' in
    let export_svg = not no_svg in
    let wrap_literal_property_updates = not no_literal_prop_wrap in
    { taint_config; export_svg; wrap_literal_property_updates; parse_env }

  let cmd (inputs : Fpath.t list) (output : Fpath.t option) (env : env) : t =
    { inputs; output; env }
end

let set_temp_env (env : Options.env) : unit =
  (* FIXME: remove in favor of env structures *)
  Builder_config.(export_svg := env.export_svg);
  Builder_config.(
    wrap_literal_property_updates := env.wrap_literal_property_updates )

module Workspace = struct
  include Workspace

  let mdg (env : Options.env) (w : t) (mrel : Fpath.t) (main : bool) : t =
    let temp_f rel = Filename.temp_file "graphjs" (Fpath.to_string rel) in
    let dir_f w = Fs.mkdir_noerr (Fpath.parent (path w)) |> fun () -> w in
    let rel' = Fpath.rem_ext mrel in
    match (main, w.path, env.export_svg) with
    | (true, None, true) -> single ~w Fpath.(v (temp_f rel') + "svg")
    | (true, None, false) -> w
    | (true, Single _, _) -> w
    | (true, Bundle _, _) -> dir_f ((w / "mdg" // rel') + "svg")
    | (false, Bundle _, _) -> dir_f ((w / "mdg" // rel' // rel') + "svg")
    | (false, _, _) -> none
end

module Output = struct
  let url (path : Fpath.t) : string = Console.url (Fpath.to_string path)

  let export_dot (mdg : Mdg.t) (path : Fpath.t) : unit Exec.status =
    Exec.graphjs (fun () -> Svg_exporter.export_dot path mdg)

  let export_svg (kind : [ `Dot of Fpath.t | `Mdg of Mdg.t ]) (path : Fpath.t) :
      unit Exec.status =
    Exec.graphjs (fun () -> Svg_exporter.export_svg path kind)

  let taint_config (w : Workspace.t) (path : Fpath.t) (tc : Taint_config.t) :
      unit =
    let w' = Workspace.(w / "taint_config.conf") in
    Log.info "Tainted config \"%a\" read successfully." Fpath.pp path;
    Log.verbose "%a" Taint_config.pp tc;
    Workspace.output_noerr Side w' Taint_config.pp tc

  let mdg (w : Workspace.t) (mrel : Fpath.t) (mdg : Mdg.t) : unit Exec.status =
    let w' = Workspace.(w -+ "mdg") in
    Log.info "Module MDG '%a' built successfully." Fpath.pp mrel;
    Log.verbose "%a" Mdg.pp mdg;
    Workspace.output_noerr Side w' Mdg.pp mdg;
    match w.path with
    | Bundle svg_path ->
      let w'' = Workspace.(w -+ "dot") in
      let dot_path = Workspace.path w'' in
      let* _ = Workspace.execute Side w'' (export_dot mdg) in
      let* _ = Workspace.execute Side w (export_svg (`Dot dot_path)) in
      Log.info "Module MDG '%a' exported successfully." Fpath.pp mrel;
      Log.verbose "%s" (url svg_path);
      Ok ()
    | _ -> Ok ()

  let main (env : Options.env) (w : Workspace.t) (path : Fpath.t) (mdg : Mdg.t)
      : unit Exec.status =
    let w' = Workspace.(w -+ "mdg") in
    Log.info "MDGs \"%a\" merged successfully." Fpath.pp path;
    Log.verbose "%a" Mdg.pp mdg;
    match (env.export_svg, w.path) with
    | (false, _) ->
      Workspace.output_noerr Main w' Mdg.pp mdg;
      Workspace.log w "%a@." Mdg.pp mdg;
      Ok ()
    | (true, Single svg_path) ->
      let* _ = Workspace.execute Main w (export_svg (`Mdg mdg)) in
      Log.info "MDG \"%a\" exported successfully." Fpath.pp path;
      Workspace.log w "%s@." (url svg_path);
      Ok ()
    | (true, Bundle svg_path) ->
      let w'' = Workspace.(w -+ "dot") in
      let dot_path = Workspace.path w'' in
      let* _ = Workspace.execute Side w'' (export_dot mdg) in
      let* _ = Workspace.execute Main w (export_svg (`Dot dot_path)) in
      Log.info "MDG \"%a\" exported successfully." Fpath.pp path;
      Workspace.log w "%s@." (url svg_path);
      Ok ()
    | _ -> Ok ()
end

let taint_config (path : Fpath.t) () : Taint_config.t = Taint_config.read path

let mdg_builder (builder : State.t) (file : 'm File.t) () : Mdg.t =
  Builder.build_file builder file

let mdg_merger (merger : Merger.t) () : Mdg.t = Merger.merge_entries merger

let read_taint_config (env : Options.env) (w : Workspace.t) :
    Taint_config.t Exec.status =
  let* tc = Exec.graphjs (taint_config env.taint_config) in
  Output.taint_config w env.taint_config tc;
  Ok tc

let build_program_mdgs (env : Options.env) (w : Workspace.t)
    (dt : Dependency_tree.t) (builder : State.t) (prog : 'm Prog.t) :
    (Fpath.t * Mdg.t) Exec.status list =
  Fun.flip Dependency_tree.bottom_up_visit dt (fun (path, mrel) ->
      let file = Prog.find prog path in
      let* mdg = Exec.graphjs (mdg_builder builder file) in
      let w' = Workspace.mdg env w mrel false in
      let* _ = Output.mdg w' mrel mdg in
      Ok (path, mdg) )

let merge_program_mdgs (env : Options.env) (w : Workspace.t)
    (dt : Dependency_tree.t) (merger : Merger.t) : Mdg.t Exec.status =
  let* mdg = Exec.graphjs (mdg_merger merger) in
  let w' = Workspace.mdg env w dt.mrel true in
  let* _ = Output.main env w' dt.path mdg in
  Ok mdg

let run (env : Options.env) (w : Workspace.t) (input : Fpath.t) :
    Mdg.t Exec.status =
  set_temp_env env;
  let* (dt, prog) = Cmd_parse.run env.parse_env (Workspace.side_perm w) input in
  let* tc = read_taint_config env w in
  let builder = Builder.initialize_builder tc in
  let* mdgs = Result.extract (build_program_mdgs env w dt builder prog) in
  let merger = Merger.create tc mdgs in
  merge_program_mdgs env w dt merger

let outcome (result : Mdg.t Exec.status) : Bulk.Instance.outcome =
  match result with
  | Ok _ -> Success
  | Error (`DepTree _) -> Failure
  | Error (`ParseJS _) -> Failure
  | Error (`BuildMDG _) -> Failure
  | Error (`ExportMDG _) -> Anomaly
  | Error _ -> Anomaly

let bulk_interface (env : Options.env) : (module Bulk.CmdInterface) =
  ( module struct
    type t = Mdg.t

    let cmd = Docs.MdgCmd.name
    let run = run env
    let outcome = outcome
  end )

let main (opts : Options.t) () : unit Exec.status =
  let ext = Some (if opts.env.export_svg then "svg" else "mdg") in
  let w = Workspace.create ~default:(`Single ext) opts.inputs opts.output in
  let* _ = Workspace.prepare w in
  let* inputs = Bulk.InputTree.generate opts.inputs in
  let module Interface = (val bulk_interface opts.env) in
  let module Executor = Bulk.Executor (Interface) in
  Executor.execute w inputs
