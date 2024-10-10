open Graphjs_base
open Graphjs_ast

module Options = struct
  type t =
    { input : Fpath.t
    ; output : Fpath.t option
    }

  let set (input : Fpath.t) (output : Fpath.t option) : t = { input; output }
  [@@inline]
end

let parse_js (input : Fpath.t) : (Loc.t, Loc.t) Flow_ast.Program.t Exec.status =
  let input' = Fpath.to_string input in
  let parse_f () = Parser.parse input' in
  Exec.graphjs parse_f

let run () (opts : Options.t) : unit Exec.status =
  let open Result in
  let* _flow_ast = parse_js opts.input in
  Ok ()
