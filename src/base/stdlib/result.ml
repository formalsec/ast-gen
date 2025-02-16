include Stdlib.Result

let ( let* ) (r : ('a, 'e) t) (f : 'a -> ('b, 'e) t) : ('b, 'e) t = bind r f
let ( let+ ) (f : 'a -> 'b) (r : ('a, 'e) t) : ('b, 'e) t = map f r

let extract (rs : ('a, 'b) t list) : ('a list, 'b) t =
  Fun.flip2 List.fold_right rs (Ok []) (fun r acc ->
      match (acc, r) with
      | ((Error _ as err), _) -> err
      | (Ok _, (Error _ as err)) -> err
      | (Ok vs, Ok v) -> Ok (v :: vs) )
