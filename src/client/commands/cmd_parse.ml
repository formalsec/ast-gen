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

let dep_tree (path : string) () : Dependency_tree.t =
  let dep_tree = Dependency_tree.generate path in
  Log.info "Dependency tree of %S generated successfully." dep_tree.path;
  Log.verbose "%a" Dependency_tree.pp dep_tree;
  dep_tree

let build_files (dep_tree : Dependency_tree.t) :
    (string * 'm File.t) Exec.status list =
  Fun.flip Dependency_tree.bottom_up_visit dep_tree @@ fun path ->
  let* js_file = Exec.graphjs (fun () -> Javascript_parser.parse path) in
  let file = Normalizer.normalize_file js_file in
  Log.info "File %S normalized successfully." path;
  Log.verbose "%a" File.pp file;
  Ok (path, file)

let prog_ast (dep_tree : Dependency_tree.t) : 'm Prog.t Exec.status =
  let build_res = build_files dep_tree in
  let* files = Result.extract build_res in
  Ok (Prog.create files)

let run (input : Fpath.t) : (Dependency_tree.t * 'm Prog.t) Exec.status =
  let input' = Fpath.to_string input in
  let* dep_tree = Exec.graphjs (dep_tree input') in
  let* prog = prog_ast dep_tree in
  Ok (dep_tree, prog)

let main (opts : Options.t) () : unit Exec.status =
  let* (_, prog) = run opts.input in
  let pp_prog = Prog.pp ~filename:(Mode.is_multi_file Shared_config.(!mode)) in
  if not Log.Config.(!log_verbose) then Log.stdout "%a@." pp_prog prog;
  Ok ()
