type t =
  | Static of string
  | Dynamic

let is_static (prop : t) : bool =
  match prop with Static _ -> true | _ -> false

let is_dynamic (prop : t) : bool =
  match prop with Dynamic -> true | _ -> false

let hash (prop : t) : int =
  match prop with Static prop' -> String.hash prop' | Dynamic -> 0

let equal (prop1 : t) (prop2 : t) : bool =
  match (prop1, prop2) with
  | (Static prop1', Static prop2') -> String.equal prop1' prop2'
  | (Dynamic, Dynamic) -> true
  | _ -> false

let compare (prop1 : t) (prop2 : t) : int =
  match (prop1, prop2) with
  | (Static prop1', Static prop2') -> String.compare prop1' prop2'
  | (Dynamic, Dynamic) -> 0
  | (Dynamic, Static _) -> -1
  | (Static _, Dynamic) -> 1

let pp (ppf : Fmt.t) (prop : t) : unit =
  match prop with
  | Static prop' -> Fmt.pp_str ppf prop'
  | Dynamic -> Fmt.pp_str ppf "*"

let str (prop : t) : string = Fmt.str "%a" pp prop
