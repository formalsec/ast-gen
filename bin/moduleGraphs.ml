open Auxiliary.Structures
module Graph = Mdg.Graph' 

type key = string
type value = Graph.t 
type t = value HashTable.t

let empty () : t = HashTable.create 10
let add : t -> key -> value -> unit = HashTable.replace
let get : t -> key -> value = HashTable.find