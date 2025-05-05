open Graphjs_base
open Graphjs_share
open Graphjs_ast
open Graphjs_mdg
open Result

module Options = struct
  type env =
    { taint_config : Fpath.t
    ; literal_mode : Enums.LiteralMode.t
    ; func_eval_mode : Enums.FuncEvalMode.t
    ; run_cleaner_analysis : bool
    ; run_tainted_analysis : bool
    ; export_graph : bool
    ; export_subgraphs : bool
    ; export_func_subgraphs : bool
    ; export_file_subgraphs : bool
    ; export_view : Export_view.t
    ; export_timeout : int
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

  let env (taint_config' : Fpath.t option) (literal_mode' : Enums.LiteralMode.t)
      (func_eval_mode' : Enums.FuncEvalMode.t) (no_cleaner_analysis : bool)
      (no_tainted_analysis : bool) (no_export : bool) (no_subgraphs : bool)
      (no_func_subgraphs : bool) (no_file_subgraphs : bool)
      (export_view' : Export_view.t) (export_timeout' : int)
      (parse_env' : Cmd_parse.Options.env) : env =
    { taint_config = parse_taint_config taint_config'
    ; literal_mode = literal_mode'
    ; func_eval_mode = func_eval_mode'
    ; run_cleaner_analysis = not no_cleaner_analysis
    ; run_tainted_analysis = not no_tainted_analysis
    ; export_graph = not no_export
    ; export_subgraphs = not no_subgraphs
    ; export_func_subgraphs = not no_func_subgraphs
    ; export_file_subgraphs = not no_file_subgraphs
    ; export_view = export_view'
    ; export_timeout = export_timeout'
    ; parse_env = parse_env'
    }

  let cmd (inputs : Fpath.t list) (output : Fpath.t option) (env : env) : t =
    { inputs; output; env }
end

module Workspace = struct
  include Workspace

  let mdg (w : t) (export : bool) (mrel : Fpath.t) : t =
    let temp_f rel = Filename.temp_file "graphjs" (Fpath.to_string rel) in
    let dir_f w = Fs.mkdir_noerr (Fpath.parent (path w)) |> fun () -> w in
    let rel' = Fpath.rem_ext mrel in
    match (w.path, export) with
    | (None, true) -> single ~w Fpath.(v (temp_f rel') + "svg")
    | (None, false) -> w
    | (Single _, _) -> w
    | (Bundle _, _) -> dir_f ((w / "mdg" // rel') + "svg")
end

module Graphjs = struct
  let taint_config (path : Fpath.t) : Taint_config.t Exec.result =
    Exec.graphjs (fun () -> Taint_config.read path)

  let mdg_builder (env : State.Env.t) (tc : Taint_config.t) (prog : 'm Prog.t) :
      Mdg.t Exec.result =
    Exec.graphjs (fun () -> Builder.build_program env tc prog)

  let export_dot (env : Svg_exporter.Env.t) (mdg : Mdg.t) (path : Fpath.t) :
      unit Exec.result =
    Exec.graphjs (fun () -> Svg_exporter.export_dot ~env path mdg)

  let export_svg (env : Svg_exporter.Env.t)
      (kind : [ `Dot of Fpath.t | `Mdg of Mdg.t ]) (path : Fpath.t) :
      unit Exec.result =
    Exec.graphjs (fun () -> Svg_exporter.export_svg ~env path kind)
end

module Output = struct
  let taint_config (w : Workspace.t) (path : Fpath.t) (tc : Taint_config.t) :
      unit =
    let w' = Workspace.(w / "taint_config.conf") in
    Log.info "Tainted config \"%a\" read successfully." Fpath.pp path;
    Log.verbose "%a" Taint_config.pp tc;
    Workspace.output_noerr Side w' Taint_config.pp tc

  let mdg (mrel : Fpath.t) : unit =
    Log.info "Module MDG '%a' built successfully." Fpath.pp mrel

  let main (w : Workspace.t) (env : Svg_exporter.Env.t) (export : bool)
      (prog : 'm Prog.t) (mdg : Mdg.t) : unit Exec.result =
    let main = Prog.main prog in
    let w' = Workspace.mdg w export main.mrel in
    Log.verbose "%a" Mdg.pp mdg;
    match (export, w'.path) with
    | (false, _) ->
      Workspace.output_noerr Main w' Mdg.pp mdg;
      Workspace.log w' "%a@." Mdg.pp mdg;
      Ok ()
    | (true, Single svg_path) ->
      let* _ = Workspace.execute Main w' (Graphjs.export_svg env (`Mdg mdg)) in
      Log.info "MDG exported successfully.";
      Workspace.print w' "%s@." (Console.url (Fpath.to_string svg_path));
      Ok ()
    | (true, Bundle svg_path) ->
      let w'' = Workspace.(w' -+ "dot") in
      let dot = `Dot (Workspace.path w'') in
      let* _ = Workspace.execute Side w'' (Graphjs.export_dot env mdg) in
      let* _ = Workspace.execute Main w' (Graphjs.export_svg env dot) in
      Log.info "MDG exported successfully.";
      Workspace.print w' "%s@." (Console.url (Fpath.to_string svg_path));
      Ok ()
    | _ -> Ok ()
end

let builder_env (env : Options.env) : State.Env.t =
  { literal_mode = env.literal_mode
  ; func_eval_mode = env.func_eval_mode
  ; run_cleaner_analysis = env.run_cleaner_analysis
  ; run_tainted_analysis = env.run_tainted_analysis
  ; cb_mdg = Output.mdg
  }

let export_env (env : Options.env) : Svg_exporter.Env.t =
  { subgraphs = env.export_subgraphs
  ; subgraphs_func = env.export_func_subgraphs
  ; subgraphs_file = env.export_file_subgraphs
  ; view = env.export_view
  ; timeout = env.export_timeout
  }

let run (env : Options.env) (w : Workspace.t) (input : Fpath.t) :
    Mdg.t Exec.result =
  let export_env = export_env env in
  let builder_env = builder_env env in
  let* prog = Cmd_parse.run env.parse_env (Workspace.side_perm w) input in
  let* tc = Graphjs.taint_config env.taint_config in
  Output.taint_config w env.taint_config tc;
  let* mdg = Graphjs.mdg_builder builder_env tc prog in
  let* _ = Output.main w export_env env.export_graph prog mdg in
  Ok mdg

let outcome (result : Mdg.t Exec.result) : Bulk.Instance.outcome =
  match result with
  | Ok _ -> Success
  | Error (`DepTree _) -> Failure
  | Error (`ParseJS _) -> Failure
  | Error (`ExportMDG _) -> Anomaly
  | Error _ -> Anomaly

let bulk_interface (env : Options.env) : (module Bulk.CmdInterface) =
  ( module struct
    type t = Mdg.t

    let cmd = Docs.MdgCmd.name
    let run = run env
    let outcome = outcome
  end )

let main (opts : Options.t) () : unit Exec.result =
  let ext = Some (if opts.env.export_graph then "svg" else "mdg") in
  let w = Workspace.create ~default:(`Single ext) opts.inputs opts.output in
  let* _ = Workspace.prepare w in
  let* inputs = Bulk.InputTree.generate opts.inputs in
  let module Interface = (val bulk_interface opts.env) in
  let module Executor = Bulk.Executor (Interface) in
  Executor.execute w inputs
