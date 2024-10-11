type t = Yojson.Basic.t

let pp : Fmt.t -> t -> unit = Yojson.Basic.pretty_print ~std:true
let from_file : string -> t = Yojson.Basic.from_file
let from_string : string -> t = Yojson.Basic.from_string
let member : string -> t -> t = Yojson.Basic.Util.member
let to_int : t -> int = Yojson.Basic.Util.to_int
let to_float : t -> float = Yojson.Basic.Util.to_float
let to_number : t -> float = Yojson.Basic.Util.to_number
let to_string : t -> string = Yojson.Basic.Util.to_string
let to_bool : t -> bool = Yojson.Basic.Util.to_bool
let to_list : t -> t list = Yojson.Basic.Util.to_list
let to_assoc : t -> (string * t) list = Yojson.Basic.Util.to_assoc
