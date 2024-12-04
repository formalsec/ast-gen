open Graphjs_base

type error =
  [ `DepTree of Fmt.t -> unit
  | `ParseJS of Fmt.t -> unit
  | `ExportMDG of Fmt.t -> unit
  | `Generic of string
  ]

type 'a status = ('a, error) Result.t

let pp_exn (ppf : Fmt.t) : error -> unit = function
  | `DepTree fmt -> Fmt.fmt ppf "%t" fmt
  | `ParseJS fmt -> Fmt.fmt ppf "%t" fmt
  | `ExportMDG fmt -> Fmt.fmt ppf "%t" fmt
  | `Generic err -> Fmt.fmt ppf "%s" err

let log_exn : error -> unit = function
  | `DepTree fmt -> Log.stderr "%t" fmt
  | `ParseJS fmt -> Log.stderr "%t" fmt
  | `ExportMDG fmt -> Log.stderr "%t" fmt
  | `Generic err -> Log.error "%s" err

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
  | Graphjs_mdg.Svg_exporter.Exn fmt -> exn (`ParseJS fmt)
