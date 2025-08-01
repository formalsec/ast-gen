open Graphjs_ast
open Graphjs_mdg
open Result

module Options = struct
  type env =
    { jsmodel : Fpath.t
    ; unfold_depth : int
    ; reset_locations : bool
    ; run_httpserver_analysis : bool
    ; run_exported_analysis : bool
    ; run_tainted_analysis : bool
    ; run_cleaner_analysis : bool
    ; export_graph : bool
    ; export_subgraphs : bool
    ; export_func_subgraphs : bool
    ; export_file_subgraphs : bool
    ; export_view : Export_view.t
    ; export_timeout : int
    ; parse_env : Cmd_parse.Options.env
    }

  let validate_env (env : env) : env =
    let parse_env = Cmd_parse.Options.validate_env env.parse_env in
    { env with parse_env }

  type t =
    { inputs : Fpath.t list
    ; output : Fpath.t option
    ; env : env
    }

  let jsmodel_path (jsmodel : Fpath.t option) : Fpath.t =
    match jsmodel with
    | Some jsmodel' -> jsmodel'
    | None -> Properties.default_jsmodel ()

  let env (jsmodel' : Fpath.t option) (unfold_depth' : int)
      (no_exported_analysis : bool) (no_httpserver_analysis : bool)
      (no_tainted_analysis : bool) (no_cleaner_analysis : bool)
      (no_export : bool) (no_subgraphs : bool) (no_func_subgraphs : bool)
      (no_file_subgraphs : bool) (export_view' : Export_view.t)
      (export_timeout' : int) (parse_env' : Cmd_parse.Options.env) : env =
    { jsmodel = jsmodel_path jsmodel'
    ; unfold_depth = unfold_depth'
    ; reset_locations = true
    ; run_exported_analysis = not no_exported_analysis
    ; run_httpserver_analysis = not no_httpserver_analysis
    ; run_tainted_analysis = not (no_exported_analysis || no_tainted_analysis)
    ; run_cleaner_analysis = not no_cleaner_analysis
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
    | (None, false) -> w
    | (None, true) -> single ~w Fpath.(v (temp_f rel') + "svg")
    | (Single _, _) -> w
    | (Bundle _, _) -> dir_f ((w / "mdg" // rel') + "mdg")
end

module Graphjs = struct
  let jsmodel (path : Fpath.t) : Jsmodel.t Exec.result =
    Exec.graphjs (fun () -> Jsmodel.Parser.parse path)

  let mdg_builder (env : State.Env.t) (jsmodel : Jsmodel.t) (prog : 'm Prog.t) :
      Builder.ExtendedMdg.t Exec.result =
    Exec.graphjs (fun () -> Builder.build_program env jsmodel prog)

  let export_dot (env : Svg_exporter.Env.t) (mdg : Mdg.t) (path : Fpath.t) :
      unit Exec.result =
    Exec.graphjs (fun () -> Svg_exporter.export_dot ~env path mdg)

  let export_svg (env : Svg_exporter.Env.t)
      (kind : [ `Dot of Fpath.t | `Mdg of Mdg.t ]) (path : Fpath.t) :
      unit Exec.result =
    Exec.graphjs (fun () -> Svg_exporter.export_svg ~env path kind)
end

module Output = struct
  let jsmodel (w : Workspace.t) (path : Fpath.t) (jsmodel : Jsmodel.t) : unit =
    let w' = Workspace.(w / "jsmodel.conf") in
    Log.info "Tainted config \"%a\" read successfully." Fpath.pp path;
    Log.verbose "%a" Jsmodel.pp jsmodel;
    Workspace.output_noerr Side w' Jsmodel.pp jsmodel

  let mdg_file (mrel : Fpath.t) : unit =
    Log.info "Module MDG '%a' built successfully." Fpath.pp mrel

  let main (w : Workspace.t) (env : Svg_exporter.Env.t) (export : bool)
      (prog : 'm Prog.t) (mdg : Mdg.t) : unit Exec.result =
    let w' = Workspace.mdg w export (Prog.main prog).mrel in
    let url_f ppf url = Fmt.fmt ppf "%s" (Console.url (Fpath.to_string url)) in
    Log.verbose "%a" Mdg.pp mdg;
    match (export, w'.path) with
    | (false, _) ->
      Workspace.output_noerr Main w' Mdg.pp mdg;
      Ok (Workspace.log w "%a" Mdg.pp mdg)
    | (true, Single svg_path) ->
      let* _ = Workspace.execute Main w' (Graphjs.export_svg env (`Mdg mdg)) in
      Log.info "MDG exported successfully.";
      Log.verbose "%a" url_f svg_path;
      Ok (Workspace.log w "%a" url_f svg_path)
    | (true, Bundle _) ->
      let w'' = Workspace.(w' -+ "dot") in
      let w''' = Workspace.(w' -+ "svg") in
      let dot = `Dot (Workspace.path w'') in
      let svg_path = Workspace.path w''' in
      Workspace.output_noerr Main w' Mdg.pp mdg;
      let* _ = Workspace.execute Side w'' (Graphjs.export_dot env mdg) in
      let* _ = Workspace.execute Main w''' (Graphjs.export_svg env dot) in
      Log.info "MDG exported successfully.";
      Log.verbose "%a" url_f svg_path;
      Ok (Workspace.log w "%a" url_f svg_path)
    | _ -> Ok ()
end

let builder_env (env : Options.env) : State.Env.t =
  { unfold_depth = env.unfold_depth
  ; reset_locations = env.reset_locations
  ; run_httpserver_analysis = env.run_httpserver_analysis
  ; run_exported_analysis = env.run_exported_analysis
  ; run_tainted_analysis = env.run_tainted_analysis
  ; run_cleaner_analysis = env.run_cleaner_analysis
  ; cb_mdg_file = Output.mdg_file
  }

let export_env (env : Options.env) : Svg_exporter.Env.t =
  { (Svg_exporter.Env.default ()) with
    subgraphs = env.export_subgraphs
  ; subgraphs_func = env.export_func_subgraphs
  ; subgraphs_file = env.export_file_subgraphs
  ; view = env.export_view
  ; timeout = env.export_timeout
  }

let export_tainted_env (export_env : Svg_exporter.Env.t)
    (builder_env : State.Env.t) (tainted : Tainted.t) : Svg_exporter.Env.t =
  let view =
    match export_env.view with
    | Tainted _ -> Export_view.Tainted (Tainted.get_tainted tainted)
    | view -> view in
  let node_attr_mod =
    if builder_env.run_tainted_analysis then Export_taint.node_attr_mod tainted
    else export_env.node_attr_mod in
  { export_env with view; node_attr_mod }

let run (env : Options.env) (w : Workspace.t) (input : Fpath.t) :
    Builder.ExtendedMdg.t Exec.result =
  let export_env = export_env env in
  let builder_env = builder_env env in
  let* prog = Cmd_parse.run env.parse_env (Workspace.side_perm w) input in
  let* jsmodel = Graphjs.jsmodel env.jsmodel in
  Output.jsmodel w env.jsmodel jsmodel;
  let* e_mdg = Graphjs.mdg_builder builder_env jsmodel prog in
  let export_env' = export_tainted_env export_env builder_env e_mdg.tainted in
  let* _ = Output.main w export_env' env.export_graph prog e_mdg.mdg in
  Ok e_mdg

let outcome (res : Builder.ExtendedMdg.t Exec.result) : Bulk.Instance.outcome =
  match res with
  | Ok _ -> Success
  | Error (`DepTree _) -> Failure
  | Error (`ParseJS _) -> Failure
  | Error (`ExportMDG _) -> Anomaly
  | Error _ -> Anomaly

let bulk_interface (env : Options.env) : (module Bulk.CmdInterface) =
  ( module struct
    type t = Builder.ExtendedMdg.t

    let cmd = Docs.MdgCmd.name
    let run = run (Options.validate_env env)
    let outcome = outcome
  end )

let main (opts : Options.t) () : unit Exec.result =
  let ext = Some (if opts.env.export_graph then "svg" else "mdg") in
  let w = Workspace.create ~default:(`Single ext) opts.inputs opts.output in
  let* _ = Workspace.prepare w in
  let* inputs = Bulk.InputTree.generate opts.inputs in
  let module Interface = (val bulk_interface opts.env) in
  let module Executor = Bulk.Executor (Interface) in
  Executor.execute_only w inputs
