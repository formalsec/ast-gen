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

let dep_tree (output : Fpath.t option) (path : string) () : Dependency_tree.t =
  let dep_tree = Dependency_tree.generate path in
  let dep_tree_path = Fpath.v "dep_tree.txt" in
  Log.info "Dependency tree of %a generated successfully."
    Dependency_tree.pp_path dep_tree.absolute;
  Log.verbose "%a" Dependency_tree.pp dep_tree;
  Fs.output output dep_tree_path (Fmt.dly "%a" Dependency_tree.pp dep_tree);
  dep_tree

let build_files (output : Fpath.t option) (dep_tree : Dependency_tree.t) :
    (string * 'm File.t) Exec.status list =
  Fun.flip Dependency_tree.bottom_up_visit dep_tree @@ fun (abs, rel) ->
  let path = Fpath.to_string abs in
  let file_path = Fpath.(v "code" // rel) in
  let* js_file = Exec.graphjs (fun () -> Javascript_parser.parse path) in
  let file = Normalizer.normalize_file js_file in
  Log.info "File %S normalized successfully." path;
  Log.verbose "%a" File.pp file;
  Fs.output output file_path (Fmt.dly "%a" File.pp file);
  Ok (path, file)

let prog_ast (output : Fpath.t option) (dep_tree : Dependency_tree.t) :
    'm Prog.t Exec.status =
  let build_res = build_files output dep_tree in
  let* files = Result.extract build_res in
  Ok (Prog.create files)

let run (input : Fpath.t) (output : Fpath.t option) :
    (Dependency_tree.t * 'm Prog.t) Exec.status =
  let input' = Fpath.to_string input in
  let* dep_tree = Exec.graphjs (dep_tree output input') in
  let* prog = prog_ast output dep_tree in
  let prog_path = Fpath.v "code.js" in
  Fs.output ~main:true output prog_path
    (Fmt.dly "%a" (Prog.pp ~filename:true) prog);
  Ok (dep_tree, prog)

let main (opts : Options.t) () : unit Exec.status =
  let* () = Fs.prepare opts.output in
  let* (_, prog) = run opts.input opts.output in
  let pp_prog = Prog.pp ~filename:(Mode.is_multi_file Shared_config.(!mode)) in
  if not Log.Config.(!log_verbose) then Log.stdout "%a@." pp_prog prog;
  Ok ()
