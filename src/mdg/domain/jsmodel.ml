open Graphjs_ast

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

let pp_kind (ppf : Fmt.t) (kind : 'a) : unit =
  match kind with
  | `CodeInjection -> Fmt.pp_str ppf "code-injection"
  | `CommandInjection -> Fmt.pp_str ppf "command-injection"
  | `PathTraversal -> Fmt.pp_str ppf "path-traversal"
  | `TaintedSymbol -> Fmt.pp_str ppf "tainted-symbol"
  | `FunctionSummary -> Fmt.pp_str ppf "function-summary"
  | `ProtoMethodPolicy -> Fmt.pp_str ppf "proto-policy"
  | `BuiltinMethodPolicy _ -> Fmt.pp_str ppf "builtin-policy"
  | `PackageMethodPolicy _ -> Fmt.pp_str ppf "package-policy"

let pp_kind_field (ppf : Fmt.t) (kind : 'a) : unit =
  Fmt.fmt ppf "kind: \"%a\"" pp_kind kind

let pp_name_field (ppf : Fmt.t) (value : string) : unit =
  if String.length value > 0 then Fmt.fmt ppf ", name: %S" value

module TaintSink = struct
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

  let pp_args (ppf : Fmt.t) (args : int list) : unit =
    if List.length args != 0 then
      Fmt.fmt ppf ", args: [%a]" Fmt.(pp_lst !>", " pp_int) args

  let pp (ppf : Fmt.t) (sink : t) : unit =
    Fmt.fmt ppf "{ %a%a%a }" pp_kind_field sink.kind pp_name_field sink.name
      pp_args sink.args

  let str (sink : t) : string = Fmt.str "%a" pp sink
end

module TaintSource = struct
  type kind = [ `TaintedSymbol ]

  type t =
    { kind : kind
    ; name : string
    }

  let name (source : t) : string = source.name

  let pp (ppf : Fmt.t) (source : t) : unit =
    Fmt.fmt ppf "{ %a%a }" pp_kind source.kind pp_name_field source.name

  let str (source : t) : string = Fmt.str "%a" pp source
end

module FunctionSummary = struct
  type t =
    { name : string
    ; body : Region.t FunctionDefinition.t
    }

  let name (func : t) : string = func.name

  let pp (ppf : Fmt.t) (func : t) : unit =
    Fmt.fmt ppf "{ %a%a }" pp_kind `FunctionSummary pp_name_field func.name

  let str (func : t) : string = Fmt.str "%a" pp func
end

module Component = struct
  type t =
    [ `Sink of TaintSink.t
    | `Source of TaintSource.t
    | `Function of FunctionSummary.t
    ]

  let name (component : t) : string =
    match component with
    | `Sink sink -> TaintSink.name sink
    | `Source source -> TaintSource.name source
    | `Function func -> FunctionSummary.name func

  let rename (name : string) (component : t) : t =
    match component with
    | `Sink sink -> `Sink { sink with name }
    | `Source source -> `Source { source with name }
    | `Function func -> `Function { func with name }

  let pp (ppf : Fmt.t) (component : t) : unit =
    match component with
    | `Sink sink -> TaintSink.pp ppf sink
    | `Source source -> TaintSource.pp ppf source
    | `Function func -> FunctionSummary.pp ppf func

  let str (component : t) : string = Fmt.str "%a" pp component
end

module Collection = struct
  type t =
    { name : string
    ; self : Component.t option
    ; props : Component.t list
    }

  let pp_name (ppf : Fmt.t) (name : string) : unit =
    Fmt.fmt ppf "package: %S" name

  let pp_self (ppf : Fmt.t) (self : Component.t option) : unit =
    Fun.flip Option.iter self (fun component ->
        Fmt.fmt ppf ",@\nself: %a" Component.pp component )

  let pp_props (ppf : Fmt.t) (props : Component.t list) : unit =
    if List.length props > 0 then
      Fmt.fmt ppf ",@\nprops: %a" (pp_list Component.pp) props

  let pp' (ppf : Fmt.t) (collection : t) : unit =
    Fmt.fmt ppf "%a%a%a" pp_name collection.name pp_self collection.self
      pp_props collection.props

  let pp (ppf : Fmt.t) (collection : t) : unit =
    Fmt.fmt ppf "{%a}" (pp_indent pp') collection

  let str (collection : t) : string = Fmt.str "%a" pp collection
end

module TaintPolicy = struct
  type kind =
    [ `ProtoMethodPolicy
    | `BuiltinMethodPolicy of string option
    | `PackageMethodPolicy of string option
    ]

  type source =
    [ `This
    | `Arg of int
    | `Args of int
    ]

  type target =
    [ `This
    | `Retn
    | `Arg of int
    | `Args of int
    | `FArg of int * target
    ]

  let rec pp_point (ppf : Fmt.t) (point : 'a) : unit =
    match point with
    | `This -> Fmt.pp_str ppf "this"
    | `Retn -> Fmt.pp_str ppf "retn"
    | `Arg idx -> Fmt.fmt ppf "arg%d" idx
    | `Args idx -> Fmt.fmt ppf "arg%d..." idx
    | `FArg (idx, point') -> Fmt.fmt ppf "arg%d:%a" idx pp_point point'

  type t =
    { kind : kind
    ; name : string
    ; source : source
    ; targets : target list
    }

  let pp_reference (ppf : Fmt.t) (policy : t) : unit =
    match policy.kind with
    | `BuiltinMethodPolicy None -> Fmt.fmt ppf ", builtin: %S" policy.name
    | `PackageMethodPolicy None -> Fmt.fmt ppf ", package: %S" policy.name
    | `BuiltinMethodPolicy (Some builtin) ->
      Fmt.fmt ppf ", builtin: %S, name: %S" builtin policy.name
    | `PackageMethodPolicy (Some package) ->
      Fmt.fmt ppf ", package: %S, name: %S" package policy.name
    | _ -> ()

  let pp_source (ppf : Fmt.t) (source : source) : unit =
    Fmt.fmt ppf ", source: \"%a\"" pp_point source

  let pp_targets (ppf : Fmt.t) (targets : target list) : unit =
    let pp_target' ppf point = Fmt.fmt ppf "\"%a\"" pp_point point in
    Fmt.fmt ppf ", targets: [%a]" Fmt.(pp_lst !>", " pp_target') targets

  let pp (ppf : Fmt.t) (policy : t) : unit =
    Fmt.fmt ppf "{ %a%a%a%a }" pp_kind_field policy.kind pp_reference policy
      pp_source policy.source pp_targets policy.targets

  let str (policy : t) : string = Fmt.str "%a" pp policy
end

type t =
  { language : Component.t list
  ; builtins : Collection.t list
  ; packages : Collection.t list
  ; policies : TaintPolicy.t list
  }

let pp (ppf : Fmt.t) (model : t) : unit =
  let pp_component = pp_list Component.pp in
  let pp_collection = pp_list Collection.pp in
  let pp_policies = pp_list TaintPolicy.pp in
  Fmt.fmt ppf "language-components: %a,@\n" pp_component model.language;
  Fmt.fmt ppf "builtin-components: %a,@\n" pp_collection model.builtins;
  Fmt.fmt ppf "package_components: %a,@\n" pp_collection model.packages;
  Fmt.fmt ppf "taint_policies: %a@\n" pp_policies model.policies

let str (model : t) : string = Fmt.str "%a" pp model

module JSParser = struct
  open Graphjs_parser
  open Metadata

  let parse_func (code : string) : Region.t FunctionDefinition.t =
    let pp_body = Fmt.(pp_lst !>";@\n" Statement.pp) in
    let ctx = Normalizer.Ctx.default () in
    let ast = Flow_parser.parse_code code in
    let body = Normalizer.normalize_file ctx ast in
    match body with
    | [ { el = `FunctionDefinition func; _ } ] -> func
    | _ -> raise "Unexpected function summary body:@\n%a" pp_body body
end

module Parser = struct
  let raise_field (field_str : string) (type_str : string) : 'a =
    raise "Expecting '%s' field of type %s." field_str type_str

  let parse_list (parse_f : Json.t -> 'a) (config : Json.t) : 'a list =
    config |> Json.to_list |> List.map parse_f

  let parse_opt (parse_f : Json.t -> 'a) (config : Json.t) : 'a option =
    if config != `Null then Some (parse_f config) else None

  let parse_opt_list (parse_f : Json.t -> 'a) (config : Json.t) : 'a list =
    if config != `Null then parse_list parse_f config else []

  let parse_name ?(field = "name") (config : Json.t) : string =
    try config |> Json.member field |> Json.to_string
    with Json.Exn _ -> raise_field field "string"

  let parse_name_opt ?(field = "name") (config : Json.t) : string =
    let parse_f config = if config != `Null then Json.to_string config else "" in
    try config |> Json.member field |> parse_f
    with Json.Exn _ -> raise_field field "string"

  let parse_args (config : Json.t) : int list =
    try config |> Json.member "args" |> parse_list Json.to_int
    with _ -> raise_field "args" "integer list"

  let parse_code (config : Json.t) : Region.t FunctionDefinition.t =
    try
      let code = config |> Json.member "code" |> Json.to_string in
      JSParser.parse_func code
    with _ -> raise_field "code" "string"

  let parse_sink (kind : TaintSink.kind) (config : Json.t) : TaintSink.t =
    { kind; name = parse_name_opt config; args = parse_args config }

  let parse_source (kind : TaintSource.kind) (config : Json.t) : TaintSource.t =
    { kind; name = parse_name_opt config }

  let parse_function_summary (config : Json.t) : FunctionSummary.t =
    { name = parse_name_opt config; body = parse_code config }

  let parse_component (config : Json.t) : Component.t =
    try
      match config |> Json.member "type" |> Json.to_string with
      | "code-injection" -> `Sink (parse_sink `CodeInjection config)
      | "command-injection" -> `Sink (parse_sink `CommandInjection config)
      | "path-traversal" -> `Sink (parse_sink `PathTraversal config)
      | "tainted-symbol" -> `Source (parse_source `TaintedSymbol config)
      | "function-summary" -> `Function (parse_function_summary config)
      | kind -> raise "Unsupported component kind '%s' in model config." kind
    with Json.Exn _ -> raise_field "type" "string"

  let parse_language_components (config : Json.t) : Component.t list =
    let parse_f = parse_opt_list parse_component in
    try config |> Json.member "language-components" |> parse_f
    with Json.Exn _ -> raise_field "language-components" "component list"

  let parse_collection_name (field : string) (config : Json.t) : string =
    try config |> Json.member field |> Json.to_string
    with Json.Exn _ -> raise_field field "string"

  let parse_collection_self (config : Json.t) : Component.t option =
    try config |> Json.member "self" |> parse_opt parse_component
    with Json.Exn _ -> raise_field "self" "component object"

  let parse_collection_props (config : Json.t) : Component.t list =
    try config |> Json.member "props" |> parse_opt_list parse_component
    with Json.Exn _ -> raise_field "props" "component list"

  let parse_collection (collection : string) (config : Json.t) : Collection.t =
    { name = parse_collection_name collection config
    ; self = parse_collection_self config
    ; props = parse_collection_props config
    }

  let parse_builtin_components (config : Json.t) : Collection.t list =
    let parse_f = parse_opt_list (parse_collection "builtin") in
    try config |> Json.member "builtin-components" |> parse_f
    with Json.Exn _ -> raise_field "builtin-components" "builtin list"

  let parse_package_components (config : Json.t) : Collection.t list =
    let parse_f = parse_opt_list (parse_collection "package") in
    try config |> Json.member "package-components" |> parse_f
    with Json.Exn _ -> raise_field "package-components" "package list"

  let parse_policy_source_value (source : string) : TaintPolicy.source =
    let err_f = raise "Unsupported taint policy source '%s' in model config." in
    let re_arg = {|^arg\([1-9][0-9]*\)\(\.\.\.\)?$|} in
    match source with
    | "this" -> `This
    | source' when Str.string_match (Str.regexp re_arg) source' 0 -> (
      let arg = int_of_string (Str.matched_group 1 source') in
      match Str.matched_group 2 source' with
      | exception Not_found -> `Arg arg
      | "..." -> `Args arg
      | _ -> err_f source )
    | _ -> err_f source

  let rec parse_policy_target_value (target : string) : TaintPolicy.target =
    let err_f = raise "Unsupported taint policy target '%s' in model config." in
    let re_arg = {|^arg\([1-9][0-9]*\)\(\(\.\.\.\)\|\(:\(.*\)\)\)?$|} in
    match target with
    | "this" -> `This
    | "retn" -> `Retn
    | target' when Str.string_match (Str.regexp re_arg) target' 0 -> (
      let arg = int_of_string (Str.matched_group 1 target') in
      match Str.matched_group 2 target' with
      | exception Not_found -> `Arg arg
      | "..." -> `Args arg
      | _ -> parse_policy_target_value (Str.matched_group 5 target') )
    | _ -> err_f target

  let parse_policy_source (config : Json.t) : TaintPolicy.source =
    let parse_f config = Json.to_string config |> parse_policy_source_value in
    try config |> Json.member "source" |> parse_f
    with Json.Exn _ -> raise_field "source" "policy source"

  let parse_policy_targets (config : Json.t) : TaintPolicy.target list =
    let parse_f config = Json.to_string config |> parse_policy_target_value in
    try config |> Json.member "targets" |> parse_list parse_f
    with Json.Exn _ -> raise_field "targets" "policy targets"

  let parse_proto_method_policy (config : Json.t) : TaintPolicy.t =
    { kind = `ProtoMethodPolicy
    ; name = parse_name config
    ; source = parse_policy_source config
    ; targets = parse_policy_targets config
    }

  let parse_self_collection_policy (collection : string) (name : string) :
      string option * string =
    if String.length name == 0 then (None, collection)
    else (Some collection, name)

  let parse_builtin_method_policy (config : Json.t) : TaintPolicy.t =
    let builtin' = parse_name ~field:"builtin" config in
    let name' = parse_name_opt config in
    let (builtin, name) = parse_self_collection_policy builtin' name' in
    let kind = `BuiltinMethodPolicy builtin in
    let source = parse_policy_source config in
    let targets = parse_policy_targets config in
    { kind; name; source; targets }

  let parse_package_method_policy (config : Json.t) : TaintPolicy.t =
    let package' = parse_name ~field:"package" config in
    let name' = parse_name_opt config in
    let (package, name) = parse_self_collection_policy package' name' in
    let kind = `PackageMethodPolicy package in
    let source = parse_policy_source config in
    let targets = parse_policy_targets config in
    { kind; name; source; targets }

  let parse_taint_policy (config : Json.t) : TaintPolicy.t =
    try
      match config |> Json.member "type" |> Json.to_string with
      | "proto-policy" -> parse_proto_method_policy config
      | "builtin-policy" -> parse_builtin_method_policy config
      | "package-policy" -> parse_package_method_policy config
      | kind -> raise "Unsupported taint policy kind '%s' in model config." kind
    with Json.Exn _ -> raise_field "kind" "string"

  let parse_taint_policies (config : Json.t) : TaintPolicy.t list =
    let parse_f = parse_opt_list parse_taint_policy in
    try config |> Json.member "taint-policies" |> parse_f
    with Json.Exn _ -> raise_field "taint-policies" "taint policy list"

  let parse (path : Fpath.t) : t =
    let config = Json.from_file (Fpath.to_string path) in
    { language = parse_language_components config
    ; builtins = parse_builtin_components config
    ; packages = parse_package_components config
    ; policies = parse_taint_policies config
    }
end
