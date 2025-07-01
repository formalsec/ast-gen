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

let pp (ppf : Fmt.t) (time : t) : unit =
  let ftime = format time in
  let log_hours = ftime.hours > 0 in
  let log_mins = log_hours || ftime.mins > 0 in
  if log_hours then Fmt.fmt ppf "%dh " ftime.hours;
  if log_mins then Fmt.fmt ppf "%dm " ftime.mins;
  Fmt.fmt ppf "%d.%03ds" ftime.secs ftime.ms

let str (time : t) : string = Fmt.str "%a" pp time

module Config = struct
  include Config

  let timeout = static Float.max_float
end

exception Timeout

let timeout () : 'a = Stdlib.raise Timeout

let timeout_check (time : t) : unit =
  if finish time > Config.(!timeout) then timeout ()
