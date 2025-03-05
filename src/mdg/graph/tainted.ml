open Graphjs_base
open Graphjs_share

type package = Taint_config.package
type package_source = Taint_config.package_source
type package_sink = Taint_config.package_sink
type function_sink = Taint_config.function_sink
type new_sink = Taint_config.new_sink
type source = [ `PackageSource of package_source ]

type sink =
  [ `PackageSink of package_sink
  | `FunctionSink of function_sink
  | `NewSink of new_sink
  ]

type t =
  [ source
  | sink
  ]

let ( ! ) tainted : t = (tainted :> t)

let name (tainted : t) : string =
  match tainted with
  | `PackageSource package_source -> package_source.source
  | `PackageSink package_sink -> package_sink.sink
  | `FunctionSink function_sink -> function_sink.sink
  | `NewSink new_sink -> new_sink.sink

let packages (tainted : t) : package list =
  match tainted with
  | `PackageSource package_source -> package_source.packages
  | `PackageSink package_sink -> package_sink.packages
  | _ -> Log.fail "unexpected tainted element"

let kind (sink : sink) : Sink_kind.t =
  match sink with
  | `PackageSink package_sink -> package_sink.kind
  | `FunctionSink function_sink -> function_sink.kind
  | `NewSink new_sink -> new_sink.kind

let args (sink : sink) : int list =
  match sink with
  | `PackageSink _ -> Log.fail "unexpected sink kind"
  | `FunctionSink function_sink -> function_sink.args
  | `NewSink new_sink -> new_sink.args
