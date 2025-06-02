open Graphjs_share

module Id = struct
  type t =
    | Language of string
    | PackageSelf of string
    | PackageProp of string * string

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
    ; kind : Taint_config.sink
    ; args : int list
    }

  let pp (ppf : Fmt.t) (sink : t) : unit =
    let kind = (sink.kind :> Taint_config.Endpoint.kind) in
    Fmt.fmt ppf "{ sink: \"%a\", kind: \"%a\" args: [%a] }" Id.pp sink.id
      Taint_config.Endpoint.pp_kind kind Taint_config.Endpoint.pp_args sink.args

  let str (sink : t) : string = Fmt.str "%a" pp sink
  let name (sink : t) : string = Id.name sink.id
end

module Source = struct
  type t =
    { id : Id.t
    ; kind : Taint_config.source
    }

  let pp (ppf : Fmt.t) (source : t) : unit =
    let kind = (source.kind :> Taint_config.Endpoint.kind) in
    Fmt.fmt ppf "{ source: \"%a\", kind: \"%a\" }" Id.pp source.id
      Taint_config.Endpoint.pp_kind kind

  let str (source : t) : string = Fmt.str "%a" pp source
  let name (source : t) : string = Id.name source.id
end

type t =
  | Sink of Sink.t
  | Source of Source.t

let make (id : Id.t) (endpoint : Taint_config.Endpoint.t) : t =
  match endpoint.kind with
  | `CodeInjection | `CommandInjection | `PathTraversal ->
    let kind = Taint_config.sink endpoint.kind in
    Sink { id; kind; args = endpoint.args }
  | `TaintSource ->
    let kind = Taint_config.source endpoint.kind in
    Source { id; kind }

let language_sink (endpoint : Taint_config.Endpoint.t) : Sink.t =
  { id = Language endpoint.name
  ; kind = Taint_config.sink endpoint.kind
  ; args = endpoint.args
  }

let language (endpoint : Taint_config.Endpoint.t) : t =
  make (Language endpoint.name) endpoint

let package_self (package : string) (self : Taint_config.Endpoint.t) : t =
  make (PackageSelf package) self

let package_prop (package : string) (prop : Taint_config.Endpoint.t) : t =
  make (PackageProp (package, prop.name)) prop

let pp (ppf : Fmt.t) (tainted : t) : unit =
  match tainted with
  | Sink sink -> Sink.pp ppf sink
  | Source source -> Source.pp ppf source

let str (tainted : t) : string = Fmt.str "%a" pp tainted

let name (tainted : t) : string =
  match tainted with
  | Sink sink -> Sink.name sink
  | Source source -> Source.name source
