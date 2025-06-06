module Id = struct
  type t =
    | Language of string
    | PackageSelf of string
    | PackageProp of string * string

  type maker = string -> t

  let language (name : string) : t = Language name
  let package_self (package : string) : t = PackageSelf package

  let package_prop (package : string) (prop : string) : t =
    PackageProp (package, prop)

  let pp (ppf : Fmt.t) (id : t) : unit =
    match id with
    | Language name -> Fmt.pp_str ppf name
    | PackageSelf package -> Fmt.pp_str ppf package
    | PackageProp (package, prop) -> Fmt.fmt ppf "%s.%s" package prop

  let str (id : t) : string = Fmt.str "%a" pp id

  let name (id : t) : string =
    match id with
    | Language name -> name
    | PackageSelf package -> package
    | PackageProp (_, prop) -> prop
end

module Sink = struct
  type t =
    { id : Id.t
    ; kind : Jsmodel.Sink.kind
    ; args : int list
    }

  let create (id_f : Id.maker) (jsmodel : Jsmodel.Sink.t) : t =
    { id = id_f jsmodel.name; kind = jsmodel.kind; args = jsmodel.args }

  let pp (ppf : Fmt.t) (sink : t) : unit =
    let pp_args ppf args = Fmt.(pp_lst !>", " pp_int) ppf args in
    Fmt.fmt ppf "{ sink: \"%a\", kind: \"%a\", args: [%a] }" Id.pp sink.id
      Jsmodel.pp_kind sink.kind pp_args sink.args

  let str (sink : t) : string = Fmt.str "%a" pp sink
  let name (sink : t) : string = Id.name sink.id
end

module Source = struct
  type t =
    { id : Id.t
    ; kind : Jsmodel.Source.kind
    }

  let create (id_f : Id.maker) (jsmodel : Jsmodel.Source.t) : t =
    { id = id_f jsmodel.name; kind = jsmodel.kind }

  let pp (ppf : Fmt.t) (source : t) : unit =
    Fmt.fmt ppf "{ source: \"%a\", kind: \"%a\" }" Id.pp source.id
      Jsmodel.pp_kind source.kind

  let str (source : t) : string = Fmt.str "%a" pp source
  let name (source : t) : string = Id.name source.id
end
