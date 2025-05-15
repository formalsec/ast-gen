open Graphjs_base

type t =
  | PathTraversal
  | CommandInjection
  | CodeInjection

let hash (sink : t) : int =
  match sink with
  | PathTraversal -> 3
  | CommandInjection -> 2
  | CodeInjection -> 1

let equal (sink1 : t) (sink2 : t) : bool =
  match (sink1, sink2) with
  | (PathTraversal, PathTraversal) -> true
  | (CommandInjection, CommandInjection) -> true
  | (CodeInjection, CodeInjection) -> true
  | _ -> false

let compare (sink1 : t) (sink2 : t) : int =
  Int.compare (hash sink1) (hash sink2)

let pp (ppf : Fmt.t) (sink : t) : unit =
  match sink with
  | PathTraversal -> Fmt.pp_str ppf "path-traversal"
  | CommandInjection -> Fmt.pp_str ppf "command-injection"
  | CodeInjection -> Fmt.pp_str ppf "code-injection"

let str (sink : t) : string = Fmt.str "%a" pp sink
