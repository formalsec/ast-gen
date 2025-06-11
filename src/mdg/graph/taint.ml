module Sink = struct
  type t =
    { ref : Reference.t
    ; kind : Jsmodel.Sink.kind
    ; args : int list
    }

  let create (ref_f : Reference.maker) (jsmodel : Jsmodel.Sink.t) : t =
    { ref = ref_f jsmodel.name; kind = jsmodel.kind; args = jsmodel.args }

  let pp (ppf : Fmt.t) (sink : t) : unit =
    let pp_args ppf args = Fmt.(pp_lst !>", " pp_int) ppf args in
    Fmt.fmt ppf "{ sink: \"%a\", kind: \"%a\", args: [%a] }" Reference.pp
      sink.ref Jsmodel.pp_kind sink.kind pp_args sink.args

  let str (sink : t) : string = Fmt.str "%a" pp sink
  let name (sink : t) : string = Reference.name sink.ref
end

module Source = struct
  type t =
    { ref : Reference.t
    ; kind : Jsmodel.Source.kind
    }

  let create (ref_f : Reference.maker) (jsmodel : Jsmodel.Source.t) : t =
    { ref = ref_f jsmodel.name; kind = jsmodel.kind }

  let pp (ppf : Fmt.t) (source : t) : unit =
    Fmt.fmt ppf "{ source: \"%a\", kind: \"%a\" }" Reference.pp source.ref
      Jsmodel.pp_kind source.kind

  let str (source : t) : string = Fmt.str "%a" pp source
  let name (source : t) : string = Reference.name source.ref
end
