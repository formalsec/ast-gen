module DebugLvl = struct
  type t =
    | None
    | Warn
    | Info
    | All

  let all = [ None; Warn; Info; All ]

  let pp (ppf : Fmt.t) (debug_lvl : t) : unit =
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

module ExportView = struct
  open Graphjs_mdg

  type t = Graphjs_mdg.Export_view.t

  type conv =
    [ `Ok of t
    | `Error of string
    ]

  let pp (ppf : Fmt.t) (view : t) : unit =
    match view with
    | Full -> Fmt.pp_str ppf "full"
    | Calls -> Fmt.pp_str ppf "calls"
    | Object _ -> Fmt.pp_str ppf "object"
    | Parent _ -> Fmt.pp_str ppf "function"
    | Reaches _ -> Fmt.pp_str ppf "reaches"
    | Sinks -> Fmt.pp_str ppf "sinks"
    | Tainted _ -> Fmt.pp_str ppf "tainted"

  let conv_param_view (view : string) (prefix : string) : bool =
    let regex = Str.regexp (Fmt.str "^%s:\\([0-9]+\\)$" prefix) in
    Str.string_match regex view 0

  let conv (view : string) : conv =
    match view with
    | "full" -> `Ok Full
    | "calls" -> `Ok Calls
    | "sinks" -> `Ok Sinks
    | "tainted" -> `Ok (Tainted Node.Set.empty)
    | view' when conv_param_view view "object" ->
      `Ok (Object (int_of_string (Str.matched_group 1 view')))
    | view' when conv_param_view view "parent" ->
      `Ok (Parent (int_of_string (Str.matched_group 1 view')))
    | view' when conv_param_view view "reaches" ->
      `Ok (Reaches (int_of_string (Str.matched_group 1 view')))
    | _ -> `Error "Invalid export-view argument."

  let parse = (conv, pp)
end
