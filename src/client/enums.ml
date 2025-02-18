open Graphjs_base

module DebugLvl = struct
  type t =
    | None
    | Warn
    | Info
    | All

  let all = [ None; Warn; Info; All ]

  let pp (ppf : Fmt.t) debug_lvl : unit =
    match debug_lvl with
    | None -> Fmt.pp_str ppf "none"
    | Warn -> Fmt.pp_str ppf "warn"
    | Info -> Fmt.pp_str ppf "info"
    | All -> Fmt.pp_str ppf "all"

  let str (debug_lvl : t) : string = Fmt.str "%a" pp debug_lvl

  let args (debug_lvls : t list) : (string * t) list =
    List.map (fun lvl -> (str lvl, lvl)) debug_lvls

  let value (debug_lvl : t) : int =
    match debug_lvl with None -> 0 | Warn -> 1 | Info -> 2 | All -> 3

  let ( < ) (lvl1 : t) (lvl2 : t) : bool = Stdlib.(value lvl1 < value lvl2)
  let ( > ) (lvl1 : t) (lvl2 : t) : bool = Stdlib.(value lvl1 > value lvl2)
  let ( <= ) (lvl1 : t) (lvl2 : t) : bool = Stdlib.(value lvl1 <= value lvl2)
  let ( >= ) (lvl1 : t) (lvl2 : t) : bool = Stdlib.(value lvl1 >= value lvl2)
end

module AnalysisMode = struct
  include Graphjs_share.Analysis_mode

  let all = [ Basic; SingleFile; MultiFile ]

  let args (modes : t list) : (string * t) list =
    List.map (fun mode -> (str mode, mode)) modes
end
