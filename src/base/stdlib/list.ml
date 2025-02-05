include Stdlib.List

let hd_opt (lst : 'a list) : 'a option =
  match lst with [] -> None | hd :: _ -> Some hd

let tl_opt (lst : 'a list) : 'a list option =
  match lst with [] -> None | _ :: tl -> Some tl

let split3 (lst : ('a * 'b * 'c) list) : 'a list * 'b list * 'c list =
  let split_f (a, b, c) (a', b', c') = (a :: a', b :: b', c :: c') in
  fold_right split_f lst ([], [], [])
