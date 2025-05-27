open struct
  let id_gen = Generator.of_numbers ~init:1 ()
end

let reset_generator () : unit = id_gen.reset ()

type ('e, 'm) t =
  { id : int
  ; el : 'e
  ; md : 'm
  }

let ( @> ) (el : 'e) (md : 'm) : ('e, 'm) t =
  let id = id_gen.next () in
  { id; el; md }

let id (x : ('e, 'm) t) : int = x.id
let el (x : ('e, 'm) t) : 'e = x.el
let md (x : ('e, 'm) t) : 'm = x.md
