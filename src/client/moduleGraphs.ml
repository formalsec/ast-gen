open Graphjs_base
open Graphjs_mdg

type key = string
type value = Mdg.t
type t = (string, value) Hashtbl.t

let empty () : t = Hashtbl.create 10
let add : t -> key -> value -> unit = Hashtbl.replace
let get : t -> key -> value = Hashtbl.find
