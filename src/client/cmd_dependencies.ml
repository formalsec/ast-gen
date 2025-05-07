open Graphjs_base
open Graphjs_share
open Graphjs_parser
open Result

module Options = struct
  type env = { absolute_dependency_paths : bool }

  type t =
    { inputs : Fpath.t list
    ; output : Fpath.t option
    ; env : env
    }

  let env (absolute_dependency_paths : bool) : env =
    { absolute_dependency_paths }

  let cmd (inputs : Fpath.t list) (output : Fpath.t option) (env : env) : t =
    { inputs; output; env }
end

module Graphjs = struct
  let dep_tree (mode : Analysis_mode.t) (path : Fpath.t) :
      Dependency_tree.t Exec.result =
    Exec.graphjs (fun () -> Dependency_tree.generate mode path)
end

module Output = struct
  let dep_tree (abs : bool) (w : Workspace.t) (dt : Dependency_tree.t) : unit =
    let w' = Workspace.(w / "dep_tree.json") in
    Log.info "Dependency tree \"%a\" generated successfully." Fpath.pp dt.path;
    Log.verbose "%a" (Dependency_tree.pp abs) dt;
    Workspace.output_noerr Side w' (Dependency_tree.pp abs) dt

  let main (abs : bool) (w : Workspace.t) (dt : Dependency_tree.t) : unit =
    Workspace.log w "%a@." (Dependency_tree.pp abs) dt;
    match w.path with
    | Single _ -> Workspace.output_noerr Main w (Dependency_tree.pp abs) dt
    | _ -> ()
end

let generate_dep_tree (env : Options.env) (w : Workspace.t)
    (mode : Analysis_mode.t) (path : Fpath.t) : Dependency_tree.t Exec.result =
  let* dt = Graphjs.dep_tree mode path in
  Output.dep_tree env.absolute_dependency_paths w dt;
  Ok dt

let run (env : Options.env) (w : Workspace.t) (input : Fpath.t) :
    Dependency_tree.t Exec.result =
  let* dt = generate_dep_tree env w MultiFile input in
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
    let run = run env
    let outcome = outcome
  end )

let main (opts : Options.t) () : unit Exec.result =
  let ext = Some "json" in
  let w = Workspace.create ~default:(`Single ext) opts.inputs opts.output in
  let* _ = Workspace.prepare w in
  let* inputs = Bulk.InputTree.generate opts.inputs in
  let module Interface = (val interface opts.env) in
  let module Executor = Bulk.Executor (Interface) in
  Executor.execute w inputs
