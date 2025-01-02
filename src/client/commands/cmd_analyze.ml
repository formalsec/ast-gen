open Graphjs_base
open Graphjs_share
open Graphjs_analyzer
open Result

module Options = struct
  type t =
    { inputs : Fpath.t list
    ; output : Fpath.t option
    ; taint_config : Fpath.t
    }

  let set () : unit = ()

  let set_cmd (inputs : Fpath.t list) (output : Fpath.t option)
      (taint_config' : Fpath.t option) () : t =
    let taint_config = Share.parse_taint_config taint_config' in
    { inputs; output; taint_config }
end

module Output = struct
  let main (w : Workspace.t) (vulns : Vulnerability.t list) : unit =
    Log.info "Vulnerability queries runned successfully.";
    Workspace.log w Fmt.(dly "%a@." (pp_lst !>"@\n" Vulnerability.pp) vulns);
    Workspace.output_noerr Side w Fmt.(pp_lst !>"@\n" Vulnerability.pp) vulns
end

let run (tc : Taint_config.t) (input : Fpath.t) (w : Workspace.t) :
    Vulnerability.t list Exec.status =
  let* mdg = Cmd_mdg.run tc input (Workspace.side w) in
  let engine = Analysis_engine.initialize mdg in
  let vulns = Analyzer.run engine in
  Output.main w vulns;
  Ok vulns

let outcome (result : 'a Exec.status) : Bulk.Instance.outcome =
  match result with
  | Ok _ -> Success
  | Error (`DepTree _) -> Failure
  | Error (`ParseJS _) -> Failure
  | Error (`BuildMDG _) -> Failure
  | Error (`ExportMDG _) -> Anomaly
  | Error _ -> Anomaly

let bulk_interface (tc : Taint_config.t) : (module Bulk.CmdInterface) =
  ( module struct
    type t = Vulnerability.t list

    let cmd = "mdg"
    let run = run tc
    let outcome = outcome
  end )

let main (opts : Options.t) () : unit Exec.status =
  let w = Workspace.create ~default:`None opts.inputs opts.output in
  let* () = Workspace.clean w in
  let* ipairs = Bulk.InputTree.generate opts.inputs in
  let* tc = Exec.graphjs (Share.read_taint_config w opts.taint_config) in
  let module Interface = (val bulk_interface tc) in
  let module Executor = Bulk.Executor (Interface) in
  Executor.execute w ipairs
