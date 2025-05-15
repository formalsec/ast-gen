open Graphjs_base
open Graphjs_query
open Result

module Options = struct
  type env = { query_env : Cmd_query.Options.env }

  type t =
    { inputs : Fpath.t list
    ; output : Fpath.t option
    ; env : env
    }

  let env (query_env : Cmd_query.Options.env) : env = { query_env }

  let cmd (inputs : Fpath.t list) (output : Fpath.t option) (env : env) : t =
    { inputs; output; env }
end

module Parser = struct
  let expected (input : Fpath.t) : Json.t Exec.result =
    let fpath = Fpath.(input / "expected" / "detection.json") in
    let* exists = Fs.exists fpath in
    if exists then Ok (Json.from_file (Fpath.to_string fpath))
    else Exec.error "Cannot find expected query results \"%a\"" Fpath.pp fpath

  let extended (input : Fpath.t) : Json.t option Exec.result =
    let warn_f fpath =
      Log.warn "Cannot find extended query results \"%a\"" Fpath.pp fpath in
    let fpath = Fpath.(input / "expected" / "detection_extended.json") in
    let* exists = Fs.exists fpath in
    if exists then Ok (Some (Json.from_file (Fpath.to_string fpath)))
    else warn_f fpath |> fun () -> Ok None

  let sources (input : Fpath.t) : Fpath.t list Exec.result =
    let fpath = Fpath.(input / "src") in
    let* sources = Exec.bos (Bos.OS.Dir.contents ~rel:true fpath) in
    Ok (List.filter (Fpath.has_ext "js") sources)
end

module Output = struct
  let detected (w : Workspace.t) (vulns : Vulnerability.Set.t) : unit =
    let w' = Workspace.(w / "query" / "detected.json") in
    Workspace.mkdir_noerr Side w';
    Workspace.output_noerr Side w' Vulnerability.Set.pp_json vulns

  let expected (w : Workspace.t) (expected : Query_expected.t) : unit =
    let w' = Workspace.(w / "query" / "expected.json") in
    Log.info "Expected query results read successfully.";
    Log.verbose "%a" Query_expected.pp expected;
    Workspace.output_noerr Side w' Query_expected.pp expected

  let validate (w : Workspace.t) (path : Fpath.t)
      (confirm : Query_expected.Validation.t) : unit =
    let w' = Workspace.(w / "query" / "confirmation.txt") in
    Log.info "Package \"%a\" successfully validated." Fpath.pp path;
    Log.verbose "%a" Query_expected.Validation.pp confirm;
    Workspace.output_noerr Side w' Query_expected.Validation.pp confirm

  let main (w : Workspace.t) (confirm : Query_expected.Validation.t) : unit =
    Workspace.log w "%a" Query_expected.Validation.pp confirm;
    match w.path with
    | Single _ ->
      Workspace.output_noerr Main w Query_expected.Validation.pp confirm
    | _ -> ()
end

let get_query_expected (input : Fpath.t) : Query_expected.t Exec.result =
  let* expected = Parser.expected input in
  let* extended = Parser.extended input in
  Query_expected.parse expected extended

let run_queries (env : Cmd_query.Options.env) (w : Workspace.t) (input : Fpath.t)
    : Vulnerability.Set.t Exec.result =
  let* sources = Parser.sources input in
  let vulns = Ok Vulnerability.Set.empty in
  Fun.flip2 List.fold_left vulns sources (fun acc mrel ->
      let* acc' = acc in
      let input' = Fpath.(input / "src" // mrel) in
      let* vulns = Cmd_query.run ~mrel env (Workspace.side_perm w) input' in
      Ok (Vulnerability.Set.union vulns acc') )

let run (env : Options.env) (w : Workspace.t) (input : Fpath.t) :
    Query_expected.Validation.t Exec.result =
  let* vulns = run_queries env.query_env w input in
  Output.detected w vulns;
  let* expected = get_query_expected input in
  Output.expected w expected;
  let valid = Query_expected.Validation.validate expected vulns in
  Output.validate w input valid;
  Ok valid

let outcome (res : Query_expected.Validation.t Exec.result) :
    Bulk.Instance.outcome =
  match res with
  | Ok confirm ->
    if confirm.tp == confirm.exp.tp then
      if confirm.tfp == confirm.exp.tfp then Success else Partial
    else Failure
  | Error _ -> Anomaly

let bulk_interface (env : Options.env) : (module Bulk.CmdInterface) =
  ( module struct
    type t = Query_expected.Validation.t

    let cmd = Docs.QueryCmd.name
    let run = run env
    let outcome = outcome
  end )

let main (opts : Options.t) () : unit Exec.result =
  let w = Workspace.create ~default:`Bundle opts.inputs opts.output in
  let* _ = Workspace.prepare w in
  let* inputs = Bulk.InputTree.generate opts.inputs in
  let module Interface = (val bulk_interface opts.env) in
  let module Executor = Bulk.Executor (Interface) in
  Executor.execute w inputs
