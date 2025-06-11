module Sink = struct
  type t =
    { name : string
    ; kind : Jsmodel.Sink.kind
    ; args : int list
    }

  let create (jsmodel : Jsmodel.Sink.t) : t =
    { name = jsmodel.name; kind = jsmodel.kind; args = jsmodel.args }

  let pp (ppf : Fmt.t) (sink : t) : unit =
    let pp_args ppf args = Fmt.(pp_lst !>", " pp_int) ppf args in
    Fmt.fmt ppf "{ sink: %S, kind: \"%a\", args: [%a] }" sink.name
      Jsmodel.pp_kind sink.kind pp_args sink.args

  let str (sink : t) : string = Fmt.str "%a" pp sink
  let name (sink : t) : string = sink.name
end

module Source = struct
  type t =
    { name : string
    ; kind : Jsmodel.Source.kind
    }

  let create (jsmodel : Jsmodel.Source.t) : t =
    { name = jsmodel.name; kind = jsmodel.kind }

  let pp (ppf : Fmt.t) (source : t) : unit =
    Fmt.fmt ppf "{ source: %S, kind: \"%a\" }" source.name Jsmodel.pp_kind
      source.kind

  let str (source : t) : string = Fmt.str "%a" pp source
  let name (source : t) : string = source.name
end
