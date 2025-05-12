open Graphjs_base

type kind =
  | Null
  | String
  | Number
  | Boolean
  | Regex
  | BigInt
  | Template

type t =
  { kind : kind
  ; raw : string
  }

let create (kind : kind) (raw : string) : t = { kind; raw }

let is_null (literal : t) : bool =
  match literal.kind with Null -> true | _ -> false

let is_string (literal : t) : bool =
  match literal.kind with String -> true | _ -> false

let is_number (literal : t) : bool =
  match literal.kind with Number -> true | _ -> false

let is_boolean (literal : t) : bool =
  match literal.kind with Boolean -> true | _ -> false

let is_regex (literal : t) : bool =
  match literal.kind with Regex -> true | _ -> false

let is_bigint (literal : t) : bool =
  match literal.kind with BigInt -> true | _ -> false

let is_template (literal : t) : bool =
  match literal.kind with Template -> true | _ -> false

let pp (ppf : Fmt.t) (literal : t) : unit = Fmt.pp_str ppf literal.raw
let str (literal : t) : string = Fmt.str "%a" pp literal
