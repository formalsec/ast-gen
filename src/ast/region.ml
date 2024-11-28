open Graphjs_base

type pos =
  { line : int
  ; col : int
  }

type t =
  { file : string
  ; lpos : pos
  ; rpos : pos
  }

let pos_none : unit -> pos =
  let none = { line = -1; col = -1 } in
  fun () -> none

let none : unit -> t =
  let none = { file = ""; lpos = pos_none (); rpos = pos_none () } in
  fun () -> none

let create_pos (line : int) (col : int) : pos = { line; col } [@@inline]

let create (file : string) (lpos : pos) (rpos : pos) : t = { file; lpos; rpos }
[@@inline]

let pp_pos (ppf : Fmt.t) (pos : pos) : unit =
  let pp_pos' ppf v = Fmt.(if v == -1 then pp_str ppf "x" else pp_int ppf v) in
  Fmt.fmt ppf "%a.%a" pp_pos' pos.line pp_pos' pos.col

let pp (ppf : Fmt.t) (at : t) : unit =
  Fmt.fmt ppf "%S:%a-%a" at.file pp_pos at.lpos pp_pos at.rpos

let str : t -> string = Fmt.str "%a" pp
