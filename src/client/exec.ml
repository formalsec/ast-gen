open Graphjs_base

type error =
  [ `Generic of Fmt.t -> unit
  | `DepTree of Fmt.t -> unit
  | `ParseJS of Fmt.t -> unit
  | `BuildMDG of Fmt.t -> unit
  | `ExportMDG of Fmt.t -> unit
  ]

type 'a status = ('a, error) Result.t

let pp_exn (ppf : Fmt.t) : error -> unit = function
  | `Generic err -> Fmt.fmt ppf "%t" err
  | `DepTree fmt -> Fmt.fmt ppf "%t" fmt
  | `ParseJS fmt -> Fmt.fmt ppf "%t" fmt
  | `BuildMDG fmt -> Fmt.fmt ppf "%t" fmt
  | `ExportMDG fmt -> Fmt.fmt ppf "%t" fmt

let log_exn : error -> unit = function
  | `Generic err -> Log.error "%t" err
  | `DepTree fmt -> Log.stderr "%t" fmt
  | `ParseJS fmt -> Log.stderr "%t" fmt
  | `BuildMDG fmt -> Log.stderr "%t" fmt
  | `ExportMDG fmt -> Log.stderr "%t" fmt

let exn (err : error) : 'a status =
  log_exn err;
  Error err

let generic_exn (fmt : ('b, Fmt.t, unit, 'a status) format4) : 'b =
  Fmt.kdly (fun acc -> exn (`Generic acc)) fmt

let bos : ('a, [< `Msg of string ]) result -> 'a status = function
  | Ok _ as res -> res
  | Error (`Msg err) -> exn (`Generic (Fmt.dly "%s" err))

let graphjs (exec_f : unit -> 'a) : 'a status =
  try Ok (exec_f ()) with
  | Graphjs_parser.Dependency_tree.Exn fmt -> exn (`DepTree fmt)
  | Graphjs_parser.Javascript_parser.Exn fmt -> exn (`ParseJS fmt)
  | Graphjs_mdg.State.Exn fmt -> exn (`BuildMDG fmt)
  | Graphjs_mdg.Svg_exporter.Exn fmt -> exn (`ParseJS fmt)
