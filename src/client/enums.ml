open Graphjs_base

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

module AnalysisMode = struct
  include Graphjs_share.Analysis_mode

  let all = [ Basic; SingleFile; MultiFile ]

  let args (modes : t list) : (string * t) list =
    List.map (fun mode -> (str mode, mode)) modes
end

module ExportView = struct
  type t = Graphjs_mdg.Export_view.t

  type conv =
    [ `Ok of t
    | `Error of string
    ]

  let default =
    let dflt = Graphjs_mdg.Export_view.Full in
    fun () -> dflt

  let pp (ppf : Fmt.t) (view : t) : unit =
    match view with
    | Full -> Fmt.pp_str ppf "full"
    | Calls -> Fmt.pp_str ppf "calls"
    | Function _ -> Fmt.pp_str ppf "function"
    | Object _ -> Fmt.pp_str ppf "object"
    | Reaches _ -> Fmt.pp_str ppf "reaches"

  let conv_param_view (view : string) (prefix : string) : bool =
    let regex = Str.regexp (Fmt.str "^%s:\\([0-9]+\\)" prefix) in
    Str.string_match regex view 0

  let conv (view : string) : conv =
    match view with
    | "full" -> `Ok Full
    | "calls" -> `Ok Calls
    | view' when conv_param_view view "function" ->
      `Ok (Function (int_of_string (Str.matched_group 1 view')))
    | view' when conv_param_view view "object" ->
      `Ok (Object (int_of_string (Str.matched_group 1 view')))
    | view' when conv_param_view view "reaches" ->
      `Ok (Reaches (int_of_string (Str.matched_group 1 view')))
    | _ -> `Error "Invalid export-view argument."

  let parse = (conv, pp)
end
