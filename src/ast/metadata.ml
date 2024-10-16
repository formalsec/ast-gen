type ('m, 'e) t =
  { md : 'm
  ; el : 'e
  }

let ( @> ) (el : 'e) (md : 'm) : ('m, 'e) t = { el; md } [@@inline]
let el (x : ('m, 'e) t) : 'e = x.el [@@inline]
let md (x : ('m, 'e) t) : 'm = x.md [@@inline]
let map (f : 'e -> 'f) (x : ('m, 'e) t) : ('m, 'f) t = f x.el @> x.md [@@inline]
