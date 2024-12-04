open Graphjs_base
open Graphjs_shared
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

let dep_tree (output : Fpath.t option) (path : Fpath.t) () : Dependency_tree.t =
  let dt = Dependency_tree.generate path in
  let dt_path = Fpath.v "dep_tree.txt" in
  Log.info "Dependency tree of \"%a\" generated successfully." Fpath.pp dt.abs;
  Log.verbose "%a" Dependency_tree.pp dt;
  Fs.write_noerr output dt_path (Fmt.dly "%a" Dependency_tree.pp dt);
  dt

let parse_js (path : Fpath.t) () : (Loc.t, Loc.t) Flow_ast.Program.t =
  Javascript_parser.parse path

let build_files (output : Fpath.t option) (dt : Dependency_tree.t) :
    (Fpath.t * 'm File.t) Exec.status list =
  Fun.flip Dependency_tree.bottom_up_visit dt @@ fun (abs_path, rel_path) ->
  let* js_file = Exec.graphjs (parse_js abs_path) in
  let file = Normalizer.normalize_file js_file in
  let file_path = Fpath.(v "code" // rel_path) in
  Log.info "File \"%a\" normalized successfully." Fpath.pp abs_path;
  Log.verbose "%a" File.pp file;
  Fs.write_noerr output file_path (Fmt.dly "%a" File.pp file);
  Ok (abs_path, file)

let build_prog (output : Fpath.t option) (dt : Dependency_tree.t) :
    'm Prog.t Exec.status =
  let* files = Result.extract (build_files output dt) in
  let prog = Prog.create files in
  let prog_path = Fpath.v "code.js" in
  let prog_fmt = Fmt.dly "%a" (Prog.pp ~filename:true) prog in
  Fs.write_noerr ~main:true output prog_path prog_fmt;
  Ok prog

let run (input : Fpath.t) (output : Fpath.t option) :
    (Dependency_tree.t * 'm Prog.t) Exec.status =
  let* dt = Exec.graphjs (dep_tree output input) in
  let* prog = build_prog output dt in
  Ok (dt, prog)

let main (opts : Options.t) () : unit Exec.status =
  let* () = Fs.prepare opts.output in
  let* (_, prog) = run opts.input opts.output in
  let pp_prog = Prog.pp ~filename:(Mode.is_multi_file Shared_config.(!mode)) in
  if not Log.Config.(!log_verbose) then Log.stdout "%a@." pp_prog prog;
  Ok ()
