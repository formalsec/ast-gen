type t =
  | Language of string
  | PackageSelf of string
  | PackageProp of string * string

type maker = string -> t

let language (name : string) : t = Language name
let package_self (package : string) : t = PackageSelf package

let package_prop (package : string) (prop : string) : t =
  PackageProp (package, prop)

let pp (ppf : Fmt.t) (ref : t) : unit =
  match ref with
  | Language name -> Fmt.fmt ppf "%s" name
  | PackageSelf package -> Fmt.fmt ppf "%s" package
  | PackageProp (package, prop) -> Fmt.fmt ppf "%s.%s" package prop

let str (ref : t) : string = Fmt.str "%a" pp ref

let name (ref : t) : string =
  match ref with
  | Language name -> name
  | PackageSelf package -> package
  | PackageProp (_, prop) -> prop
