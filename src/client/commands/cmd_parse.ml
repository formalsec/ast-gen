open Graphjs_base
open Graphjs_parser
open Graphjs_ast
open Result

module Options = struct
  type t =
    { input : Fpath.t
    ; output : Fpath.t option
    }

  let set (test262_conform_hoisted' : bool) : unit =
    Parser_config.(test262_conform_hoisted $= test262_conform_hoisted')

  let set_cmd (input : Fpath.t) (output : Fpath.t option) () : t =
    { input; output }
end

module Output = struct
  let dep_tree (output : Fpath.t option) (dt : Dependency_tree.t) : unit =
    let path = Fs.OptPath.(create Dir output / "dep_tree.json") in
    Log.verbose "%a" Dependency_tree.pp dt;
    Fs.write_noerr path (Fmt.dly "%a" Dependency_tree.pp dt)

  let source_file (output : Fpath.t option) (rel : Fpath.t) (abs : Fpath.t) :
      unit =
    let path = Fs.OptPath.(create Dir output / "input" // rel) in
    Fs.copy_noerr path abs

  let normalized_file (output : Fpath.t option) (rel : Fpath.t)
      (file : 'm File.t) : unit =
    let path = Fs.OptPath.(create Dir output / "code" // rel) in
    Log.verbose "%a" File.pp file;
    Fs.write_noerr path (Fmt.dly "%a" File.pp file)

  let command (dt : Dependency_tree.t) (prog : 'm Prog.t) : unit =
    let pp_prog = Prog.pp ~filename:(Dependency_tree.multi_file dt) in
    if not Log.Config.(!log_verbose) then Log.stdout "%a@." pp_prog prog
end

let js_parser (path : Fpath.t) () : (Loc.t, Loc.t) Flow_ast.Program.t =
  Javascript_parser.parse path

let dep_tree (output : Fpath.t option) (path : Fpath.t) () : Dependency_tree.t =
  let dt = Dependency_tree.generate path in
  Log.info "Dependency tree of \"%a\" generated successfully." Fpath.pp dt.abs;
  Output.dep_tree output dt;
  dt

let normalized_files (output : Fpath.t option) (dt : Dependency_tree.t) :
    (Fpath.t * 'm File.t) Exec.status list =
  Fun.flip Dependency_tree.bottom_up_visit dt @@ fun (abs_path, rel_path) ->
  let* js_file = Exec.graphjs (js_parser abs_path) in
  let file = Normalizer.normalize_file js_file in
  Log.info "File \"%a\" normalized successfully." Fpath.pp abs_path;
  Output.source_file output rel_path abs_path;
  Output.normalized_file output rel_path file;
  Ok (abs_path, file)

let normalized_prog (output : Fpath.t option) (dt : Dependency_tree.t) :
    'm Prog.t Exec.status =
  let* files = Result.extract (normalized_files output dt) in
  Ok (Prog.create files)

let run (input : Fpath.t) (output : Fpath.t option) :
    (Dependency_tree.t * 'm Prog.t) Exec.status =
  let* dt = Exec.graphjs (dep_tree output input) in
  let* prog = normalized_prog output dt in
  Ok (dt, prog)

let main (opts : Options.t) () : unit Exec.status =
  let* () = Fs.prepare opts.output in
  let* (dt, prog) = run opts.input opts.output in
  Output.command dt prog;
  Ok ()
