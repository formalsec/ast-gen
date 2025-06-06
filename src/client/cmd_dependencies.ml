open Graphjs_parser
open Result

module Options = struct
  type env =
    { multifile : bool
    ; absolute_dependency_paths : bool
    }

  let validate_env (env : env) : env = env

  type t =
    { inputs : Fpath.t list
    ; output : Fpath.t option
    ; env : env
    }

  let env (absolute_dependency_paths : bool) : env =
    { multifile = true; absolute_dependency_paths }

  let cmd (inputs : Fpath.t list) (output : Fpath.t option) (env : env) : t =
    { inputs; output; env }
end

module Graphjs = struct
  let deptree (multifile : bool) (path : Fpath.t) :
      Dependency_tree.t Exec.result =
    Exec.graphjs (fun () -> Dependency_tree.generate multifile path)
end

module Output = struct
  let deptree (abs : bool) (w : Workspace.t) (dt : Dependency_tree.t) : unit =
    let w' = Workspace.(w / "deptree.json") in
    Log.info "Dependency tree \"%a\" generated successfully." Fpath.pp dt.path;
    Log.verbose "%a" (Dependency_tree.pp abs) dt;
    Workspace.output_noerr Side w' (Dependency_tree.pp abs) dt

  let main (abs : bool) (w : Workspace.t) (dt : Dependency_tree.t) : unit =
    Workspace.log w "%a" (Dependency_tree.pp abs) dt;
    match w.path with
    | Single _ -> Workspace.output_noerr Main w (Dependency_tree.pp abs) dt
    | _ -> ()
end

let run (env : Options.env) (w : Workspace.t) (input : Fpath.t) :
    Dependency_tree.t Exec.result =
  let* dt = Graphjs.deptree env.multifile input in
  Output.deptree env.absolute_dependency_paths w dt;
  Output.main env.absolute_dependency_paths w dt;
  Ok dt

let outcome (res : Dependency_tree.t Exec.result) : Bulk.Instance.outcome =
  match res with
  | Ok _ -> Success
  | Error (`DepTree _) -> Failure
  | Error _ -> Anomaly

let interface (env : Options.env) : (module Bulk.CmdInterface) =
  ( module struct
    type t = Dependency_tree.t

    let cmd = Docs.DependenciesCmd.name
    let run = run (Options.validate_env env)
    let outcome = outcome
  end )

let main (opts : Options.t) () : unit Exec.result =
  let ext = Some "json" in
  let w = Workspace.create ~default:(`Single ext) opts.inputs opts.output in
  let* _ = Workspace.prepare w in
  let* inputs = Bulk.InputTree.generate opts.inputs in
  let module Interface = (val interface opts.env) in
  let module Executor = Bulk.Executor (Interface) in
  Executor.execute_only w inputs
