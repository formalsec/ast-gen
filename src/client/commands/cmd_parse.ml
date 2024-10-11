open Graphjs_base
open Graphjs_config
open Graphjs_parser

module Options = struct
  type t =
    { input : Fpath.t
    ; output : Fpath.t option
    ; mode : Mode.t
    }

  let set (input : Fpath.t) (output : Fpath.t option)
      (mode : Enums.AnalysisMode.t) : t =
    { input; output; mode = Enums.AnalysisMode.conv mode }
  [@@inline]
end

let dep_tree (input : Fpath.t) (mode : Mode.t) : Dependency_tree.t Exec.status =
  let input' = Fpath.to_string input in
  let generate_dep_tree_f () = Dependency_tree.generate input' mode in
  Exec.graphjs generate_dep_tree_f

let parse_js (input : Fpath.t) : (Loc.t, Loc.t) Flow_ast.Program.t Exec.status =
  let input' = Fpath.to_string input in
  let parse_f () = Parser.parse input' in
  Exec.graphjs parse_f

let run () (opts : Options.t) : unit Exec.status =
  let open Result in
  let* _dep_tree = dep_tree opts.input opts.mode in
  let* _flow_ast = parse_js opts.input in
  Ok ()
