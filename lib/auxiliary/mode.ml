type t = Basic | Single_file | Multi_file

let basic = Basic
let single_file = Single_file
let multi_file = Multi_file
let is_basic = function Basic -> true | _ -> false
let is_single_file = function Single_file -> true | _ -> false
let is_multi_file = function Multi_file -> true | _ -> false

let of_string = function
  | "basic" -> Ok Basic
  | "single_file" -> Ok Single_file
  | "multi_file" -> Ok Multi_file
  | _ ->
      Error "[ERROR] Invalid mode. Try using: basic, single_file or multi_file"

let pp fmt = function
  | Basic -> Format.pp_print_string fmt "basic"
  | Single_file -> Format.pp_print_string fmt "single_file"
  | Multi_file -> Format.pp_print_string fmt "multi_file"

let to_string mode = Format.asprintf "%a" pp mode
