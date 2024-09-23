include Fun

let seq (f : 'b -> 'c) (g : 'a -> 'b) (x : 'a) : 'c = f (g x) [@@inline]
let ( << ) : ('b -> 'c) -> ('a -> 'b) -> 'a -> 'c = seq
