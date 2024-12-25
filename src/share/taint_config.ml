open Graphjs_base

exception Exn of (Fmt.t -> unit)

open struct
  let raise (fmt : ('b, Fmt.t, unit, 'a) format4) : 'b =
    let raise_f acc = raise (Exn acc) in
    Fmt.kdly (fun acc -> raise_f (fun ppf -> Log.fmt_error ppf "%t" acc)) fmt
end

type package =
  { package : string
  ; args : int list
  }

type package_source =
  { source : string
  ; packages : package list
  }

type package_sink =
  { kind : Sink_kind.t
  ; sink : string
  ; packages : package list
  }

type function_sink =
  { kind : Sink_kind.t
  ; sink : string
  ; args : int list
  }

type new_sink =
  { kind : Sink_kind.t
  ; sink : string
  ; args : int list
  }

type t =
  { package_sources : package_source list
  ; package_sinks : package_sink list
  ; function_sinks : function_sink list
  ; new_sinks : new_sink list
  }

let default : unit -> t =
  let dflt =
    { package_sources = []
    ; package_sinks = []
    ; function_sinks = []
    ; new_sinks = []
    } in
  fun () -> dflt

let pp_indent (pp_v : Fmt.t -> 'a -> unit) (ppf : Fmt.t) (vs : 'a list) : unit =
  if List.length vs == 0 then ()
  else Fmt.fmt ppf "@\n@[<v 2>  %a@]" Fmt.(pp_lst !>"@\n" pp_v) vs

let pp_package (ppf : Fmt.t) (package : package) : unit =
  let pp_args = Fmt.(pp_lst !>", " pp_int) in
  Fmt.fmt ppf "{ package: %S, args: [%a] }" package.package pp_args package.args

let pp_package_source (ppf : Fmt.t) (package_source : package_source) : unit =
  Fmt.fmt ppf "{ source: %S, packages: [...] }%a" package_source.source
    (pp_indent pp_package) package_source.packages

let pp_package_sink (ppf : Fmt.t) (package_sink : package_sink) : unit =
  Fmt.fmt ppf "{ kind: \"%a\", source: %S, packages: [...] }%a" Sink_kind.pp
    package_sink.kind package_sink.sink (pp_indent pp_package)
    package_sink.packages

let pp_function_sink (ppf : Fmt.t) (function_sink : function_sink) : unit =
  let pp_args = Fmt.(pp_lst !>", " pp_int) in
  Fmt.fmt ppf "{ kind: \"%a\", source: %S, args: [%a] }" Sink_kind.pp
    function_sink.kind function_sink.sink pp_args function_sink.args

let pp_new_sink (ppf : Fmt.t) (new_sink : new_sink) : unit =
  let pp_args = Fmt.(pp_lst !>", " pp_int) in
  Fmt.fmt ppf "{ kind: \"%a\", source: %S, args: [%a] }" Sink_kind.pp
    new_sink.kind new_sink.sink pp_args new_sink.args

let pp (ppf : Fmt.t) (tconf : t) : unit =
  let pp_pckg_srcs = pp_indent pp_package_source in
  let pp_pckg_sinks = pp_indent pp_package_sink in
  let pp_func_sinks = pp_indent pp_function_sink in
  let pp_new_sinks = pp_indent pp_new_sink in
  Fmt.fmt ppf "[package_sources]%a@\n" pp_pckg_srcs tconf.package_sources;
  Fmt.fmt ppf "[package_sinks]%a@\n" pp_pckg_sinks tconf.package_sinks;
  Fmt.fmt ppf "[function_sinks]%a@\n" pp_func_sinks tconf.function_sinks;
  Fmt.fmt ppf "[new_sinks]%a" pp_new_sinks tconf.new_sinks

let str (tconf : t) : string = Fmt.str "%a" pp tconf [@@inline]

open struct
  type sources = package_source list
  type sinks = package_sink list * function_sink list * new_sink list

  let read_vuln : string -> Sink_kind.t = function
    | "code-injection" -> CodeInjection
    | "command-injection" -> CommandInjection
    | "path-traversal" -> PathTraversal
    | vuln -> raise "Unsupported vulnerability type '%s' in taint config." vuln

  let read_package (package : Json.t) : package =
    let package_name = package |> Json.member "package" |> Json.to_string in
    let package_args = package |> Json.member "args" |> Json.to_list in
    let package_args' = List.map Json.to_int package_args in
    { package = package_name; args = package_args' }

  let read_source (source : Json.t) (package_sources : sources) : sources =
    let source_name = source |> Json.member "source" |> Json.to_string in
    let source_type = source |> Json.member "type" |> Json.to_string in
    match source_type with
    | "package" ->
      let packages' = source |> Json.member "packages" |> Json.to_list in
      let packages = List.map read_package packages' in
      let package_source = { source = source_name; packages } in
      package_source :: package_sources
    | _ -> raise "Unsupported source type '%s' in taint config." source_type

  let read_sink (kind : Sink_kind.t) (sink : Json.t)
      ((package_sinks, function_sinks, new_sinks) : sinks) : sinks =
    let sink_name = sink |> Json.member "sink" |> Json.to_string in
    let sink_type = sink |> Json.member "type" |> Json.to_string in
    match sink_type with
    | "package" ->
      let packages' = sink |> Json.member "packages" |> Json.to_list in
      let packages = List.map read_package packages' in
      let package_sink : package_sink = { kind; sink = sink_name; packages } in
      (package_sink :: package_sinks, function_sinks, new_sinks)
    | "function" ->
      let args' = sink |> Json.member "args" |> Json.to_list in
      let args = List.map Json.to_int args' in
      let function_sink : function_sink = { kind; sink = sink_name; args } in
      (package_sinks, function_sink :: function_sinks, new_sinks)
    | "new" ->
      let args' = sink |> Json.member "args" |> Json.to_list in
      let args = List.map Json.to_int args' in
      let new_sink : new_sink = { kind; sink = sink_name; args } in
      (package_sinks, function_sinks, new_sink :: new_sinks)
    | _ -> raise "Unsupported sink type '%s' in taint config." sink_type

  let read_vuln_sink ((vuln_type, vuln_sinks) : string * Json.t) (sinks : sinks)
      : sinks =
    let vuln = read_vuln vuln_type in
    List.fold_right (read_sink vuln) (Json.to_list vuln_sinks) sinks

  let read_sources (config_json : Json.t) : package_source list =
    let sources = config_json |> Json.member "sources" in
    if sources == `Null then []
    else List.fold_right read_source (Json.to_list sources) []

  let read_sinks (config_json : Json.t) :
      package_sink list * function_sink list * new_sink list =
    let sinks = config_json |> Json.member "sinks" in
    if sinks == `Null then ([], [], [])
    else List.fold_right read_vuln_sink (Json.to_assoc sinks) ([], [], [])
end

let read (path : Fpath.t) : t =
  let config = Json.from_file (Fpath.to_string path) in
  let package_sources = read_sources config in
  let (package_sinks, function_sinks, new_sinks) = read_sinks config in
  { package_sources; package_sinks; function_sinks; new_sinks }
