include Stdlib.Result

let ( let* ) v f = bind v f
let ( let+ ) v f = map f v
