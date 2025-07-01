type error =
  [ `Generic of Fmt.t -> unit
  | `Failure of Fmt.t -> unit
  | `Timeout
  | `DepTree of Fmt.t -> unit
  | `ParseJS of Fmt.t -> unit
  | `Jsmodel of Fmt.t -> unit
  | `ExportMDG of Fmt.t -> unit
  ]

type 'a result = ('a, error) Result.t

let pp_err (ppf : Fmt.t) (err : error) : unit =
  match err with
  | `Generic err -> Log.fmt_error ppf "%t" err
  | `Failure err -> Log.fmt_error ppf "%t" err
  | `Timeout -> Log.fmt_error ppf "graphjs timeout"
  | `DepTree fmt -> Fmt.fmt ppf "%t" fmt
  | `ParseJS fmt -> Fmt.fmt ppf "%t" fmt
  | `Jsmodel fmt -> Fmt.fmt ppf "%t" fmt
  | `ExportMDG fmt -> Fmt.fmt ppf "%t" fmt

let log_err (err : error) : unit = Log.stderr "%a" pp_err err

let exn (err : error) : 'a result =
  log_err err;
  Error err

let error (fmt : ('b, Fmt.t, unit, 'a result) format4) : 'b =
  Fmt.kdly (fun acc -> exn (`Generic acc)) fmt

let fail (fmt : ('b, Fmt.t, unit, 'a result) format4) : 'b =
  Fmt.kdly (fun acc -> exn (`Failure acc)) fmt

let bos (res : ('a, [< `Msg of string ]) Result.t) : 'a result =
  match res with
  | Ok _ as res' -> res'
  | Error (`Msg err) -> exn (`Generic (Fmt.dly "%s" err))

let graphjs (exec_f : unit -> 'a) : 'a result =
  try Ok (exec_f ()) with
  | Graphjs_base.Time.Timeout -> exn `Timeout
  | Graphjs_parser.Dependency_tree.Exn fmt -> exn (`DepTree fmt)
  | Graphjs_parser.Flow_parser.Exn fmt -> exn (`ParseJS fmt)
  | Graphjs_mdg.Jsmodel.Exn fmt -> exn (`Jsmodel fmt)
  | Graphjs_mdg.Export_view.Exn fmt -> exn (`ExportMDG fmt)
  | Graphjs_mdg.Svg_exporter.Exn fmt -> exn (`ExportMDG fmt)
  | err ->
    let msg = Printexc.to_string err in
    let trace = Printexc.get_backtrace () in
    exn (`Failure (Fmt.dly "%s@\n%s" msg trace))
