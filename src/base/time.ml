type t = float

type ftime =
  { hours : int
  ; mins : int
  ; secs : int
  ; ms : int
  }

let start () : t = Unix.gettimeofday ()
let finish (time : t) : t = start () -. time

let compute (f : unit -> 'a) : t * 'a =
  let time = start () in
  let res = f () in
  let time' = finish time in
  (time', res)

let format (time : t) : ftime =
  let total_ms = int_of_float (time *. 1000.) in
  let ms = total_ms mod 1000 in
  let total_sec = total_ms / 1000 in
  let secs = total_sec mod 60 in
  let total_min = total_sec / 60 in
  let mins = total_min mod 60 in
  let hours = total_min / 60 in
  { hours; mins; secs; ms }
