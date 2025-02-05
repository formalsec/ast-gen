include Stdlib.Fun

let ( << ) (f : 'b -> 'c) (g : 'a -> 'b) (x : 'a) : 'c = f (g x)
let flip (f : 'a -> 'b -> 'c) (v2 : 'b) (v1 : 'a) : 'c = f v1 v2

let flip2 (f : 'a -> 'b -> 'c -> 'd) (v2 : 'b) (v3 : 'c) (v1 : 'a) : 'd =
  f v1 v2 v3
