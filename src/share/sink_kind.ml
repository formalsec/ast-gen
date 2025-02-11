open Graphjs_base

type t =
  | CodeInjection
  | CommandInjection
  | PathTraversal

let hash (sink : t) : int =
  match sink with
  | CodeInjection -> 1
  | CommandInjection -> 2
  | PathTraversal -> 3

let equal (sink1 : t) (sink2 : t) : bool =
  match (sink1, sink2) with
  | (CodeInjection, CodeInjection) -> true
  | (CommandInjection, CommandInjection) -> true
  | (PathTraversal, PathTraversal) -> true
  | _ -> false

let compare (sink1 : t) (sink2 : t) : int =
  Int.compare (hash sink1) (hash sink2)

let pp (ppf : Fmt.t) (sink : t) : unit =
  match sink with
  | CodeInjection -> Fmt.pp_str ppf "code-injection"
  | CommandInjection -> Fmt.pp_str ppf "command-injection"
  | PathTraversal -> Fmt.pp_str ppf "path-traversal"

let str (sink : t) : string = Fmt.str "%a" pp sink
