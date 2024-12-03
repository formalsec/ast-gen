include Stdlib.Result

let ( let* ) v f = bind v f
let ( let+ ) v f = map f v

let extract (results : ('a, 'b) t list) : ('a list, 'b) t =
  let extract_f result acc =
    match (acc, result) with
    | ((Error _ as err), _) -> err
    | (Ok _, (Error _ as err)) -> err
    | (Ok results, Ok result') -> Ok (result' :: results) in
  List.fold_right extract_f results (Ok [])
