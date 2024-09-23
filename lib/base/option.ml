include Option

let ( let* ) : 'a t -> ('a -> 'b t) -> 'b t = bind
let ( let+ ) : ('a -> 'b) -> 'a t -> 'b t = map

let map_none ~(value : 'a t) : 'a t -> 'a t = function
  | None -> value
  | Some _ as o -> o

let apply ~(default : 'b) (f : 'a -> 'b) : 'a t -> 'b = function
  | None -> default
  | Some v -> f v

let apply_lazy ~(default : 'b lazy_t) (f : 'a -> 'b) : 'a t -> 'b = function
  | None -> Lazy.force default
  | Some v -> f v
