open Graphjs_base

module Config = struct
  include Config

  let id_gen = constant (Generator.of_numbers ~init:1 ())
end

type ('e, 'm) t =
  { id : int
  ; el : 'e
  ; md : 'm
  }

let ( @> ) (el : 'e) (md : 'm) : ('e, 'm) t =
  let id = Config.(!id_gen).next () in
  { id; el; md }

let el (x : ('e, 'm) t) : 'e = x.el
let md (x : ('e, 'm) t) : 'm = x.md
