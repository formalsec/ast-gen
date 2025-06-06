exception Exn of (Fmt.t -> unit)

let pp_indent (pp_v : Fmt.t -> 'a -> unit) (ppf : Fmt.t) (v : 'a) : unit =
  Fmt.fmt ppf "@\n@[<v 2>  %a@]@\n" pp_v v

let pp_list (pp_v : Fmt.t -> 'a -> unit) (ppf : Fmt.t) (vs : 'a list) : unit =
  match List.length vs with
  | 0 -> ()
  | 1 -> Fmt.fmt ppf "[%a]" Fmt.(pp_lst !>",@\n" pp_v) vs
  | _ -> Fmt.fmt ppf "[%a]" (pp_indent Fmt.(pp_lst !>",@\n" pp_v)) vs

let pp_kind (ppf : Fmt.t) (kind : 'a) : unit =
  match kind with
  | `CodeInjection -> Fmt.pp_str ppf "code-injection"
  | `CommandInjection -> Fmt.pp_str ppf "command-injection"
  | `PathTraversal -> Fmt.pp_str ppf "path-traversal"
  | `TaintedSymbol -> Fmt.pp_str ppf "tainted-symbol"

let pp_kind_field (ppf : Fmt.t) (kind : 'a) : unit =
  Fmt.fmt ppf "kind: \"%a\"" pp_kind kind

let pp_name_field (ppf : Fmt.t) (name : string) : unit =
  if String.length name == 0 then () else Fmt.fmt ppf ", name: %S" name

let pp_args_field (ppf : Fmt.t) (args : int list) : unit =
  if List.length args == 0 then ()
  else Fmt.fmt ppf ", args: [%a]" Fmt.(pp_lst !>", " pp_int) args

module Sink = struct
  type kind =
    [ `CodeInjection
    | `CommandInjection
    | `PathTraversal
    ]

  type t =
    { kind : kind
    ; name : string
    ; args : int list
    }

  let name (sink : t) : string = sink.name

  let pp (ppf : Fmt.t) (sink : t) : unit =
    Fmt.fmt ppf "{ %a%a%a }" pp_kind_field sink.kind pp_name_field sink.name
      pp_args_field sink.args

  let str (sink : t) : string = Fmt.str "%a" pp sink
end

module Source = struct
  type kind = [ `TaintedSymbol ]

  type t =
    { kind : kind
    ; name : string
    }

  let name (source : t) : string = source.name

  let pp (ppf : Fmt.t) (source : t) : unit =
    Fmt.fmt ppf "{ %a%a }" pp_kind_field source.kind pp_name_field source.name

  let str (source : t) : string = Fmt.str "%a" pp source
end

module Component = struct
  type t =
    [ `Sink of Sink.t
    | `Source of Source.t
    ]

  let name (component : t) : string =
    match component with
    | `Sink sink -> Sink.name sink
    | `Source source -> Source.name source

  let pp (ppf : Fmt.t) (component : t) : unit =
    match component with
    | `Sink sink -> Sink.pp ppf sink
    | `Source source -> Source.pp ppf source

  let str (component : t) : string = Fmt.str "%a" pp component
end

module Package = struct
  type t =
    { name : string
    ; self : Component.t option
    ; props : Component.t list
    }

  let pp_package_field (ppf : Fmt.t) (name : string) : unit =
    Fmt.fmt ppf "package: %S" name

  let pp_self_field (ppf : Fmt.t) (self : Component.t option) : unit =
    Fun.flip Option.iter self (fun component ->
        Fmt.fmt ppf ",@\nself: %a" Component.pp component )

  let pp_props_field (ppf : Fmt.t) (props : Component.t list) : unit =
    if List.length props > 0 then
      Fmt.fmt ppf ",@\nprops: %a" (pp_list Component.pp) props

  let pp' (ppf : Fmt.t) (package : t) : unit =
    Fmt.fmt ppf "%a%a%a" pp_package_field package.name pp_self_field
      package.self pp_props_field package.props

  let pp (ppf : Fmt.t) (package : t) : unit =
    Fmt.fmt ppf "{%a}" (pp_indent pp') package

  let str (package : t) : string = Fmt.str "%a" pp package
end

type t =
  { language : Component.t list
  ; packages : Package.t list
  }

let pp (ppf : Fmt.t) (model : t) : unit =
  Fmt.fmt ppf "language-config: %a,@\n" (pp_list Component.pp) model.language;
  Fmt.fmt ppf "package_configs: %a@\n" (pp_list Package.pp) model.packages

let str (model : t) : string = Fmt.str "%a" pp model

module Parser = struct
  let raise (fmt : ('b, Fmt.t, unit, 'a) format4) : 'b =
    let raise_f acc = raise (Exn acc) in
    Fmt.kdly (fun acc -> raise_f (fun ppf -> Log.fmt_error ppf "%t" acc)) fmt

  let raise_field (field_str : string) (type_str : string) : 'a =
    raise "Expecting '%s' field of type %s." field_str type_str

  let parse_opt (parse_f : Json.t -> 'a) (config : Json.t) : 'a option =
    if config != `Null then Some (parse_f config) else None

  let parse_opt_list (parse_f : Json.t -> 'a) (config : Json.t) : 'a list =
    if config != `Null then Json.to_list config |> List.map parse_f else []

  let parse_string_opt (config : Json.t) : string =
    if config != `Null then Json.to_string config else ""

  let parse_name (config : Json.t) : string =
    try config |> Json.member "name" |> parse_string_opt
    with Json.Exn _ -> raise_field "name" "string"

  let parse_args (config : Json.t) : int list =
    try config |> Json.member "args" |> Json.to_list |> List.map Json.to_int
    with _ -> raise_field "args" "integer list"

  let parse_sink (kind : Sink.kind) (config : Json.t) : Sink.t =
    { kind; name = parse_name config; args = parse_args config }

  let parse_source (kind : Source.kind) (config : Json.t) : Source.t =
    { kind; name = parse_name config }

  let parse_component (config : Json.t) : Component.t =
    try
      match config |> Json.member "type" |> Json.to_string with
      | "code-injection" -> `Sink (parse_sink `CodeInjection config)
      | "command-injection" -> `Sink (parse_sink `CommandInjection config)
      | "path-traversal" -> `Sink (parse_sink `PathTraversal config)
      | "tainted-symbol" -> `Source (parse_source `TaintedSymbol config)
      | kind -> raise "Unsupported component kind '%s' in model config." kind
    with Json.Exn _ -> raise_field "type" "string"

  let parse_language_config (config : Json.t) : Component.t list =
    try
      config |> Json.member "language-config" |> parse_opt_list parse_component
    with Json.Exn _ -> raise_field "language-config" "component list"

  let parse_package_name (config : Json.t) : string =
    try config |> Json.member "package" |> Json.to_string
    with Json.Exn _ -> raise_field "package" "string."

  let parse_package_self (config : Json.t) : Component.t option =
    try config |> Json.member "self" |> parse_opt parse_component
    with Json.Exn _ -> raise_field "self" "component object"

  let parse_package_props (config : Json.t) : Component.t list =
    try config |> Json.member "props" |> parse_opt_list parse_component
    with Json.Exn _ -> raise_field "props" "component list"

  let parse_package (config : Json.t) : Package.t =
    { name = parse_package_name config
    ; self = parse_package_self config
    ; props = parse_package_props config
    }

  let parse_package_config (config : Json.t) : Package.t list =
    try config |> Json.member "package-config" |> parse_opt_list parse_package
    with Json.Exn _ -> raise_field "package-config" "package list"

  let parse (path : Fpath.t) : t =
    let config = Json.from_file (Fpath.to_string path) in
    { language = parse_language_config config
    ; packages = parse_package_config config
    }
end
