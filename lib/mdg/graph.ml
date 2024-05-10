open Structures
open Auxiliary.Functions
open Auxiliary.Structures
open Normalizer.Structures

(* =============== S T R U C T U R E S =============== *)
module Node = struct            
  type t = 
    | Object
    | Function of string
    | Parameter of string 

  let to_string (node : t) = match node with
    | Object -> "(obj)"
    | Function func -> "(fun " ^ func ^ ")"
    | Parameter param -> "(param " ^ param ^ ")"
  
end

module Edge = struct
    type _type = 
      | Property of property option
      | Version  of property option
      | Dependency
      | Argument of string   
      | Parameter of string 
      | Call 

    type t = {
        _to  : location;
        _type : _type;
      } 

    let compare (edge : t) (edge' : t) : int = 
        Bool.to_int (edge._to = edge'._to && edge._type = edge'._type) - 1

    let to_string (edge : t) : string = 
        let edge_info = match edge._type with 
            | Property prop -> map_default (fun prop -> "P(" ^ prop ^ ")") "P(*)" prop
            | Version prop -> map_default (fun prop -> "V(" ^ prop ^ ")") "V(*)" prop
            | Dependency -> "D" 
            | Argument id -> "ARG(" ^ id ^ ")"
            | Parameter pos -> "param " ^ pos
            | Call -> "CG"
        in 
        " --" ^ edge_info ^ "-> " ^ edge._to 

    (* TODO : why not pass edge instead of only its type? operations must be done in the unit not on its parts *)
    let get_property (_type : _type) : property = 
        match _type with 
            | Property prop
            | Version prop -> map_default (identity) ("*") prop
            | _ -> failwith "provided edge has no property"

end

module EdgeSet = Set.Make(Edge)
type t = {
  edges : EdgeSet.t HashTable.t;
  nodes : Node.t HashTable.t;
  register : unit -> unit;
}

(* =============== F U N C T I O N S =============== *)

(* ------- S T R U C T U R E   F U N C T I O N S ------- *)
let copy (graph : t) : t = {graph with edges = HashTable.copy graph.edges; nodes = HashTable.copy graph.nodes}
let empty (register : unit -> unit) : t = {edges = HashTable.create 100; nodes = HashTable.create 100; register = register}

(* > EDGES FUNCTIONS : *)
let iter_edges (f : location -> EdgeSet.t -> unit) (graph : t) = HashTable.iter f graph.edges
let fold_edges (f : location -> EdgeSet.t -> 'acc -> 'acc) (graph : t) : 'acc -> 'acc = HashTable.fold f graph.edges
let find_edges_opt (graph : t) : location -> EdgeSet.t option = HashTable.find_opt graph.edges
let find_edges (graph : t) : location -> EdgeSet.t = HashTable.find graph.edges
let mem_edges (graph : t) : location -> bool =  HashTable.mem graph.edges
let replace_edges (graph : t) (location : location) (edges : EdgeSet.t) : unit = 
  let old_edges = find_edges_opt graph location in
  map_default (fun old_edges -> if not (EdgeSet.subset edges old_edges) then graph.register () ) (graph.register ()) old_edges;
  HashTable.replace graph.edges location edges

(* > NODE FUNCTIONS : *)
let iter_nodes (f : location -> Node.t -> unit) (graph : t) = HashTable.iter f graph.nodes

let find_node_opt (graph : t) : location -> Node.t option = HashTable.find_opt graph.nodes

let replace_node (graph : t) (location : location) (node : Node.t) = 
  let old_node = find_node_opt graph location in
  map_default (fun old_node -> if old_node != node then graph.register () ) (graph.register ()) old_node;
  HashTable.replace graph.nodes location node

let rec print (graph : t) : unit = 
  iter_edges print_edge graph;
  print_string "\n";

and print_edge (from : location) (edges : EdgeSet.t) : unit = 
  EdgeSet.iter (fun edge -> print_string (from ^ (Edge.to_string edge) ^ "\n")) edges

and print_node (location : location) (node : Node.t) : unit =
  print_endline (Node.to_string node ^ " " ^ location)



(* ------- A U X I L I A R Y   F U N C T I O N S -------*)
let get_edges (graph : t) (origin : location) : EdgeSet.t = 
  map_default identity EdgeSet.empty (find_edges_opt graph origin)

let has_version_edge ?(_to' : location option = None) ?(property' : property option option = None) (edge : Edge.t) : bool = 
  match edge._type with
    | Version property -> map_default ((=) edge._to) (true) _to' && map_default ((=) property) (true) property'
    | _         -> false

let has_property_edge (property' : property option) (edge : Edge.t) : bool = 
  match edge._type with
    | Property property -> property = property'
    | _                 -> false

let get_expression_id (expr : m Expression.t) : string =
  match expr with 
    | _, Identifier {name; _} -> name
    | _, This _ -> "this"
    | _ -> failwith "expression cannot be converted into an id"

(* ------- M A I N   F U N C T I O N S -------*)
let lub (graph : t) (graph' : t) : unit = 
  (* least upper bound *)
  iter_edges (fun from edges' -> 
    let edges = get_edges graph from in 
    replace_edges graph from (EdgeSet.union edges edges');
  ) graph'

let alloc (_ : t) (id : int) : location = loc_obj_prefix ^ (Int.to_string id)

let alloc_param (_ : t) (param : string) = loc_par_prefix ^ param
let alloc_function (_ : t) (func : string) = loc_fun_prefix ^ func


(* TODO : test *)
let rec orig (graph : t) (l : location) : location = 
  fold_edges (fun l' edges acc ->
    if (EdgeSet.exists (has_version_edge ~_to':(Some l)) edges) 
      then orig graph l'
      else acc
  ) graph l 

let find_version_edge_origin (graph : t) (_to : location) (property : property option) : bool * location =
  let _to = Some _to in 
  let property' : property option option = if Option.is_some property then None else Some None in 
  fold_edges (fun from edges acc ->
    (* check if version edge exists and if its property is different than the one provided *)
    if (EdgeSet.exists (fun edge -> has_version_edge ~_to':_to ~property':property' edge && map_default ((!=) (Edge.get_property edge._type)) (true) property) edges)
      then true, from
      else acc
  ) graph (false, "!NOT FOUND!")

let rec lookup (graph : t) (l : location) (property : property) : location =
  let direct_edges = find_edges graph l in  

  (* Direct Lookup - Known Property *)
  if (EdgeSet.exists (has_property_edge (Some property)) direct_edges) then 
    let {Edge._to; _} = List.find (has_property_edge (Some property)) (EdgeSet.elements direct_edges) in 
    _to

  (* Direct Lookup - Unknown Property *)
  else if (EdgeSet.exists (has_property_edge None) direct_edges) then 
    let {Edge._to; _} = List.find (has_property_edge None) (EdgeSet.elements direct_edges) in 
    _to

  (* Indirect Lookup - Known Version *)
  else let is_kv_lookup, l' = find_version_edge_origin graph l (Some property) in 
  if is_kv_lookup then lookup graph l' property
  
  (* Indirect Lookup - Unknown Version *)
  else let is_uv_lookup, l' = find_version_edge_origin graph l None in
  if is_uv_lookup then lookup graph l' property
  
  else failwith "property lookup failed, location doesn't posses such property"

(* ------- G R A P H   M A N I P U L A T I O N ------- *)
let addNode (graph : t) (loc : location) (node : Node.t) : unit =
  replace_node  graph loc node;
  replace_edges graph loc EdgeSet.empty

let addObjNode (graph : t) (loc : location) : unit =
  let node : Node.t = Object in 
  addNode graph loc node

let addFuncNode (graph : t) (loc : location) (func_name) : unit =
  let node : Node.t = Function func_name in 
  addNode graph loc node
  
let addParamNode (graph : t) (loc : location) (param : string) : unit =
  let node : Node.t = Parameter param in 
  addNode graph loc node


let addEdge (graph : t) (edge : Edge.t) (_to : location) (from : location) : unit = 
  let edges = get_edges graph from in 
  replace_edges graph from (EdgeSet.add edge edges)

let addDepEdge (graph : t) (from : location) (_to : location) : unit = 
  let edge = {Edge._to = _to; _type = Dependency} in 
  addEdge graph edge _to from

let addPropEdge (graph : t) (from : location) (_to : location) (property : property option) : unit = 
  let edge = {Edge._to = _to; _type = Property property} in 
  addEdge graph edge _to from

let addVersionEdge (graph : t) (from : location) (_to : location) (property : property option) : unit =
  let edge = {Edge._to = _to; _type = Version property} in 
  addEdge graph edge _to from

let addArgEdge (graph : t) (from : location) (_to : location) (identifier : string) : unit = 
  let edge = {Edge._to = _to; _type = Argument identifier} in 
  addEdge graph edge _to from

let addParamEdge (graph : t) (from : location) (_to : location) (index : string) : unit = 
  let edge = {Edge._to = _to; _type = Parameter index} in 
  addEdge graph edge _to from

let addCallEdge (graph : t) (from : location) (_to : location) : unit = 
  let edge = {Edge._to = _to; _type = Call} in 
  addEdge graph edge _to from

let getFuncNode (graph : t) (func_name : string) : location option = 
  let res : location option ref = ref None in 
  iter_nodes ( fun location node ->
    match node with 
      | Function func_name' -> if func_name = func_name' then res := Some location
      | _ -> ()
  ) graph;
  !res


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
      let {Edge._to; _} = List.find (has_property_edge None) (EdgeSet.elements edges) in
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
  LocationSet.iter ( fun l -> 
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
  