type t = Yojson.Basic.t

exception Exn = Yojson.Basic.Util.Type_error

let from_file (path : string) : t = Yojson.Basic.from_file path
let from_string (data : string) : t = Yojson.Basic.from_string data
let to_int (json : t) : int = Yojson.Basic.Util.to_int json
let to_float (json : t) : float = Yojson.Basic.Util.to_float json
let to_number (json : t) : float = Yojson.Basic.Util.to_number json
let to_string (json : t) : string = Yojson.Basic.Util.to_string json
let to_bool (json : t) : bool = Yojson.Basic.Util.to_bool json
let to_list (json : t) : t list = Yojson.Basic.Util.to_list json
let to_assoc (json : t) : (string * t) list = Yojson.Basic.Util.to_assoc json
let member (field : string) (json : t) : t = Yojson.Basic.Util.member field json

let pp (ppf : Fmt.t) (json : t) : unit =
  Yojson.Basic.pretty_print ~std:true ppf json
