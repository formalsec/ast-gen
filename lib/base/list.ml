include List

let hd_opt : 'a list -> 'a option = function [] -> None | fst :: _ -> Some fst

let split3 (lst : ('a * 'b * 'c) list) : 'a list * 'b list * 'c list =
  let rec split3' (xs, ys, zs) = function
    | [] -> (List.rev xs, List.rev ys, List.rev zs)
    | (x, y, z) :: tl -> split3' (x :: xs, y :: ys, z :: zs) tl in
  split3' ([], [], []) lst
