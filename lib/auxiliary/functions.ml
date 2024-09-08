let (<<) f g x = f(g(x));;
let identity x = x 

let flip f x y = f y x

let map_default f x value =
  match value with
    | Some value -> f value
    | None -> x

let map_default_lazy f x value =
  match value with
    | Some value -> f value
    | None -> Lazy.force x

let option_may f x : unit = 
  match x with 
    | Some x -> f x
    | None   -> ()

let hd_opt (lst : 'a list) : 'a option =
  match lst with 
    | [] -> None 
    | fst::_ -> Some fst

let split3 (lst : ('a * 'b * 'c) list) : 'a list * 'b list * 'c list  =
  let rec aux lst (xs, ys, zs) = match lst with
    | [] -> (xs, ys, zs)
    | (x, y, z)::tail -> aux tail (x::xs, y::ys, z::zs)
  in aux lst ([], [], [])