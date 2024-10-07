open Graphjs_base
open Graphjs_mdg
open Structs

type key = string
type value = Mdg.t
type t = value HashTable.t

let empty () : t = HashTable.create 10
let add : t -> key -> value -> unit = HashTable.replace
let get : t -> key -> value = HashTable.find
