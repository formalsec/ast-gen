let (<<) f g x = f(g(x));;
let identity x = x 

let flip f x y = f y x

let map_default f x value =
  match value with
    | Some value -> f value
    | None -> x