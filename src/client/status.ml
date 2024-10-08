open Graphjs_base
include Result

type t' = [ `Generic of string ]
type t = (unit, t') Result.t

let log_error : t' -> unit = function `Generic msg -> Log.error "%s" msg

let error (err : t') : t =
  log_error err;
  Error err

let bos : ('a, [< `Msg of string ]) result -> t = function
  | Ok _ as res -> res
  | Error (`Msg err) -> error (`Generic err)
