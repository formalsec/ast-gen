exception Exn of (Fmt.t -> unit)

let raise (fmt : ('b, Fmt.t, unit, 'a) format4) : 'b =
  let raise_f acc = raise (Exn acc) in
  Fmt.kdly (fun acc -> raise_f (fun ppf -> Log.fmt_error ppf "%t" acc)) fmt

let pp_indent (pp_v : Fmt.t -> 'a -> unit) (ppf : Fmt.t) (v : 'a) : unit =
  Fmt.fmt ppf "@\n@[<v 2>  %a@]@\n" pp_v v

let pp_list (pp_v : Fmt.t -> 'a -> unit) (ppf : Fmt.t) (vs : 'a list) : unit =
  match List.length vs with
  | 0 -> ()
  | 1 -> Fmt.fmt ppf "[%a]" Fmt.(pp_lst !>",@\n" pp_v) vs
  | _ -> Fmt.fmt ppf "[%a]" (pp_indent Fmt.(pp_lst !>",@\n" pp_v)) vs

type sink =
  [ `CodeInjection
  | `CommandInjection
  | `PathTraversal
  ]

type source = [ `TaintSource ]

let sink = function
  | (`CodeInjection | `CommandInjection | `PathTraversal) as kind' -> kind'
  | _ -> Log.fail "unexpected non-sink endpoint"

let source = function
  | `TaintSource as kind' -> kind'
  | _ -> Log.fail "unexpected non-source endpoint"

module Endpoint = struct
  type kind =
    [ sink
    | source
    ]

  type t =
    { name : string
    ; kind : kind
    ; args : int list
    }

  let pp_kind (ppf : Fmt.t) (kind : kind) : unit =
    match kind with
    | `CodeInjection -> Fmt.pp_str ppf "kind: \"code-injection\""
    | `CommandInjection -> Fmt.pp_str ppf "kind: \"command-injection\""
    | `PathTraversal -> Fmt.pp_str ppf "kind: \"path-traversal\""
    | `TaintSource -> Fmt.pp_str ppf "kind: \"taint-source\""

  let pp_name (ppf : Fmt.t) (name : string) : unit =
    if String.length name == 0 then () else Fmt.fmt ppf ", name: %S" name

  let pp_args (ppf : Fmt.t) (args : int list) : unit =
    if List.length args == 0 then ()
    else Fmt.fmt ppf ", args: [%a]" Fmt.(pp_lst !>", " pp_int) args

  let pp (ppf : Fmt.t) (endpoint : t) : unit =
    Fmt.fmt ppf "{ %a%a%a }" pp_kind endpoint.kind pp_name endpoint.name pp_args
      endpoint.args

  let str (endpoint : t) : string = Fmt.str "%a" pp endpoint
end

module Package = struct
  type t =
    { name : string
    ; self : Endpoint.t option
    ; props : Endpoint.t list
    }

  let pp_package (ppf : Fmt.t) (name : string) : unit =
    Fmt.fmt ppf "package: %S" name

  let pp_self (ppf : Fmt.t) (self : Endpoint.t option) : unit =
    Fun.flip Option.iter self (fun endpoint ->
        Fmt.fmt ppf ",@\nself: %a" Endpoint.pp endpoint )

  let pp_props (ppf : Fmt.t) (props : Endpoint.t list) : unit =
    if List.length props > 0 then
      Fmt.fmt ppf ",@\nprops: %a" (pp_list Endpoint.pp) props

  let pp' (ppf : Fmt.t) (package : t) : unit =
    Fmt.fmt ppf "%a%a%a" pp_package package.name pp_self package.self pp_props
      package.props

  let pp (ppf : Fmt.t) (package : t) : unit =
    Fmt.fmt ppf "{%a}" (pp_indent pp') package

  let str (package : t) : string = Fmt.str "%a" pp package
end

type t =
  { language : Endpoint.t list
  ; packages : Package.t list
  }

let pp (ppf : Fmt.t) (tconf : t) : unit =
  Fmt.fmt ppf "language-endpoints: %a,@\n" (pp_list Endpoint.pp) tconf.language;
  Fmt.fmt ppf "package_endpoints: %a@\n" (pp_list Package.pp) tconf.packages

let str (tconf : t) : string = Fmt.str "%a" pp tconf

let parse_endpoint_name (name : Json.t) : string =
  try Json.to_string name
  with _ -> raise "Expected 'name' field of type string."

let parse_endpoint_kind (kind : Json.t) : Endpoint.kind =
  match kind with
  | `String "code-injection" -> `CodeInjection
  | `String "command-injection" -> `CommandInjection
  | `String "path-traversal" -> `PathTraversal
  | `String "taint-source" -> `TaintSource
  | _ -> raise "Unsupported endpoint kind '%a' in taint config." Json.pp kind

let parse_endpoint_args (args : Json.t) : int list =
  try Json.to_list args |> List.map Json.to_int
  with _ -> raise "Expecting 'args' field of type integer list."

let read_endpoint_body (endpoint : Json.t) : Endpoint.kind * int list =
  let kind = endpoint |> Json.member "type" |> parse_endpoint_kind in
  match kind with
  | `CodeInjection | `CommandInjection | `PathTraversal ->
    let args = endpoint |> Json.member "args" |> parse_endpoint_args in
    (kind, args)
  | `TaintSource -> (kind, [])

let read_endpoint (endpoint : Json.t) : Endpoint.t =
  let name = endpoint |> Json.member "name" |> parse_endpoint_name in
  let (kind, args) = read_endpoint_body endpoint in
  { name; kind; args }

let parse_package_name (name : Json.t) : string =
  try Json.to_string name
  with _ -> raise "Expected 'package' field of type string."

let parse_package_self (self : Json.t) : Endpoint.t option =
  if self != `Null then
    let (kind, args) = read_endpoint_body self in
    Some { name = ""; kind; args }
  else None

let parse_package_props (props : Json.t) : Endpoint.t list =
  if props != `Null then List.map read_endpoint (Json.to_list props) else []

let read_package (package : Json.t) : Package.t =
  let name = package |> Json.member "package" |> parse_package_name in
  let self = package |> Json.member "self" |> parse_package_self in
  let props = package |> Json.member "props" |> parse_package_props in
  { name; self; props }

let read_language_endpoints (config : Json.t) : Endpoint.t list =
  let endpoints = config |> Json.member "language-endpoints" in
  if endpoints != `Null then List.map read_endpoint (Json.to_list endpoints)
  else []

let read_package_endpoints (config : Json.t) : Package.t list =
  let packages = config |> Json.member "package-endpoints" in
  if packages != `Null then List.map read_package (Json.to_list packages)
  else []

let read (path : Fpath.t) : t =
  let config = Json.from_file (Fpath.to_string path) in
  let language = read_language_endpoints config in
  let packages = read_package_endpoints config in
  { language; packages }
