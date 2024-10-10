open Graphjs_base

type error =
  [ `ParseJS
  | `Generic of string
  ]

type 'a status = ('a, error) Result.t

let log_error : error -> unit = function
  | `ParseJS -> ()
  | `Generic err -> Log.error "%s" err

let error (err : error) : 'a status =
  log_error err;
  Error err

let bos : ('a, [< `Msg of string ]) result -> 'a status = function
  | Ok _ as res -> res
  | Error (`Msg err) -> error (`Generic err)

let graphjs (exec_f : unit -> 'a) : 'a status =
  try Ok (exec_f ()) with Graphjs_ast.Parser.Error -> error `ParseJS
