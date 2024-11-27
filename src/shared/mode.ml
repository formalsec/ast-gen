type t =
  | Basic
  | SingleFile
  | MultiFile

let is_basic : t -> bool = function Basic -> true | _ -> false
let is_single_file : t -> bool = function SingleFile -> true | _ -> false
let is_multi_file : t -> bool = function MultiFile -> true | _ -> false

let pp (ppf : Format.formatter) : t -> unit = function
  | Basic -> Format.pp_print_string ppf "basic"
  | SingleFile -> Format.pp_print_string ppf "single_file"
  | MultiFile -> Format.pp_print_string ppf "multi_file"

let str (mode : t) : string = Format.asprintf "%a" pp mode
