open Graphjs_base

type error =
  [ `DepTree of Fmt.t -> unit
  | `ParseJS of Fmt.t -> unit
  | `Generic of string
  ]

type 'a status = ('a, error) Result.t

let log_exn : error -> unit = function
  | `DepTree fmt -> Log.stderr "%t@." fmt
  | `ParseJS fmt -> Log.stderr "%t@." fmt
  | `Generic err -> Log.error "%s@." err

let exn (err : error) : 'a status =
  log_exn err;
  Error err

let bos : ('a, [< `Msg of string ]) result -> 'a status = function
  | Ok _ as res -> res
  | Error (`Msg err) -> exn (`Generic err)

let graphjs (exec_f : unit -> 'a) : 'a status =
  try Ok (exec_f ()) with
  | Graphjs_parser.Dependency_tree.Exn fmt -> exn (`DepTree fmt)
  | Graphjs_parser.Javascript_parser.Exn fmt -> exn (`ParseJS fmt)
