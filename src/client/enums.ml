open Graphjs_base

module DebugLvl = struct
  type t =
    | None
    | Warn
    | Info
    | Full

  let all : t list = [ None; Warn; Info; Full ]

  let pp (ppf : Fmt.t) : t -> unit = function
    | None -> Fmt.pp_str ppf "none"
    | Warn -> Fmt.pp_str ppf "warn"
    | Info -> Fmt.pp_str ppf "info"
    | Full -> Fmt.pp_str ppf "full"

  let str : t -> string = Fmt.str "%a" pp
  let args : t list -> (string * t) list = List.map (fun lvl -> (str lvl, lvl))

  let value : t -> int = function
    | None -> 0
    | Warn -> 1
    | Info -> 2
    | Full -> 3

  let ( < ) (lvl1 : t) (lvl2 : t) : bool = Stdlib.(value lvl1 < value lvl2)
  let ( > ) (lvl1 : t) (lvl2 : t) : bool = Stdlib.(value lvl1 > value lvl2)
  let ( <= ) (lvl1 : t) (lvl2 : t) : bool = Stdlib.(value lvl1 <= value lvl2)
  let ( >= ) (lvl1 : t) (lvl2 : t) : bool = Stdlib.(value lvl1 >= value lvl2)
end

module AnalysisMode = struct
  type t =
    | Basic
    | SingleFile
    | MultiFile

  let all : t list = [ Basic; SingleFile; MultiFile ]

  let pp (ppf : Fmt.t) : t -> unit = function
    | Basic -> Fmt.pp_str ppf "basic"
    | SingleFile -> Fmt.pp_str ppf "single-file"
    | MultiFile -> Fmt.pp_str ppf "multi-file"

  let str : t -> string = Fmt.str "%a" pp

  let args : t list -> (string * t) list =
    List.map (fun mode -> (str mode, mode))

  let conv : t -> Graphjs_shared.Mode.t = function
    | Basic -> Basic
    | SingleFile -> SingleFile
    | MultiFile -> MultiFile
end
