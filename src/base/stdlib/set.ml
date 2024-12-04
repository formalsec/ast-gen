module type S = Stdlib.Set.S

module type OrderedType = sig
  type elt

  val compare : elt -> elt -> int
end

module Make (Ord : OrderedType) = struct
  include Stdlib.Set.Make (struct
    type t = Ord.elt

    let compare = Ord.compare
  end)

  let map_flat (f : elt -> t) (set : t) : t =
    fold (fun el acc -> union acc (f el)) set empty
end
