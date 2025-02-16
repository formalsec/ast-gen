open Graphjs_base

type t =
  | Basic
  | SingleFile
  | MultiFile

let is_basic = function Basic -> true | _ -> false
let is_singlefile = function SingleFile -> true | _ -> false
let is_multifile = function MultiFile -> true | _ -> false

let pp (ppf : Fmt.t) (mode : t) : unit =
  match mode with
  | Basic -> Fmt.pp_str ppf "basic"
  | SingleFile -> Fmt.pp_str ppf "singlefile"
  | MultiFile -> Fmt.pp_str ppf "multifile"

let str (mode : t) : string = Fmt.str "%a" pp mode
