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

let package_source (name : string) (p_source : Taint_config.package_source) :
    source =
  let pkg = Taint_config.find_package name p_source.pkgs in
  { mrel = Some name; name = p_source.name; args = pkg.args }

let package_sink (name : string) (p_sink : Taint_config.package_sink) : sink =
  let pkg = Taint_config.find_package name p_sink.pkgs in
  { mrel = Some name; name = p_sink.name; kind = p_sink.kind; args = pkg.args }

let function_sink (f_sink : Taint_config.function_sink) : sink =
  { mrel = None; name = f_sink.name; kind = f_sink.kind; args = f_sink.args }

let new_sink (n_sink : Taint_config.new_sink) : sink =
  { mrel = None; name = n_sink.name; kind = n_sink.kind; args = n_sink.args }

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
