open Structures
open Auxiliary.Functions

type t = EdgeSet.t HashTable.t
let empty : t = HashTable.create 100


(* =============== F U N C T I O N S =============== *)
let lub (graph : t) (graph' : t) : unit = 
  (* least upper bound *)
  HashTable.iter (fun from edges' -> 
    let edges = map_default identity EdgeSet.empty (HashTable.find_opt graph from) in 
    HashTable.replace graph from (EdgeSet.union edges edges');
  ) graph'

let alloc (_ : t) (id : int) : location = loc_prefix ^ (Int.to_string id)

let copy (graph : t) : t = HashTable.copy graph

let rec print (graph : t) : unit = 
  HashTable.iter print_edge graph;
  print_string "\n";

and print_edge (from : location) (edges : EdgeSet.t) : unit = 
  EdgeSet.iter (fun edge -> print_string (from ^ (Edge.to_string edge))) edges

(* ------- G R A P H   M A N I P U L A T I O N ------- *)
let addNode (graph : t) (loc : location) : unit =
  HashTable.add graph loc EdgeSet.empty

let addEdge (graph : t) (_to : location) (from : location) (info : Edge.info) : unit = 
  let edge = {Edge._to = _to; info = info} in 
  let edges = HashTable.find graph from in 
  HashTable.replace graph from (EdgeSet.add edge edges)

let addDepEdge (graph : t) (_to : location) (from : location) : unit = 
  addEdge graph _to from (Edge.Dependency)