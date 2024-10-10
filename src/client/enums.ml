open Graphjs_base

module DebugLvl = struct
  type t =
    | None
    | Warn
    | Full

  let all : t list = [ None; Warn; Full ]

  let pp (ppf : Fmt.t) : t -> unit = function
    | None -> Fmt.pp_str ppf "none"
    | Warn -> Fmt.pp_str ppf "warn"
    | Full -> Fmt.pp_str ppf "full"

  let str : t -> string = Fmt.str "%a" pp
  let value : t -> int = function None -> 0 | Warn -> 1 | Full -> 2
  let args : t list -> (string * t) list = List.map (fun lvl -> (str lvl, lvl))
  let ( < ) (lvl1 : t) (lvl2 : t) : bool = Stdlib.(value lvl1 < value lvl2)
  let ( > ) (lvl1 : t) (lvl2 : t) : bool = Stdlib.(value lvl1 > value lvl2)
  let ( <= ) (lvl1 : t) (lvl2 : t) : bool = Stdlib.(value lvl1 <= value lvl2)
  let ( >= ) (lvl1 : t) (lvl2 : t) : bool = Stdlib.(value lvl1 >= value lvl2)
end