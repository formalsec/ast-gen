open Graphjs_base
open Graphjs_analyzer
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
  (* let tainted (w : Workspace.t) (engine : Analysis_engine.t) : unit =
    let w' = Workspace.(w / "tainted.svg") in
    Log.info "Analysis engine initialized successfully";
    Workspace.execute_noerr Side w'
      (Fun.flip Svg_exporter.export_svg (`Mdg engine.mdg)) *)

  (* let pp_vulns (p : Fpath.t) (ppf : Fmt.t) (vs : Vulnerability.t list) : unit =
    if List.length vs > 0 then Fmt.(pp_lst !>"@\n" Vulnerability.pp) ppf vs
    else Fmt.fmt ppf "No vulnerabilities detected in \"%a\"." Fpath.pp p *)

  (* let main (w : Workspace.t) (path : Fpath.t) (vulns : Vulnerability.t list) :
      unit =
    Log.info "Vulnerability queries runned successfully.";
    Log.stdout "%a@." (pp_vulns path) vulns;
    match w.path with
    | None -> ()
    | Single _ -> Workspace.output_noerr Main w (pp_vulns path) vulns
    | Bundle _ ->
      let w' = Workspace.(w / "vulns.txt") in
      Workspace.output_noerr Side w' (pp_vulns path) vulns *)

end

let run (env : Options.env) (w : Workspace.t) (input : Fpath.t) :
    unit Exec.result =
  let* mdg = Cmd_mdg.run env.mdg_env (Workspace.side_perm w) input in
  let _engine = Analysis_engine.initialize mdg in
  (* Output.tainted w engine; *)
  (* ignore (Analyzer.run engine); *)
  (* Output.main w input vulns; *)
  Ok ()

let outcome (result : 'a Exec.result) : Bulk.Instance.outcome =
  match result with
  | Ok _ -> Success
  | Error (`DepTree _) -> Anomaly
  | Error (`ParseJS _) -> Anomaly
  | Error (`ExportMDG _) -> Anomaly
  | Error _ -> Anomaly

let bulk_interface (env : Options.env) : (module Bulk.CmdInterface) =
  ( module struct
    type t = unit

    let cmd = Docs.AnalyzeCmd.name
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
