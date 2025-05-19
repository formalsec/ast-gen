open Graphjs_base
open Graphjs_query
open Result

module Options = struct
  type env = { mdg_env : Cmd_mdg.Options.env }

  let validate_env (env : env) : env =
    match env.mdg_env.func_eval_mode with
    | Opaque ->
      Log.warn "Unable to run built-in queries with 'opaque' function eval.";
      Log.warn "Defaulting function evaluation mode to 'unfold:rec'...";
      { mdg_env = { env.mdg_env with func_eval_mode = UnfoldRec } }
    | _ -> env

  type t =
    { inputs : Fpath.t list
    ; output : Fpath.t option
    ; env : env
    }

  let env (mdg_env : Cmd_mdg.Options.env) : env = { mdg_env }

  let cmd (inputs : Fpath.t list) (output : Fpath.t option) (env : env) : t =
    { inputs; output; env }
end

module Output = struct
  let pp_mrel (ppf : Fmt.t) (mrel : Fpath.t option) : unit =
    match mrel with
    | None -> Fmt.pp_str ppf "."
    | Some mrel' -> Fmt.fmt ppf " for \"%a\"" Fpath.pp mrel'

  let engine (mrel : Fpath.t option) : unit =
    Log.info "Analysis engine initialized successfully%a" pp_mrel mrel

  let main (w : Workspace.t) (path : Fpath.t) (mrel : Fpath.t option)
      (vulns : Vulnerability.Set.t) : unit =
    Log.info "Vulnerability queries ran successfully%a" pp_mrel mrel;
    Log.verbose "%a@." (Vulnerability.Set.pp path) vulns;
    Workspace.log w "%a" (Vulnerability.Set.pp path) vulns;
    match (w.path, mrel) with
    | (Single _, _) ->
      Workspace.output_noerr Main w Vulnerability.Set.pp_json vulns
    | (Bundle _, None) ->
      let w' = Workspace.(w / "detected.json") in
      Workspace.output_noerr Side w' Vulnerability.Set.pp_json vulns
    | _ -> ()
end

let run ?(mrel : Fpath.t option) (env : Options.env) (w : Workspace.t)
    (input : Fpath.t) : Vulnerability.Set.t Exec.result =
  let* e_mdg = Cmd_mdg.run env.mdg_env (Workspace.side_perm w) input in
  let engine = Query_engine.initialize e_mdg in
  Output.engine mrel;
  let vulns = Builtin_queries.run engine in
  Output.main w input mrel vulns;
  Ok vulns

let outcome (res : Vulnerability.Set.t Exec.result) : Bulk.Instance.outcome =
  match res with
  | Ok _ -> Success
  | Error (`DepTree _) -> Failure
  | Error (`ParseJS _) -> Failure
  | Error (`ExportMDG _) -> Anomaly
  | Error _ -> Anomaly

let bulk_interface (env : Options.env) : (module Bulk.CmdInterface) =
  ( module struct
    type t = Vulnerability.Set.t

    let cmd = Docs.QueryCmd.name
    let run = run (Options.validate_env env)
    let outcome = outcome
  end )

let main (opts : Options.t) () : unit Exec.result =
  let ext = Some "json" in
  let w = Workspace.create ~default:(`Single ext) opts.inputs opts.output in
  let* _ = Workspace.prepare w in
  let* inputs = Bulk.InputTree.generate opts.inputs in
  let module Interface = (val bulk_interface opts.env) in
  let module Executor = Bulk.Executor (Interface) in
  Executor.execute_only w inputs
