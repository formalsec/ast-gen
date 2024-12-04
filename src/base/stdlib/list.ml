include Stdlib.List

let hd_opt : 'a t -> 'a option = function [] -> None | hd :: _ -> Some hd
let tl_opt : 'a t -> 'a list option = function [] -> None | _ :: tl -> Some tl
