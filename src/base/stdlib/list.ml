include Stdlib.List

let hd_opt : 'a t -> 'a option = function [] -> None | fst :: _ -> Some fst

let split3 (lst : ('a * 'b * 'c) t) : 'a t * 'b t * 'c t =
  let rec split3' (xs, ys, zs) = function
    | [] -> (rev xs, rev ys, rev zs)
    | (x, y, z) :: tl -> split3' (x :: xs, y :: ys, z :: zs) tl in
  split3' ([], [], []) lst
