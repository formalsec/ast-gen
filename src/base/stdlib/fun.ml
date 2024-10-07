include Stdlib.Fun

let ( << ) (f : 'b -> 'c) (g : 'a -> 'b) (x : 'a) : 'c = f (g x) [@@inline]
