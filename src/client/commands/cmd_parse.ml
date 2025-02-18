open Graphjs_base
open Graphjs_ast
open Graphjs_share
open Graphjs_parser
open Result

module Options = struct
  type env =
    { mode : Analysis_mode.t
    ; test262_conform_hoisted : bool
    }

  type t =
    { inputs : Fpath.t list
    ; output : Fpath.t option
    ; env : env
    }

  let env (mode : Analysis_mode.t) (test262_conform_hoisted : bool) : env =
    { mode; test262_conform_hoisted }

  let cmd (inputs : Fpath.t list) (output : Fpath.t option) (env : env) : t =
    { inputs; output; env }
end

let set_temp_env (env : Options.env) : unit =
  (* FIXME: remove in favor of env structures *)
  Parser_config.(test262_conform_hoisted := env.test262_conform_hoisted)

module Output = struct
  let dep_tree (w : Workspace.t) (dt : Dependency_tree.t) : unit =
    let w' = Workspace.(w / "dep_tree.json") in
    Log.info "Dependency tree \"%a\" generated successfully." Fpath.pp dt.path;
    Log.verbose "%a" Dependency_tree.pp dt;
    Workspace.output_noerr Side w' Dependency_tree.pp dt

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

  let main (w : Workspace.t) (p : 'm Prog.t) : unit =
    let multifile = Prog.length p > 1 in
    Workspace.log w "%a@." (Prog.pp ~filename:multifile) p
end

let dep_tree (path : Fpath.t) (mode : Analysis_mode.t) () : Dependency_tree.t =
  Dependency_tree.generate mode (Fpath.to_string path)

let js_parser (path : Fpath.t) () : (Loc.t, Loc.t) Flow_ast.Program.t =
  Flow_parser.parse path

let js_normalizer (file : (Loc.t, Loc.t) Flow_ast.Program.t) () :
    Normalizer.n_stmt =
  Normalizer.normalize_file file

let generate_dependency_tree (env : Options.env) (w : Workspace.t)
    (path : Fpath.t) : Dependency_tree.t Exec.status =
  let* dt = Exec.graphjs (dep_tree path env.mode) in
  Output.dep_tree w dt;
  Ok dt

let normalize_program_modules (w : Workspace.t) (dt : Dependency_tree.t) :
    (Fpath.t * 'm File.t) Exec.status list =
  Fun.flip Dependency_tree.bottom_up_visit dt (fun (path, mrel) ->
      Output.source_file w path mrel;
      let* js_file = Exec.graphjs (js_parser path) in
      let* normalized_file = Exec.graphjs (js_normalizer js_file) in
      Output.normalized_file w mrel normalized_file;
      Ok (path, normalized_file) )

let run (env : Options.env) (w : Workspace.t) (input : Fpath.t) :
    (Dependency_tree.t * 'm Prog.t) Exec.status =
  set_temp_env env;
  let* dt = generate_dependency_tree env w input in
  let* files = Result.extract (normalize_program_modules w dt) in
  let prog = Prog.create files in
  Output.main w prog;
  Ok (dt, prog)

let outcome (result : (Dependency_tree.t * 'm Prog.t) Exec.status) :
    Bulk.Instance.outcome =
  match result with
  | Ok _ -> Success
  | Error (`DepTree _) -> Failure
  | Error (`ParseJS _) -> Failure
  | Error _ -> Anomaly

let interface (env : Options.env) : (module Bulk.CmdInterface) =
  ( module struct
    type t = Dependency_tree.t * Region.t Prog.t

    let cmd = Docs.ParseCmd.name
    let run = run env
    let outcome = outcome
  end )

let main (opts : Options.t) () : unit Exec.status =
  let w = Workspace.create ~default:`Bundle opts.inputs opts.output in
  let* _ = Workspace.prepare w in
  let* inputs = Bulk.InputTree.generate opts.inputs in
  let module Interface = (val interface opts.env) in
  let module Executor = Bulk.Executor (Interface) in
  Executor.execute w inputs
