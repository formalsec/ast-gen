open Graphjs_base

open struct
  let loc_gen = Generator.of_numbers ~init:1 ()
end

let reset_generator () : unit = loc_gen.reset ()

type t = int

let invalid = fun () -> -1
let create () : t = loc_gen.next ()
let hash (loc : t) : int = Int.hash loc
let equal (loc1 : t) (loc2 : t) : bool = Int.equal loc1 loc2
let compare (loc1 : t) (loc2 : t) : int = Int.compare loc1 loc2
let pp (ppf : Fmt.t) (loc : t) : unit = Fmt.fmt ppf "#%d" loc
let str (loc : t) : string = Fmt.str "%a" pp loc
