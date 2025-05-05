open Graphjs_base
open Graphjs_share

type source =
  { mrel : string option
  ; name : string
  ; args : int list
  }

type sink =
  { mrel : string option
  ; name : string
  ; kind : Sink_kind.t
  ; args : int list
  }

type t =
  | Source of source
  | Sink of sink

let package_source (name : string) (source : Taint_config.package_source) :
    source =
  let package = Taint_config.find_package name source.packages in
  { mrel = Some name; name = source.source; args = package.args }

let package_sink (name : string) (sink : Taint_config.package_sink) : sink =
  let package = Taint_config.find_package name sink.packages in
  { mrel = Some name; name = sink.sink; kind = sink.kind; args = package.args }

let function_sink (sink : Taint_config.function_sink) : sink =
  { mrel = None; name = sink.sink; kind = sink.kind; args = sink.args }

let new_sink (sink : Taint_config.new_sink) : sink =
  { mrel = None; name = sink.sink; kind = sink.kind; args = sink.args }

let pp_args (ppf : Fmt.t) (args : int list) : unit =
  Fmt.(pp_lst !>", " pp_int) ppf args

let pp_source (ppf : Fmt.t) (source : source) : unit =
  Fmt.fmt ppf "{ source: %S, args: [%a] }" source.name pp_args source.args

let pp_sink (ppf : Fmt.t) (sink : sink) : unit =
  Fmt.fmt ppf "{ sink: %S, kind: \"%a\" args: [%a] }" sink.name Sink_kind.pp
    sink.kind pp_args sink.args

let pp (ppf : Fmt.t) (tainted : t) : unit =
  match tainted with
  | Source source -> pp_source ppf source
  | Sink sink -> pp_sink ppf sink

let str (tainted : t) : string = Fmt.str "%a" pp tainted
