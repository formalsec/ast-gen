open Graphjs_mdg
open Graphjs_query
open Result

module Options = struct
  type env = { query_env : Cmd_query.Options.env }

  let validate_env (env : env) : env =
    let query_env = Cmd_query.Options.validate_env env.query_env in
    let mdg_env = { query_env.mdg_env with reset_locations = false } in
    { query_env = { mdg_env } }

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

  let validate (w : Workspace.t) (path : Fpath.t) (valid : Query_validation.t) :
      unit =
    let w' = Workspace.(w / "query" / "confirmation.txt") in
    Log.info "Package \"%a\" successfully validated." Fpath.pp path;
    Log.verbose "%a" Query_validation.pp valid;
    Workspace.output_noerr Side w' Query_validation.pp valid

  let main (w : Workspace.t) (valid : Query_validation.t) : unit =
    Workspace.log w "%a" Query_validation.pp valid;
    match w.path with
    | Single _ -> Workspace.output_noerr Main w Query_validation.pp valid
    | _ -> ()
end

module Csv_exporter = struct
  let dataset_segment (seg : string) : string option =
    let regex = Str.regexp (Fmt.str "^\\([^-]+\\)-dataset$") in
    if Str.string_match regex seg 0 then Some (Str.matched_group 1 seg)
    else None

  let cwe_segment (seg : string) : bool =
    let regex = Str.regexp (Fmt.str "^CWE-[0-9]+$") in
    Str.string_match regex seg 0

  let pp_field (ppf : Fmt.t) (field : string option) : unit =
    match field with
    | None -> Fmt.pp_str ppf "-"
    | Some field' -> Fmt.pp_str ppf field'

  let pp_outcome (ppf : Fmt.t) (outcome : Bulk.Instance.outcome) : unit =
    match outcome with
    | Success -> Fmt.fmt ppf "Success"
    | Partial -> Fmt.fmt ppf "Partial"
    | Failure -> Fmt.fmt ppf "Failure"
    | Anomaly -> Fmt.fmt ppf "Anomaly"
    | Timeout -> Fmt.fmt ppf "Timeout"
    | Skipped -> Fmt.fmt ppf "Untested"

  let pp_result (ppf : Fmt.t) (result : Query_validation.t Exec.result) : unit =
    match result with
    | Error _ -> Fmt.fmt ppf "-,-,-,-,-"
    | Ok valid ->
      Fmt.fmt ppf "%d,%d,%d,%d,%d" valid.tp valid.tpe valid.tfp valid.e_tp
        valid.e_tpe

  let pp_instance (ppf : Fmt.t) (instance : Query_validation.t Bulk.Instance.t)
      : unit =
    let segs = Fpath.segs instance.input in
    let dataset = List.find_map dataset_segment segs in
    let cwe = List.find_opt cwe_segment segs in
    let package = List.nth segs (List.length segs - 2) in
    Fmt.fmt ppf "%a,%a,%s,%a,%a" pp_field dataset pp_field cwe package
      pp_outcome instance.outcome pp_result instance.result

  let export_results (w : Workspace.t)
      (instances : Query_validation.t Bulk.Instance.t list) : unit =
    let w' = Workspace.(w / "validation.csv") in
    let instances' = List.sort Bulk.Instance.compare instances in
    let pp_validation = Fmt.(pp_lst !>"@\n" pp_instance) in
    Workspace.output_noerr Main w' pp_validation instances'
end

let run_queries (env : Cmd_query.Options.env) (w : Workspace.t) (input : Fpath.t)
    : Vulnerability.Set.t Exec.result =
  let* sources = Parser.sources input in
  Fun.flip2 List.fold_left (Ok Vulnerability.Set.empty) sources (fun acc mrel ->
      let* acc' = acc in
      let input' = Fpath.(input / "src" // mrel) in
      let* vulns = Cmd_query.run ~mrel env (Workspace.side_perm w) input' in
      Ok (Vulnerability.Set.union vulns acc') )

let get_query_expected (input : Fpath.t) : Query_expected.t Exec.result =
  let* expected = Parser.expected input in
  let* extended = Parser.extended input in
  Query_expected.parse expected extended

let run (env : Options.env) (w : Workspace.t) (input : Fpath.t) :
    Query_validation.t Exec.result =
  Location.reset_generator ();
  let* vulns = run_queries env.query_env w input in
  Output.detected w vulns;
  let* expected = get_query_expected input in
  Output.expected w expected;
  let valid = Query_validation.validate expected vulns in
  Output.validate w input valid;
  Output.main w valid;
  Ok valid

let outcome (res : Query_validation.t Exec.result) : Bulk.Instance.outcome =
  match res with
  | Ok confirm ->
    if confirm.tp == confirm.e_tp then
      if confirm.tpe == confirm.e_tpe then Success else Partial
    else Failure
  | Error _ -> Anomaly

let bulk_interface (env : Options.env) :
    (module Bulk.CmdInterface with type t = Query_validation.t) =
  ( module struct
    type t = Query_validation.t

    let cmd = Docs.QueryCmd.name
    let run = run (Options.validate_env env)
    let outcome = outcome
  end )

let main (opts : Options.t) () : unit Exec.result =
  let w = Workspace.create ~default:`Bundle opts.inputs opts.output in
  let* _ = Workspace.prepare w in
  let* inputs = Bulk.InputTree.generate opts.inputs in
  let module Interface = (val bulk_interface opts.env) in
  let module Executor = Bulk.Executor (Interface) in
  let instances = Executor.execute w inputs in
  Csv_exporter.export_results w instances;
  Executor.execution_result instances
