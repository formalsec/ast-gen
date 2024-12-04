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

let default_pos : unit -> pos =
  let dflt = { line = -1; col = -1 } in
  fun () -> dflt

let default : unit -> t =
  let dflt = { file = ""; lpos = default_pos (); rpos = default_pos () } in
  fun () -> dflt

let create_pos (line : int) (col : int) : pos = { line; col }
let create (file : string) (lpos : pos) (rpos : pos) : t = { file; lpos; rpos }

let pp_pos (ppf : Fmt.t) (pos : pos) : unit =
  let pp_pos' ppf v = Fmt.(if v == -1 then pp_str ppf "x" else pp_int ppf v) in
  Fmt.fmt ppf "%a.%a" pp_pos' pos.line pp_pos' pos.col

let pp (ppf : Fmt.t) (at : t) : unit =
  Fmt.fmt ppf "%S:%a-%a" at.file pp_pos at.lpos pp_pos at.rpos

let str (at : t) : string = Fmt.str "%a" pp at [@@inline]
