include Stdlib.Option

let ( let* ) (o : 'a t) (f : 'a -> 'b t) : 'b t = bind o f
let ( let+ ) (f : 'a -> 'b) (o : 'a t) : 'b t = map f o

let value_lazy ~(default : 'a lazy_t) (o : 'a t) : 'a =
  match o with None -> Lazy.force default | Some v -> v

let map_none ~(value : 'a t) (o : 'a t) : 'a t =
  match o with None -> value | Some _ as v -> v

let fold_lazy ~(none : 'b lazy_t) ~(some : 'a -> 'b) (o : 'a t) : 'b =
  match o with None -> Lazy.force none | Some v -> some v
