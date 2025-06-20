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
    fold (fun elt acc -> union acc (f elt)) set empty

  let map_list (f : elt -> 'a) (set : t) : 'a list =
    fold (fun elt acc -> f elt :: acc) set []

  let map_opt (f : elt -> elt option) (set : t) : t =
    let f' elt acc =
      match f elt with None -> acc | Some elt' -> add elt' acc in
    fold f' set empty
end
