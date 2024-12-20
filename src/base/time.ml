type t = float
type formatted = int * int * int * int

let start () : t = Unix.gettimeofday ()
let finish (time : t) : t = start () -. time

let time (f : unit -> 'a) : t * 'a =
  let time = start () in
  let res = f () in
  let time' = finish time in
  (time', res)

let format (time : t) : formatted =
  let total_secs = int_of_float (floor time) in
  let hours = total_secs / 3600 in
  let minutes = (total_secs - (hours * 3600)) / 60 in
  let seconds = total_secs - ((hours * 3600) + (minutes * 60)) in
  let millis = int_of_float (Float.round ((time -. floor time) *. 1000.0)) in
  (hours, minutes, seconds, millis)
