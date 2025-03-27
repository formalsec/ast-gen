open Graphjs_base

type mode =
  | Single
  | PropWrap
  | Multiple

let is_single (mode : mode) : bool =
  match mode with Single -> true | _ -> false

let is_propwrap (mode : mode) : bool =
  match mode with PropWrap -> true | _ -> false

let is_multiple (mode : mode) : bool =
  match mode with Multiple -> true | _ -> false

type kind =
  | Default
  | Null
  | String
  | Number
  | Boolean
  | Regex
  | BigInt

type t =
  { kind : kind
  ; raw : string
  }

let default =
  let dflt = { kind = Default; raw = "" } in
  fun () -> dflt

let create (kind : kind) (raw : string) : t = { kind; raw }

let is_default (literal : t) : bool =
  match literal.kind with Default -> true | _ -> false

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

let pp (ppf : Fmt.t) (literal : t) : unit =
  match literal.kind with
  | Default -> Fmt.pp_str ppf "[[literal]]"
  | _ -> Fmt.pp_str ppf literal.raw

let str (literal : t) : string = Fmt.str "%a" pp literal
