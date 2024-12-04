include Stdlib.Option

let ( let* ) : 'a t -> ('a -> 'b t) -> 'b t = bind
let ( let+ ) : ('a -> 'b) -> 'a t -> 'b t = map

let value_lazy ~(default : 'a lazy_t) : 'a t -> 'a = function
  | None -> Lazy.force default
  | Some o -> o

let fold_lazy ~(none : 'b lazy_t) ~(some : 'a -> 'b) : 'a t -> 'b = function
  | None -> Lazy.force none
  | Some v -> some v

let map_none ~(value : 'a t) : 'a t -> 'a t = function
  | None -> value
  | Some _ as o -> o
