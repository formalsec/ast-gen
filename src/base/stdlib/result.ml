include Stdlib.Result

let ( let* ) (v : ('a, 'e) t) (f : 'a -> ('b, 'e) t) : ('b, 'e) t = bind v f
let ( let+ ) (f : 'a -> 'b) (v : ('a, 'e) t) : ('b, 'e) t = map f v

let extract (vs : ('a, 'b) t list) : ('a list, 'b) t =
  Fun.flip2 List.fold_right vs (Ok []) (fun v acc ->
      match (acc, v) with
      | ((Error _ as err), _) -> err
      | (Ok _, (Error _ as err)) -> err
      | (Ok vs, Ok v) -> Ok (v :: vs) )
