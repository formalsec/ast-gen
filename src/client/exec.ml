open Graphjs_base

type error =
  [ `DepTree of Fmt.t -> unit
  | `ParseJS of Fmt.t -> unit
  | `BuildMDG of Fmt.t -> unit
  | `ExportMDG of Fmt.t -> unit
  | `Generic of Fmt.t -> unit
  | `Failure of Fmt.t -> unit
  | `Timeout
  ]

type 'a status = ('a, error) Result.t

let pp_exn (ppf : Fmt.t) : error -> unit = function
  | `DepTree fmt -> Fmt.fmt ppf "%t" fmt
  | `ParseJS fmt -> Fmt.fmt ppf "%t" fmt
  | `BuildMDG fmt -> Fmt.fmt ppf "%t" fmt
  | `ExportMDG fmt -> Fmt.fmt ppf "%t" fmt
  | `Generic err -> Fmt.fmt ppf "%t" err
  | `Failure err -> Fmt.fmt ppf "%t" err
  | `Timeout -> Fmt.fmt ppf "graphjs timeout"

let log_exn : error -> unit = function
  | `DepTree fmt -> Log.stderr "%t" fmt
  | `ParseJS fmt -> Log.stderr "%t" fmt
  | `BuildMDG fmt -> Log.stderr "%t" fmt
  | `ExportMDG fmt -> Log.stderr "%t" fmt
  | `Generic err -> Log.error "%t" err
  | `Failure err -> Log.error "%t" err
  | `Timeout -> Log.error "graphjs timeout"

let exn (err : error) : 'a status =
  log_exn err;
  Error err

let error (fmt : ('b, Fmt.t, unit, 'a status) format4) : 'b =
  Fmt.kdly (fun acc -> exn (`Generic acc)) fmt

let fail (fmt : ('b, Fmt.t, unit, 'a status) format4) : 'b =
  Fmt.kdly (fun acc -> exn (`Failure acc)) fmt

let timeout () : 'b = exn `Timeout

let bos : ('a, [< `Msg of string ]) result -> 'a status = function
  | Ok _ as res -> res
  | Error (`Msg err) -> exn (`Generic (Fmt.dly "%s" err))

let graphjs (exec_f : unit -> 'a) : 'a status =
  try Ok (exec_f ()) with
  | Graphjs_parser.Dependency_tree.Exn fmt -> exn (`DepTree fmt)
  | Graphjs_parser.Flow_parser.Exn fmt -> exn (`ParseJS fmt)
  | Graphjs_mdg.State.Exn fmt -> exn (`BuildMDG fmt)
  | Graphjs_mdg.Svg_exporter.Exn fmt -> exn (`ParseJS fmt)
  | Graphjs_mdg.Svg_exporter.Timeout -> exn `Timeout
  | err ->
    let msg = Printexc.to_string err in
    let trace = Printexc.get_backtrace () in
    exn (`Failure (Fmt.dly "%s@\n%s" msg trace))
