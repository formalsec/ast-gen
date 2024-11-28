open Graphjs_base
open Graphjs_shared
open Graphjs_ast
open Graphjs_parser

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

let build_prog (dep_tree : Dependency_tree.t) (prog_ast : 'm Prog.t) :
    'm Prog.t Exec.status list =
  let open Result in
  let parse_js path () = Javascript_parser.parse path in
  Fun.flip Dependency_tree.bottom_up_visit dep_tree @@ fun path ->
  let* js_file = Exec.graphjs (parse_js path) in
  let file = Normalizer.normalize_file js_file in
  Log.info "File %S normalized successfully." path;
  Log.verbose "%a" File.pp file;
  Prog.add prog_ast path file;
  Ok prog_ast

let prog_ast (dep_tree : Dependency_tree.t) : 'm Prog.t Exec.status =
  let prog_ast = Prog.create () in
  let build_res = build_prog dep_tree prog_ast in
  match List.find_opt Result.is_error build_res with
  | None -> Ok prog_ast
  | Some err -> err

let run (opts : Options.t) () : unit Exec.status =
  let open Result in
  let input = Fpath.to_string opts.input in
  let* dep_tree = Exec.graphjs (dep_tree input) in
  let* prog_ast = prog_ast dep_tree in
  let pp_prog = Prog.pp ~filename:(Mode.is_multi_file Shared_config.(!mode)) in
  if not Log.Config.(!log_verbose) then Log.stdout "%a@." pp_prog prog_ast;
  Ok ()
