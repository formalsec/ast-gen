include Stdlib.String

let split (limit : int option) (text : string) : string * string =
  let limit' = Option.value ~default:Int.max_int limit in
  let truncate_line line rest =
    let len = length line in
    if len > limit' then
      let line' = sub line 0 limit' in
      let rest' = sub line limit' (len - limit') in
      (line', rest' ^ rest)
    else (line, rest) in
  match split_on_char '\n' text with
  | [] -> ("", "")
  | line :: [] -> truncate_line line ""
  | line :: text' -> truncate_line line (concat "\n" text')

let truncate (limit : int option) (text : string) : string =
  fst (split limit text)
