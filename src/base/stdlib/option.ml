include Stdlib.Option

let ( let* ) (v : 'a t) (f : 'a -> 'b t) : 'b t = bind v f
let ( let+ ) (f : 'a -> 'b) (v : 'a t) : 'b t = map f v

let value_lazy ~(default : 'a lazy_t) : 'a t -> 'a = function
  | None -> Lazy.force default
  | Some v -> v

let map_none ~(value : 'a t) : 'a t -> 'a t = function
  | None -> value
  | Some _ as v -> v

let fold_lazy ~(none : 'b lazy_t) ~(some : 'a -> 'b) : 'a t -> 'b = function
  | None -> Lazy.force none
  | Some v -> some v
