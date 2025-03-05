open Graphjs_base

type t = string option

let static (name : string) = Some name

let dynamic =
  let dyn = None in
  fun () -> dyn

let is_static (prop : t) = Option.is_some prop
let is_dynamic (prop : t) = Option.is_none prop
let hash (prop : t) : int = Option.fold ~none:0 ~some:String.hash prop
let equal (prop1 : t) (prop2 : t) : bool = Option.equal String.equal prop1 prop2

let compare (prop1 : t) (prop2 : t) : int =
  Option.compare String.compare prop1 prop2

let pp (ppf : Fmt.t) (prop : t) : unit =
  Fmt.pp_str ppf (Option.value ~default:"*" prop)

let str (prop : t) : string = Fmt.str "%a" pp prop
