include Stdlib.List

let hd_opt (lst : 'a list) : 'a option =
  match lst with [] -> None | hd :: _ -> Some hd

let tl_opt (lst : 'a list) : 'a list option =
  match lst with [] -> None | _ :: tl -> Some tl

let map_flat (f : 'a -> 'b list) (lst : 'a list) : 'b list =
  fold_left (fun acc el -> acc @ f el) [] lst

let split3 (lst : ('a * 'b * 'c) list) : 'a list * 'b list * 'c list =
  let split_f (a, b, c) (a', b', c') = (a :: a', b :: b', c :: c') in
  fold_right split_f lst ([], [], [])

let product (lst1 : 'a list) (lst2 : 'b list) : ('a * 'b) list =
  flatten (map (fun a -> map (fun b -> (a, b)) lst2) lst1)

let count (f : 'a -> bool) (lst : 'a list) : int =
  fold_left (fun acc el -> if f el then acc + 1 else acc) 0 lst
