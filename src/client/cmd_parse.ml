open Graphjs_base
open Graphjs_share
open Graphjs_parser
open Graphjs_ast
open Result

module Options = struct
  type env =
    { mode : Analysis_mode.t
    ; always_fresh : bool
    ; disable_hoisting : bool
    ; disable_defaults : bool
    ; disable_short_circuit : bool
    ; disable_aliases : bool
    ; deps_env : Cmd_dependencies.Options.env
    }

  type t =
    { inputs : Fpath.t list
    ; output : Fpath.t option
    ; env : env
    }

  let env (mode : Analysis_mode.t) (always_fresh : bool)
      (disable_hoisting : bool) (disable_defaults : bool)
      (disable_short_circuit : bool) (disable_aliases : bool)
      (deps_env : Cmd_dependencies.Options.env) : env =
    { mode
    ; always_fresh
    ; disable_hoisting
    ; disable_defaults
    ; disable_short_circuit
    ; disable_aliases
    ; deps_env
    }

  let cmd (inputs : Fpath.t list) (output : Fpath.t option) (env : env) : t =
    { inputs; output; env }
end

module Graphjs = struct
  let normalize_program (env : Normalizer.Env.t) (dt : Dependency_tree.t) :
      Region.t Prog.t Exec.result =
    Exec.graphjs (fun () -> Normalizer.normalize_program env dt)
end

module Output = struct
  let source_file (w : Workspace.t) (path : Fpath.t) (mrel : Fpath.t) : unit =
    let w' = Workspace.(w / "input" // mrel) in
    Log.info "Initializing normalization of the '%a' module..." Fpath.pp mrel;
    Workspace.mkdir_noerr Side w';
    Workspace.copy_noerr Side w' path

  let normalized_file (w : Workspace.t) (mrel : Fpath.t) (file : 'm File.t) :
      unit =
    let w' = Workspace.(w / "code" // mrel) in
    Log.info "Module '%a' normalized successfully." Fpath.pp mrel;
    Log.verbose "%a" File.pp file;
    Workspace.mkdir_noerr Side w';
    Workspace.output_noerr Side w' File.pp file

  let main (w : Workspace.t) (prog : 'm Prog.t) : unit =
    let multifile = Prog.is_multifile prog in
    Workspace.log w "%a@." (Prog.pp ~filename:multifile) prog
end

let normalizer_env (env : Options.env) (w : Workspace.t) : Normalizer.Env.t =
  { always_fresh = env.always_fresh
  ; disable_hoisting = env.disable_hoisting
  ; disable_defaults = env.disable_defaults
  ; disable_short_circuit = env.disable_short_circuit
  ; disable_aliases = env.disable_aliases
  ; cb_source = Output.source_file w
  ; cb_normalized = Output.normalized_file w
  }

let run (env : Options.env) (w : Workspace.t) (input : Fpath.t) :
    'm Prog.t Exec.result =
  let normalizer_env = normalizer_env env w in
  let* dt = Cmd_dependencies.generate_dep_tree env.deps_env w env.mode input in
  let* prog = Graphjs.normalize_program normalizer_env dt in
  Output.main w prog;
  Ok prog

let outcome (result : 'm Prog.t Exec.result) : Bulk.Instance.outcome =
  match result with
  | Ok _ -> Success
  | Error (`DepTree _) -> Failure
  | Error (`ParseJS _) -> Failure
  | Error _ -> Anomaly

let interface (env : Options.env) : (module Bulk.CmdInterface) =
  ( module struct
    type t = Region.t Prog.t

    let cmd = Docs.ParseCmd.name
    let run = run env
    let outcome = outcome
  end )

let main (opts : Options.t) () : unit Exec.result =
  let w = Workspace.create ~default:`Bundle opts.inputs opts.output in
  let* _ = Workspace.prepare w in
  let* inputs = Bulk.InputTree.generate opts.inputs in
  let module Interface = (val interface opts.env) in
  let module Executor = Bulk.Executor (Interface) in
  Executor.execute w inputs
