open Auxiliary.Structures
module ExportedObject = Mdg.ExportedObject 

type key = string
type value = ExportedObject.t 
type t = value HashTable.t

let empty () : t = HashTable.create 10
let add : t -> key -> value -> unit = HashTable.replace
let get_opt : t -> key -> value option = HashTable.find_opt
