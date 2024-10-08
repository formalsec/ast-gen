open Graphjs_base
open Graphjs_mdg

type key = string
type value = ExportedObject.t 
type t = (string, value) Hashtbl.t

let empty () : t = Hashtbl.create 10
let add : t -> key -> value -> unit = Hashtbl.replace
let get_opt : t -> key -> value option = Hashtbl.find_opt
