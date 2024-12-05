open Graphjs_base

type t = int

let make_generator () : t Generator.t = Generator.of_numbers ~init:1 ()
[@@inline]

let reset (gen : t Generator.t) : unit = gen.reset () [@@inline]
let create (gen : t Generator.t) : t = gen.next () [@@inline]
let hash (loc : t) : int = Hashtbl.hash loc [@@inline]
let equal (loc1 : t) (loc2 : t) : bool = Int.equal loc1 loc2 [@@inline]
let compare (loc1 : t) (loc2 : t) : int = Int.compare loc1 loc2 [@@inline]
let pp (ppf : Fmt.t) (loc : t) : unit = Fmt.pp_int ppf loc [@@inline]
let str (loc : t) : string = Fmt.str "%a" pp loc [@@inline]
