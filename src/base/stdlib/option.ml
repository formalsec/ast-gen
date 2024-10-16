include Stdlib.Option

let ( let* ) : 'a t -> ('a -> 'b t) -> 'b t = bind
let ( let+ ) : ('a -> 'b) -> 'a t -> 'b t = map

let apply ~(default : 'b) (f : 'a -> 'b) : 'a t -> 'b = function
  | Some v -> f v
  | None -> default

let apply_lazy ~(default : 'b lazy_t) (f : 'a -> 'b) : 'a t -> 'b = function
  | Some v -> f v
  | None -> Lazy.force default

let map_none ~(value : 'a t) : 'a t -> 'a t = function
  | Some _ as o -> o
  | None -> value
