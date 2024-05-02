open Structures
open Auxiliary.Functions

type t = EdgeSet.t HashTable.t
let empty : t = HashTable.create 100


(* =============== F U N C T I O N S =============== *)
 
let get_edges (graph : t) (origin : location) : EdgeSet.t = 
  map_default identity EdgeSet.empty (HashTable.find_opt graph origin)

let has_version_edge (_to' : location) ({_to; info} : Edge.t) : bool = 
  match info with
    | Version _ -> _to = _to'
    | _         -> false

let has_property_edge (property' : property option) ({_to; info} : Edge.t) : bool = 
  match info with
    | Property property -> property = property'
    | _                 -> false

let rec print (graph : t) : unit = 
  HashTable.iter print_edge graph;
  print_string "\n";

and print_edge (from : location) (edges : EdgeSet.t) : unit = 
  EdgeSet.iter (fun edge -> print_string (from ^ (Edge.to_string edge) ^ "\n")) edges


let copy (graph : t) : t = HashTable.copy graph


(* ------- M A I N   F U N C T I O N S -------*)
let lub (graph : t) (graph' : t) : unit = 
  (* least upper bound *)
  HashTable.iter (fun from edges' -> 
    let edges = get_edges graph from in 
    HashTable.replace graph from (EdgeSet.union edges edges');
  ) graph'

let alloc (_ : t) (id : int) : location = loc_prefix ^ (Int.to_string id)

(* TODO : test*)
let rec orig (graph : t) (l : location) : location = 
  HashTable.fold (fun l' edges acc ->
    if (EdgeSet.exists (has_version_edge l) edges) 
      then orig graph l'
      else acc
  ) graph l 


(* TODO *)
let lookup (graph : t) (l : location) (property : property) : location =
  let direct_edges = HashTable.find graph l in   

  if (EdgeSet.exists (has_property_edge (Some property)) direct_edges) then 
    (* Direct Lookup - Known Property *)
    (
    let {Edge._to; _} = EdgeSet.find_last (has_property_edge (Some property)) direct_edges in 
    _to)
  else if (EdgeSet.exists (has_property_edge None) direct_edges) then 
    (* Direct Lookup - Unknown Property *)
    (print_endline "yo";
    let {Edge._to; _} = EdgeSet.find_last (has_property_edge None) direct_edges in 
    _to)
  else 
    (* TODO : Indirect Lookup - Known Version and Indirect Lookup - Unknown Version *)
    "!TODO!"
  
  

(* ------- G R A P H   M A N I P U L A T I O N ------- *)
let addNode (graph : t) (loc : location) : unit =
  HashTable.add graph loc EdgeSet.empty

let addEdge (graph : t) (edge : Edge.t) (_to : location) (from : location) : unit = 
  let edges = get_edges graph from in 
  HashTable.replace graph from (EdgeSet.add edge edges)

let addDepEdge (graph : t) (_to : location) (from : location) : unit = 
  let edge = {Edge._to = _to; info = Dependency} in 
  addEdge graph edge _to from

let addPropEdge (graph : t) (from : location) (_to : location) (property : property option) : unit = 
  let edge = {Edge._to = _to; info = Property property} in 
  addEdge graph edge _to from

let staticAddProperty (graph : t) (_L : LocationSet.t) (property : property) (id : int) : unit =
  LocationSet.iter (fun l -> 
    let l_o = orig graph l in 

    let edges = get_edges graph l_o in  
    if not (EdgeSet.exists (has_property_edge (Some property)) edges) 
      then let l_i = alloc graph id in 
           addPropEdge graph l_o l_i (Some property)
  ) _L 
  