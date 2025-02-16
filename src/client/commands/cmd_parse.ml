open Graphjs_base
open Graphjs_ast
open Graphjs_parser
open Result

module Options = struct
  type t =
    { inputs : Fpath.t list
    ; output : Fpath.t option
    }

  let set (test262_conform_hoisted' : bool) : unit =
    Parser_config.(test262_conform_hoisted := test262_conform_hoisted')

  let set_cmd (inputs : Fpath.t list) (output : Fpath.t option) () : t =
    { inputs; output }
end

module Output = struct
  let dep_tree (w : Workspace.t) (dt : Dependency_tree.t) : unit =
    let w' = Workspace.(w / "dep_tree.json") in
    Log.info "Dependency tree \"%a\" generated successfully." Fpath.pp dt.path;
    Log.verbose "%a" Dependency_tree.pp dt;
    Workspace.output_noerr Side w' Dependency_tree.pp dt

  let source_file (w : Workspace.t) (path : Fpath.t) (mrel : Fpath.t) : unit =
    let w' = Workspace.(w / "input" // mrel) in
    Workspace.mkdir_noerr Side w';
    Workspace.copy_noerr Side w' path

  let normalized_file (w : Workspace.t) (path : Fpath.t) (mrel : Fpath.t)
      (file : 'm File.t) : unit =
    let w' = Workspace.(w / "code" // mrel) in
    Log.info "File \"%a\" normalized successfully." Fpath.pp path;
    Log.verbose "%a" File.pp file;
    Workspace.mkdir_noerr Side w';
    Workspace.output_noerr Side w' File.pp file

  let main (w : Workspace.t) (dt : Dependency_tree.t) (p : 'm Prog.t) : unit =
    let pp_prog = Prog.pp ~filename:(Dependency_tree.multi_file dt) in
    Workspace.log w (Fmt.dly "%a@." pp_prog p)
end

let dep_tree (w : Workspace.t) (path : Fpath.t) () : Dependency_tree.t =
  let dt = Dependency_tree.generate path in
  Output.dep_tree w dt;
  dt

let js_parser (path : Fpath.t) () : (Loc.t, Loc.t) Flow_ast.Program.t =
  Flow_parser.parse path

let js_normalizer (file : (Loc.t, Loc.t) Flow_ast.Program.t) () :
    Normalizer.n_stmt =
  Normalizer.normalize_file file

let normalized_files (w : Workspace.t) (dt : Dependency_tree.t) :
    (Fpath.t * 'm File.t) Exec.status list =
  Fun.flip Dependency_tree.bottom_up_visit dt (fun (path, mrel) ->
      Output.source_file w path mrel;
      let* js_file = Exec.graphjs (js_parser path) in
      let* file = Exec.graphjs (js_normalizer js_file) in
      Output.normalized_file w path mrel file;
      Ok (path, file) )

let normalized_prog (w : Workspace.t) (dt : Dependency_tree.t) :
    'm Prog.t Exec.status =
  let* files = Result.extract (normalized_files w dt) in
  Ok (Prog.create files)

let run (input : Fpath.t) (w : Workspace.t) :
    (Dependency_tree.t * 'm Prog.t) Exec.status =
  let* _ = Workspace.mkdir Side w in
  let* dt = Exec.graphjs (dep_tree w input) in
  let* prog = normalized_prog w dt in
  Output.main w dt prog;
  Ok (dt, prog)

let outcome (result : (Dependency_tree.t * 'm Prog.t) Exec.status) :
    Bulk.Instance.outcome =
  match result with
  | Ok _ -> Success
  | Error (`DepTree _) -> Failure
  | Error (`ParseJS _) -> Failure
  | Error _ -> Anomaly

let bulk_interface () : (module Bulk.CmdInterface) =
  ( module struct
    type t = Dependency_tree.t * Region.t Prog.t

    let cmd = "parse"
    let run = run
    let outcome = outcome
  end )

let main (opts : Options.t) () : unit Exec.status =
  let w = Workspace.create ~default:`Bundle opts.inputs opts.output in
  let* () = Workspace.clean w in
  let* ipairs = Bulk.InputTree.generate opts.inputs in
  let module Interface = (val bulk_interface ()) in
  let module Executor = Bulk.Executor (Interface) in
  Executor.execute w ipairs
