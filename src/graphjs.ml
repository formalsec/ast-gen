open Graphjs_base
open Graphjs_client
open Cmdliner

type status = (unit Exec.result Cmd.eval_ok, Cmd.eval_error) Result.t

let set_copts (colorless : bool) (lvl : Enums.DebugLvl.t) (verbose : bool)
    (override' : bool) : unit =
  Font.Config.(colored := not colorless);
  Log.Config.(log_warns := lvl >= Warn);
  Log.Config.(log_infos := verbose || lvl >= Info);
  Log.Config.(log_debugs := lvl >= All);
  Log.Config.(log_verbose := verbose);
  Workspace.Config.(override := override')

let copts =
  let open Term in
  const set_copts
  $ Docs.CommonOpts.colorless
  $ Docs.CommonOpts.debug
  $ Docs.CommonOpts.verbose
  $ Docs.CommonOpts.override

let dependencies_env =
  let open Term in
  const Cmd_dependencies.Options.env
  $ Docs.DependenciesOpts.absolute_dependency_paths

let dependencies_opts =
  let open Term in
  const Cmd_dependencies.Options.cmd
  $ Docs.FileOpts.input_paths
  $ Docs.FileOpts.output_path
  $ dependencies_env

let dependencies_cmd =
  let open Docs.DependenciesCmd in
  let info = Cmd.info name ~doc ~sdocs ~man ~man_xrefs ~exits in
  Cmd.v info Term.(const Cmd_dependencies.main $ dependencies_opts $ copts)

let parse_env =
  let open Term in
  const Cmd_parse.Options.env
  $ Docs.DependenciesOpts.multifile
  $ Docs.ParseOpts.always_fresh
  $ Docs.ParseOpts.disable_hoisting
  $ Docs.ParseOpts.disable_defaults
  $ Docs.ParseOpts.disable_short_circuit
  $ Docs.ParseOpts.disable_aliases
  $ dependencies_env

let parse_opts =
  let open Term in
  const Cmd_parse.Options.cmd
  $ Docs.FileOpts.input_paths
  $ Docs.FileOpts.output_dir
  $ parse_env

let parse_cmd =
  let open Docs.ParseCmd in
  let info = Cmd.info name ~doc ~sdocs ~man ~man_xrefs ~exits in
  Cmd.v info Term.(const Cmd_parse.main $ parse_opts $ copts)

let mdg_env =
  let open Term in
  const Cmd_mdg.Options.env
  $ Docs.MdgOpts.taint_config
  $ Docs.MdgOpts.func_eval_mode
  $ Docs.MdgOpts.no_exported_analysis
  $ Docs.MdgOpts.no_tainted_analysis
  $ Docs.MdgOpts.no_cleaner_analysis
  $ Docs.MdgOpts.no_export
  $ Docs.MdgOpts.no_subgraphs
  $ Docs.MdgOpts.no_func_subgraphs
  $ Docs.MdgOpts.no_file_subgraphs
  $ Docs.MdgOpts.export_view
  $ Docs.MdgOpts.export_timeout
  $ parse_env

let mdg_opts =
  let open Term in
  const Cmd_mdg.Options.cmd
  $ Docs.FileOpts.input_paths
  $ Docs.FileOpts.output_path
  $ mdg_env

let mdg_cmd =
  let open Docs.MdgCmd in
  let info = Cmd.info name ~doc ~sdocs ~man ~man_xrefs ~exits in
  Cmd.v info Term.(const Cmd_mdg.main $ mdg_opts $ copts)

let query_env =
  let open Term in
  const Cmd_query.Options.env $ mdg_env

let query_opts =
  let open Term in
  const Cmd_query.Options.cmd
  $ Docs.FileOpts.input_paths
  $ Docs.FileOpts.output_path
  $ query_env

let query_cmd =
  let open Docs.QueryCmd in
  let info = Cmd.info name ~doc ~sdocs ~man ~man_xrefs ~exits in
  Cmd.v info Term.(const Cmd_query.main $ query_opts $ copts)

let validate_env =
  let open Term in
  const Cmd_validate.Options.env $ query_env

let validate_opts =
  let open Term in
  const Cmd_validate.Options.cmd
  $ Docs.FileOpts.input_dirs
  $ Docs.FileOpts.output_dir
  $ validate_env

let validate_cmd =
  let open Docs.ValidateCmd in
  let info = Cmd.info name ~doc ~sdocs ~man ~man_xrefs ~exits in
  Cmd.v info Term.(const Cmd_validate.main $ validate_opts $ copts)

let cmd_list = [ dependencies_cmd; parse_cmd; mdg_cmd; query_cmd; validate_cmd ]

let main_cmd =
  let open Docs.Application in
  let default = Term.(ret (const (fun _ -> `Help (`Pager, None)) $ copts)) in
  let info = Cmd.info name ~doc ~sdocs ~version ~man ~man_xrefs ~exits in
  Cmd.group info ~default cmd_list

let eval_cmd (status : status) =
  match status with
  | Ok (`Help | `Version) -> Docs.ExitCodes.ok
  | Ok (`Ok (Ok ())) -> Docs.ExitCodes.ok
  | Ok (`Ok (Error (`Generic _))) -> Docs.ExitCodes.generic
  | Ok (`Ok (Error (`Failure _))) -> Docs.ExitCodes.internal
  | Ok (`Ok (Error `Timeout)) -> Docs.ExitCodes.timeout
  | Ok (`Ok (Error (`DepTree _))) -> Docs.ExitCodes.deptree
  | Ok (`Ok (Error (`ParseJS _))) -> Docs.ExitCodes.parsejs
  | Ok (`Ok (Error (`ExportMDG _))) -> Docs.ExitCodes.export_mdg
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
