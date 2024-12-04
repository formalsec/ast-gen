include Stdlib.Fun

let ( << ) (f : 'b -> 'c) (g : 'a -> 'b) (x : 'a) : 'c = f (g x) [@@inline]

let flip2 (f : 'a -> 'b -> 'c -> 'd) (v2 : 'b) (v3 : 'c) (v1 : 'a) : 'd =
  f v1 v2 v3
[@@inline]
