include Option

let ( let* ) : 'a t -> ('a -> 'b t) -> 'b t = bind
let ( let+ ) : ('a -> 'b) -> 'a t -> 'b t = map

let map_none ~(value : 'a t) : 'a t -> 'a t = function
  | None -> value
  | Some _ as o -> o