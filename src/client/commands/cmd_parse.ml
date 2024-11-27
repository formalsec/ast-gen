open Graphjs_base
open Graphjs_shared
open Graphjs_ast
open Graphjs_parser

module Options = struct
  type t =
    { input : Fpath.t
    ; output : Fpath.t option
    }

  let set_internal (mode' : Enums.AnalysisMode.t)
      (test262_conform_hoisted' : bool) : unit =
    Parser_config.(mode $= Enums.AnalysisMode.conv mode');
    Parser_config.(test262_conform_hoisted $= test262_conform_hoisted')

  let set (mode : Enums.AnalysisMode.t) (input : Fpath.t)
      (output : Fpath.t option) (test262_conform_hoisted : bool) : t =
    set_internal mode test262_conform_hoisted;
    { input; output }
  [@@inline]
end

let log_dependency_tree (dep_tree : Dependency_tree.t) : unit =
  if Log.Config.(!log_infos) then Log.stdout "%a@." Dependency_tree.pp dep_tree

let log_normalized_file (file : 'm File.t) : unit =
  if Log.Config.(!log_infos) then Log.stdout "%a@." File.pp file

let log_normalized_prog (prog : 'm Prog.t) : unit =
  let filename = Mode.is_multi_file Parser_config.(!mode) in
  if not Log.Config.(!log_infos) then Log.stdout "%a@." (Prog.pp ~filename) prog

let dep_tree (path : string) () : Dependency_tree.t =
  let dep_tree = Dependency_tree.generate path in
  Log.info "Dependency tree of %S generated successfully." dep_tree.path;
  log_dependency_tree dep_tree;
  dep_tree

let build_prog (dep_tree : Dependency_tree.t) (prog_ast : 'm Prog.t) :
    'm Prog.t Exec.status list =
  let open Result in
  let parse_js path () = Javascript_parser.parse path in
  Fun.flip Dependency_tree.bottom_up_visit dep_tree @@ fun path ->
  let* js_file = Exec.graphjs (parse_js path) in
  let file = Normalizer.normalize_file js_file in
  Log.info "File %S normalized successfully." path;
  log_normalized_file file;
  Prog.add prog_ast path file;
  Ok prog_ast

let prog_ast (dep_tree : Dependency_tree.t) : 'm Prog.t Exec.status =
  let prog_ast = Prog.create () in
  let build_res = build_prog dep_tree prog_ast in
  match List.find_opt Result.is_error build_res with
  | None -> Ok prog_ast
  | Some err -> err

let run () (opts : Options.t) : unit Exec.status =
  let open Result in
  let input = Fpath.to_string opts.input in
  let* dep_tree = Exec.graphjs (dep_tree input) in
  let* prog_ast = prog_ast dep_tree in
  log_normalized_prog prog_ast;
  Ok ()
