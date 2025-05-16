open Graphjs_base

exception Exn of (Fmt.t -> unit)

open struct
  let raise (fmt : ('b, Fmt.t, unit, 'a) format4) : 'b =
    let raise_f acc = raise (Exn acc) in
    Fmt.kdly (fun acc -> raise_f (fun ppf -> Log.fmt_error ppf "%t" acc)) fmt
end

let pp_args (ppf : Fmt.t) (args : int list) : unit =
  Fmt.(pp_lst !>", " pp_int) ppf args

let pp_indent (pp_v : Fmt.t -> 'a -> unit) (ppf : Fmt.t) (vs : 'a list) : unit =
  if List.length vs == 0 then ()
  else Fmt.fmt ppf "@\n@[<v 2>  %a@]" Fmt.(pp_lst !>"@\n" pp_v) vs

type package =
  { name : string
  ; args : int list
  }

let find_package (name : string) (pkgs : package list) : package =
  List.find (fun pkg -> String.equal name pkg.name) pkgs

let pp_package (ppf : Fmt.t) (pkg : package) : unit =
  Fmt.fmt ppf "{ package: %S, args: [%a] }" pkg.name pp_args pkg.args

type package_source =
  { name : string
  ; pkgs : package list
  }

let pp_package_source (ppf : Fmt.t) (p_source : package_source) : unit =
  Fmt.fmt ppf "{ source: %S, packages: [...] }%a" p_source.name
    (pp_indent pp_package) p_source.pkgs

type package_sink =
  { name : string
  ; kind : Sink_kind.t
  ; pkgs : package list
  }

let pp_package_sink (ppf : Fmt.t) (p_sink : package_sink) : unit =
  Fmt.fmt ppf "{ source: %S, kind: \"%a\", packages: [...] }%a" p_sink.name
    Sink_kind.pp p_sink.kind (pp_indent pp_package) p_sink.pkgs

type function_sink =
  { name : string
  ; kind : Sink_kind.t
  ; args : int list
  }

let pp_function_sink (ppf : Fmt.t) (f_sink : function_sink) : unit =
  Fmt.fmt ppf "{ source: %S, kind: \"%a\", args: [%a] }" f_sink.name
    Sink_kind.pp f_sink.kind pp_args f_sink.args

type new_sink =
  { name : string
  ; kind : Sink_kind.t
  ; args : int list
  }

let pp_new_sink (ppf : Fmt.t) (n_sink : new_sink) : unit =
  Fmt.fmt ppf "{ source: %S, kind: \"%a\", args: [%a] }" n_sink.name
    Sink_kind.pp n_sink.kind pp_args n_sink.args

type t =
  { p_sources : package_source list
  ; p_sinks : package_sink list
  ; f_sinks : function_sink list
  ; n_sinks : new_sink list
  }

let pp (ppf : Fmt.t) (tconf : t) : unit =
  let pp_p_sources = pp_indent pp_package_source in
  let pp_p_sinks = pp_indent pp_package_sink in
  let pp_f_sinks = pp_indent pp_function_sink in
  let pp_n_sinks = pp_indent pp_new_sink in
  Fmt.fmt ppf "[package_sources]%a@\n" pp_p_sources tconf.p_sources;
  Fmt.fmt ppf "[package_sinks]%a@\n" pp_p_sinks tconf.p_sinks;
  Fmt.fmt ppf "[function_sinks]%a@\n" pp_f_sinks tconf.f_sinks;
  Fmt.fmt ppf "[new_sinks]%a" pp_n_sinks tconf.n_sinks

let str (tconf : t) : string = Fmt.str "%a" pp tconf

open struct
  type sources = package_source list
  type sinks = package_sink list * function_sink list * new_sink list

  let read_sink_kind (sink_kind : string) : Sink_kind.t =
    match sink_kind with
    | "path-traversal" -> PathTraversal
    | "command-injection" -> CommandInjection
    | "code-injection" -> CodeInjection
    | _ -> raise "Unsupported sink kind '%s' in taint config." sink_kind

  let read_package (pkg : Json.t) : package =
    let pkg_name = pkg |> Json.member "package" |> Json.to_string in
    let pkg_args = pkg |> Json.member "args" |> Json.to_list in
    let pkg_args' = List.map Json.to_int pkg_args in
    { name = pkg_name; args = pkg_args' }

  let read_source (source : Json.t) (p_sources : sources) : sources =
    let source_name = source |> Json.member "source" |> Json.to_string in
    let source_type = source |> Json.member "type" |> Json.to_string in
    match source_type with
    | "package" ->
      let pkgs = source |> Json.member "packages" |> Json.to_list in
      let pkgs' = List.map read_package pkgs in
      { name = source_name; pkgs = pkgs' } :: p_sources
    | _ -> raise "Unsupported source type '%s' in taint config." source_type

  let read_sink (kind : Sink_kind.t) (sink : Json.t)
      ((p_sinks, f_sinks, n_sinks) : sinks) : sinks =
    let sink_name = sink |> Json.member "sink" |> Json.to_string in
    let sink_type = sink |> Json.member "type" |> Json.to_string in
    match sink_type with
    | "package" ->
      let pkgs = sink |> Json.member "packages" |> Json.to_list in
      let pkgs' = List.map read_package pkgs in
      let p_sink : package_sink = { kind; name = sink_name; pkgs = pkgs' } in
      (p_sink :: p_sinks, f_sinks, n_sinks)
    | "function" ->
      let args = sink |> Json.member "args" |> Json.to_list in
      let args' = List.map Json.to_int args in
      let f_sink : function_sink = { kind; name = sink_name; args = args' } in
      (p_sinks, f_sink :: f_sinks, n_sinks)
    | "new" ->
      let args = sink |> Json.member "args" |> Json.to_list in
      let args' = List.map Json.to_int args in
      let n_sink : new_sink = { kind; name = sink_name; args = args' } in
      (p_sinks, f_sinks, n_sink :: n_sinks)
    | _ -> raise "Unsupported sink type '%s' in taint config." sink_type

  let read_vuln_sink (vuln : string * Json.t) (sinks : sinks) : sinks =
    let (sink_kind, vuln_sinks) = vuln in
    let kind = read_sink_kind sink_kind in
    List.fold_right (read_sink kind) (Json.to_list vuln_sinks) sinks

  let read_sources (config : Json.t) : sources =
    let sources = config |> Json.member "sources" in
    if sources == `Null then []
    else List.fold_right read_source (Json.to_list sources) []

  let read_sinks (config : Json.t) : sinks =
    let sinks = config |> Json.member "sinks" in
    if sinks == `Null then ([], [], [])
    else List.fold_right read_vuln_sink (Json.to_assoc sinks) ([], [], [])
end

let read (path : Fpath.t) : t =
  let config = Json.from_file (Fpath.to_string path) in
  let p_sources = read_sources config in
  let (p_sinks, f_sinks, n_sinks) = read_sinks config in
  { p_sources; p_sinks; f_sinks; n_sinks }
