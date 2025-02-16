open Graphjs_base
open Graphjs_client
open Cmdliner

type status = (unit Exec.status Cmd.eval_ok, Cmd.eval_error) Result.t

let set_copts (colorless : bool) (lvl : Enums.DebugLvl.t) (verbose : bool)
    (override' : bool) : unit =
  Font.Config.(colored := not colorless);
  Log.Config.(log_warns := (lvl >= Warn));
  Log.Config.(log_infos := (verbose || lvl >= Info));
  Log.Config.(log_debugs := (lvl >= All));
  Log.Config.(log_verbose := verbose);
  Workspace.Config.(override := override')

let copts : unit Term.t =
  let open Term in
  const set_copts
  $ Docs.CommonOpts.colorless
  $ Docs.CommonOpts.debug
  $ Docs.CommonOpts.verbose
  $ Docs.CommonOpts.override

let set_shared_opts (mode' : Enums.AnalysisMode.t) () : unit =
  let open Graphjs_share in
  Share_config.(mode := Enums.AnalysisMode.conv mode')

let shared_opts : unit Term.t =
  Term.(const set_shared_opts $ Docs.SharedOpts.mode $ copts)

let parse_opts : unit Term.t =
  Term.(const Cmd_parse.Options.set $ Docs.ParseOpts.test262_conform_hoisted)

let parse_cmd_opts : Cmd_parse.Options.t Term.t =
  let open Term in
  const Cmd_parse.Options.set_cmd
  $ Docs.FileOpts.inputs
  $ Docs.FileOpts.output_dir
  $ parse_opts

let parse_cmd : unit Exec.status Cmd.t =
  let open Docs.ParseCmd in
  let info = Cmd.info name ~sdocs ~doc ~man ~man_xrefs ~exits in
  Cmd.v info Term.(const Cmd_parse.main $ parse_cmd_opts $ shared_opts)

let mdg_opts : unit Term.t =
  let open Term in
  const Cmd_mdg.Options.set
  $ Docs.MdgOpts.no_svg
  $ Docs.MdgOpts.no_literal_property_wrapping
  $ parse_opts

let mdg_cmd_opts : Cmd_mdg.Options.t Term.t =
  let open Term in
  const Cmd_mdg.Options.set_cmd
  $ Docs.FileOpts.inputs
  $ Docs.FileOpts.output
  $ Docs.SharedOpts.taint_config
  $ mdg_opts

let mdg_cmd : unit Exec.status Cmd.t =
  let open Docs.MdgCmd in
  let info = Cmd.info name ~sdocs ~doc ~man ~man_xrefs ~exits in
  Cmd.v info Term.(const Cmd_mdg.main $ mdg_cmd_opts $ shared_opts)

let analyze_opts : unit Term.t =
  let open Term in
  const Cmd_analyze.Options.set $ mdg_opts

let analyze_cmd_opts : Cmd_analyze.Options.t Term.t =
  let open Term in
  const Cmd_analyze.Options.set_cmd
  $ Docs.FileOpts.inputs
  $ Docs.FileOpts.output
  $ Docs.SharedOpts.taint_config
  $ analyze_opts

let analyze_cmd : unit Exec.status Cmd.t =
  let open Docs.AnalyzeCmd in
  let info = Cmd.info name ~sdocs ~doc ~man ~man_xrefs ~exits in
  Cmd.v info Term.(const Cmd_analyze.main $ analyze_cmd_opts $ shared_opts)

let cmd_list : unit Exec.status Cmd.t list = [ parse_cmd; mdg_cmd; analyze_cmd ]

let main_cmd : unit Exec.status Cmd.t =
  let open Docs.Application in
  let default = Term.(ret (const (fun _ -> `Help (`Pager, None)) $ copts)) in
  let info = Cmd.info name ~sdocs ~doc ~version ~man ~man_xrefs ~exits in
  Cmd.group info ~default cmd_list

let eval_cmd : status -> int = function
  | Ok (`Help | `Version) -> Docs.ExitCodes.ok
  | Ok (`Ok (Ok ())) -> Docs.ExitCodes.ok
  | Ok (`Ok (Error (`DepTree _))) -> Docs.ExitCodes.deptree
  | Ok (`Ok (Error (`ParseJS _))) -> Docs.ExitCodes.parsejs
  | Ok (`Ok (Error (`BuildMDG _))) -> Docs.ExitCodes.build_mdg
  | Ok (`Ok (Error (`ExportMDG _))) -> Docs.ExitCodes.export_mdg
  | Ok (`Ok (Error (`Generic _))) -> Docs.ExitCodes.generic
  | Ok (`Ok (Error (`Failure _))) -> Docs.ExitCodes.internal
  | Ok (`Ok (Error `Timeout)) -> Docs.ExitCodes.timeout
  | Error `Term -> Docs.ExitCodes.term
  | Error `Parse -> Docs.ExitCodes.client
  | Error `Exn -> Docs.ExitCodes.internal

let () =
  Printexc.record_backtrace true;
  try Cmdliner.Cmd.eval_value main_cmd |> eval_cmd |> exit
  with exn ->
    flush_all ();
    Log.stderr "[graphjs] uncaught exception %s@." (Printexc.to_string exn);
    Printexc.print_backtrace stderr;
    exit Docs.ExitCodes.internal
