open Graphjs_base

type t = int

let make_generator () : t Generator.t = Generator.of_numbers ~init:1 ()
let reset_generator (gen : t Generator.t) : unit = gen.reset ()
let create (gen : t Generator.t) : t = gen.next ()
let hash (loc : t) : int = Int.hash loc
let equal (loc1 : t) (loc2 : t) : bool = Int.equal loc1 loc2
let compare (loc1 : t) (loc2 : t) : int = Int.compare loc1 loc2
let pp (ppf : Fmt.t) (loc : t) : unit = Fmt.pp_int ppf loc
let str (loc : t) : string = Fmt.str "%a" pp loc
let literal = fun () -> -0
let invalid = fun () -> -1
let taint_source = fun () -> -3
