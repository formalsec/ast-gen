open Structures

type edge_info = 
  | Property of property
  | Version  of property
  | Dependency

type node = {
  _to  : location;
  edge : edge_info;
} 

type t = (node list) HashTable.t
let empty : t = HashTable.create 100


(* ----------- F U N C T I O N S -----------*)
let alloc (_ : t) (id : int) : location = loc_prefix ^ (Int.to_string id)

let addNode (graph : t) (loc : location) : unit =
  HashTable.add graph loc []

let addEdge (graph : t) (_to : location) (from : location) (info : edge_info) : unit = 
  let node = {_to = _to; edge = info} in 
  let edges = HashTable.find graph from in 
  HashTable.replace graph from (node :: edges)

let addDepEdge (graph : t) (_to : location) (from : location) : unit = 
  addEdge graph _to from (Dependency)