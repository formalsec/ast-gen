open Graphjs_base

module Config = struct
  include Config

  let invalid = constant (-1)
end

type pos =
  { line : int
  ; col : int
  }

type t =
  { file : string
  ; lpos : pos
  ; rpos : pos
  }

let default_pos =
  let dflt = { line = Config.(!invalid); col = Config.(!invalid) } in
  fun () -> dflt

let default =
  let dflt = { file = ""; lpos = default_pos (); rpos = default_pos () } in
  fun () -> dflt

let create_pos (line : int) (col : int) : pos = { line; col }
let create (file : string) (lpos : pos) (rpos : pos) : t = { file; lpos; rpos }
let is_invalid (v : int) : bool = v == Config.(!invalid)

let pp_pos (ppf : Fmt.t) (pos : pos) : unit =
  let pp_pos' ppf v =
    if is_invalid v then Fmt.pp_str ppf "x" else Fmt.pp_int ppf v in
  Fmt.fmt ppf "%a.%a" pp_pos' pos.line pp_pos' pos.col

let pp (ppf : Fmt.t) (at : t) : unit =
  Fmt.fmt ppf "%S:%a-%a" at.file pp_pos at.lpos pp_pos at.rpos

let str (at : t) : string = Fmt.str "%a" pp at
