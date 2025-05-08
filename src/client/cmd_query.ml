open Graphjs_base
open Graphjs_query
open Result

module Options = struct
  type env = { mdg_env : Cmd_mdg.Options.env }

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
  let engine () : unit = Log.info "Analysis engine initialized successfully."

  let main (w : Workspace.t) (path : Fpath.t) (vulns : Vulnerability.Set.t) :
      unit =
    Log.info "Vulnerability queries ran successfully.";
    Log.stdout "%a@." (Vulnerability.Set.pp path) vulns;
    match w.path with
    | None -> ()
    | Single _ ->
      Workspace.output_noerr Main w (Vulnerability.Set.pp path) vulns
    | Bundle _ ->
      let w' = Workspace.(w / "vulns.txt") in
      Workspace.output_noerr Side w' (Vulnerability.Set.pp path) vulns
end

let validate_mdg_env (env : Cmd_mdg.Options.env) : Cmd_mdg.Options.env =
  match env.func_eval_mode with
  | Opaque ->
    Log.warn "Unable to run built-in queries with 'opaque' function evaluation.";
    Log.warn "Defaulting function evaluation mode to 'unfold:rec'...";
    { env with func_eval_mode = UnfoldRec }
  | _ -> env

let run (env : Options.env) (w : Workspace.t) (input : Fpath.t) :
    unit Exec.result =
  let mdg_env = validate_mdg_env env.mdg_env in
  let* e_mdg = Cmd_mdg.run mdg_env (Workspace.side_perm w) input in
  let engine = Query_engine.initialize e_mdg in
  Output.engine ();
  let vulns = Builtin_queries.run engine in
  Output.main w input vulns;
  Ok ()

let outcome (res : 'a Exec.result) : Bulk.Instance.outcome =
  match res with Ok _ -> Success | Error _ -> Anomaly

let bulk_interface (env : Options.env) : (module Bulk.CmdInterface) =
  ( module struct
    type t = unit

    let cmd = Docs.QueryCmd.name
    let run = run env
    let outcome = outcome
  end )

let main (opts : Options.t) () : unit Exec.result =
  let w = Workspace.create ~default:`None opts.inputs opts.output in
  let* _ = Workspace.prepare w in
  let* inputs = Bulk.InputTree.generate opts.inputs in
  let module Interface = (val bulk_interface opts.env) in
  let module Executor = Bulk.Executor (Interface) in
  Executor.execute w inputs
