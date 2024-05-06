open Structures
open Auxiliary.Functions
open Auxiliary.GraphJS

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

let get_expression_id (expr : m Expression.t) : string =
  match expr with 
    | _, Identifier {name; _} -> name
    | _, This _ -> "this"
    | _ -> failwith "expression cannot be converted into an id"

let rec print (graph : t) : unit = 
  HashTable.iter print_edge graph;
  print_string "\n";

and print_edge (from : location) (edges : EdgeSet.t) : unit = 
  EdgeSet.iter (fun edge -> print_string (from ^ (Edge.to_string edge) ^ "\n")) edges

let copy (graph : t) : t = HashTable.copy graph

let is_equal (graph : t) (graph' : t) : bool = 
  let result = ref true in
  if HashTable.length graph = HashTable.length graph'
    then (
        HashTable.iter ( fun key value -> 
        if !result then
          let value' = HashTable.find_opt graph' key in 
          if Option.is_some value'
            then result := EdgeSet.equal value (Option.get value')
            else result := false
        ) graph;
        !result
      )
    else false

(* ------- M A I N   F U N C T I O N S -------*)
let lub (graph : t) (graph' : t) : unit = 
  (* least upper bound *)
  HashTable.iter (fun from edges' -> 
    let edges = get_edges graph from in 
    HashTable.replace graph from (EdgeSet.union edges edges');
  ) graph'

let alloc (_ : t) (id : int) : location = loc_prefix ^ (Int.to_string id)

(* TODO : test *)
let rec orig (graph : t) (l : location) : location = 
  HashTable.fold (fun l' edges acc ->
    if (EdgeSet.exists (has_version_edge l) edges) 
      then orig graph l'
      else acc
  ) graph l 


let lookup (graph : t) (l : location) (property : property) : location =
  let direct_edges = HashTable.find graph l in   

  (* Direct Lookup - Known Property *)
  if (EdgeSet.exists (has_property_edge (Some property)) direct_edges) then 
    let {Edge._to; _} = EdgeSet.find_last (has_property_edge (Some property)) direct_edges in 
    _to

  (* Direct Lookup - Unknown Property *)
  else if (EdgeSet.exists (has_property_edge None) direct_edges) then 
    let {Edge._to; _} = EdgeSet.find_last (has_property_edge None) direct_edges in 
    _to

  (* TODO : Indirect Lookup - Known Version and Indirect Lookup - Unknown Version *)
  else 
    "!TODO!"

(* ------- G R A P H   M A N I P U L A T I O N ------- *)
let addNode (graph : t) (loc : location) : unit =
  HashTable.add graph loc EdgeSet.empty

let addEdge (graph : t) (edge : Edge.t) (_to : location) (from : location) : unit = 
  let edges = get_edges graph from in 
  HashTable.replace graph from (EdgeSet.add edge edges)

let addDepEdge (graph : t) (from : location) (_to : location) : unit = 
  let edge = {Edge._to = _to; info = Dependency} in 
  addEdge graph edge _to from

let addPropEdge (graph : t) (from : location) (_to : location) (property : property option) : unit = 
  let edge = {Edge._to = _to; info = Property property} in 
  addEdge graph edge _to from

let addVersionEdge (graph : t) (from : location) (_to : location) (property : property option) : unit =
  let edge = {Edge._to = _to; info = Version property} in 
  addEdge graph edge _to from

let staticAddProperty (graph : t) (_L : LocationSet.t) (property : property) (id : int) : unit =
  LocationSet.iter (fun l -> 
    let l_o = orig graph l in 

    let edges = get_edges graph l_o in  
    if not (EdgeSet.exists (has_property_edge (Some property)) edges) 
      then let l_i = alloc graph id in 
           addPropEdge graph l_o l_i (Some property)
  ) _L 

let dynamicAddProperty (graph : t) (_L_obj : LocationSet.t) (_L_prop : LocationSet.t) (id : int) : unit =
  LocationSet.iter (fun l -> 
    let l_o = orig graph l in 

    let edges = get_edges graph l_o in  
    if (EdgeSet.exists (has_property_edge None) edges) then 
      let {Edge._to; _} = EdgeSet.find_last (has_property_edge None) edges in
      LocationSet.iter (flip (addDepEdge graph) _to) _L_prop
    else 
    ( let l_i = alloc graph id in 
      addPropEdge graph l_o l_i None;
      LocationSet.iter (flip (addDepEdge graph) l_i) _L_prop )

  ) _L_obj  


let sNVStrongUpdate (graph : t) (store : Store.t) (l : location) (property : property) (id : int) : LocationSet.t = 
  let l_i = alloc graph id in 
  addVersionEdge graph l l_i (Some property);
  Store.strong_update store l l_i;

  (* return *)
  LocationSet.singleton l_i

let sNVWeakUpdate (graph : t) (store : Store.t) (_object : string) (_L : LocationSet.t) (property : property) (id : int) : LocationSet.t = 
  let l_i = alloc graph id in 
  LocationSet.iter ( fun l ->
    (* add version edges *)
    addVersionEdge graph l l_i (Some property);
    
    (* store update *)
    let _new = LocationSet.of_list [l; l_i] in
    Store.weak_update store l _new
  ) _L;
  Store.update' store _object (LocationSet.singleton l_i);

  (* return *)
  LocationSet.singleton l_i

let staticNewVersion (graph : t) (store : Store.t) (_object : m Expression.t) (_L : LocationSet.t) (property : property) (id : int) : LocationSet.t = 
  if LocationSet.cardinal _L = 1 
    then sNVStrongUpdate graph store (LocationSet.min_elt _L) property id
    else sNVWeakUpdate graph store (get_expression_id _object) _L property id


let dNVStrongUpdate (graph : t) (store : Store.t) (l_obj : location) (_L_prop : LocationSet.t) (id : int) : LocationSet.t = 
  let l_i = alloc graph id in 
  addVersionEdge graph l_obj l_i None;

  (* add dependency edges *)
  LocationSet.iter (fun l_prop ->
    addDepEdge graph l_prop l_i 
  ) _L_prop;

  Store.strong_update store l_obj l_i;

  (* return *)
  LocationSet.singleton l_i

let dNVWeakUpdate (graph : t) (store : Store.t) (_object : string) (_L_obj : LocationSet.t) (_L_prop : LocationSet.t) (id : int) : LocationSet.t = 
  let l_i = alloc graph id in 
  print_endline "yee";
  LocationSet.iter ( fun l -> 
    print_endline l;
    (* add version edges *)
    addVersionEdge graph l l_i None;

    (* store update *)
    let _new = LocationSet.of_list [l; l_i] in
    Store.weak_update store l _new
  ) _L_obj;
  Store.update' store _object (LocationSet.singleton l_i);


  (* add dependency edges *)
  LocationSet.iter (fun l_prop ->
    addDepEdge graph l_prop l_i 
  ) _L_prop;
  
  (* return *)
  LocationSet.singleton l_i

let dynamicNewVersion (graph : t) (store : Store.t) (_object : m Expression.t) (_L_obj : LocationSet.t) (_L_prop : LocationSet.t) (id : int) : LocationSet.t = 
  if LocationSet.cardinal _L_obj = 1 
    then dNVStrongUpdate graph store (LocationSet.min_elt _L_obj) _L_prop id
    else dNVWeakUpdate graph store (get_expression_id _object) _L_obj _L_prop id
  