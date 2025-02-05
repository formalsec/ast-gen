include Stdlib.String

(* FIXME: currently unhappy with this function *)
let truncate (limit : int) (text : string) : string * bool =
  let truncate_line line text =
    try if length line > limit then (sub line 0 limit, true) else (line, text)
    with Invalid_argument _ -> ("", true) in
  match split_on_char '\n' text with
  | [] -> ("", false)
  | line :: [] -> truncate_line line false
  | line :: _ -> truncate_line line true
