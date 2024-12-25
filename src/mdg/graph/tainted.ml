open Graphjs_share

open struct
  type package_source = Taint_config.package_source
  type package_sink = Taint_config.package_sink
  type function_sink = Taint_config.function_sink
  type new_sink = Taint_config.new_sink
end

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

let ( ! ) tainted : t = (tainted :> t) [@@inline]

let name : t -> string = function
  | `PackageSource package_source -> package_source.source
  | `PackageSink package_sink -> package_sink.sink
  | `FunctionSink function_sink -> function_sink.sink
  | `NewSink new_sink -> new_sink.sink

let kind : sink -> Sink_kind.t = function
  | `PackageSink package_sink -> package_sink.kind
  | `FunctionSink function_sink -> function_sink.kind
  | `NewSink new_sink -> new_sink.kind
