type t =
  | Basic
  | SingleFile
  | MultiFile

let is_basic : t -> bool = function Basic -> true | _ -> false
let is_single_file : t -> bool = function SingleFile -> true | _ -> false
let is_multi_file : t -> bool = function MultiFile -> true | _ -> false

let of_string : string -> (t, string) Result.t = function
  | "basic" -> Ok Basic
  | "single_file" -> Ok SingleFile
  | "multi_file" -> Ok MultiFile
  | _ -> Error "Invalid mode! Try using: basic, single_file or multi_file"

let pp (fmt : Format.formatter) : t -> unit = function
  | Basic -> Format.pp_print_string fmt "basic"
  | SingleFile -> Format.pp_print_string fmt "single_file"
  | MultiFile -> Format.pp_print_string fmt "multi_file"

let str (mode : t) : string = Format.asprintf "%a" pp mode
