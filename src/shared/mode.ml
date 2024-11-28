open Graphjs_base

type t =
  | Basic
  | SingleFile
  | MultiFile

let is_basic : t -> bool = function Basic -> true | _ -> false
let is_single_file : t -> bool = function SingleFile -> true | _ -> false
let is_multi_file : t -> bool = function MultiFile -> true | _ -> false

let pp (ppf : Fmt.t) : t -> unit = function
  | Basic -> Fmt.pp_str ppf "basic"
  | SingleFile -> Fmt.pp_str ppf "single_file"
  | MultiFile -> Fmt.pp_str ppf "multi_file"

let str (mode : t) : string = Fmt.str "%a" pp mode
