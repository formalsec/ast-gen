open Structures
open Auxiliary.Functions
open Auxiliary.Structures
open Ast.Grammar

(* =============== S T R U C T U R E S =============== *)
module Node = struct            
  type t = 
    | Object
    | Function of string
    | Parameter of string 

  let equals (node : t) (node' : t) = match (node, node') with
    | Object, Object -> true
    | Function x, Function x'
    | Parameter x, Parameter x' -> String.equal x x'
    | _ -> false
    
  let label (node : t) = match node with
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

    let is_property (edge : t) = match edge._type with Property _ -> true | _ -> false
    let is_version (edge : t) = match edge._type with Version _ -> true | _ -> false
    let get_property (edge : t) : property option = match edge._type with Property p | Version p -> p | _ -> failwith "edge is neither a property edge nor a version edge"
    let get_to (edge : t) : location = edge._to

    let _type_to_int (t : _type) : int =
      match t with
      | Property _  -> 0   | Version  _  -> 1
      | Dependency  -> 2   | Argument _  -> 3
      | Parameter _ -> 4   | Call        -> 5


    let compare_type (t : _type) (t' : _type) : int =
      match Int.compare (_type_to_int t) (_type_to_int t'), t, t' with
      | 0, Property x, Property x'
      | 0, Version  x, Version  x' -> Option.compare (String.compare) x x'
      | 0, Argument  x, Argument  x'
      | 0, Parameter x, Parameter x' -> String.compare x x'
      | c, _, _ -> c
    
    let compare (edge : t) (edge' : t) : int = 
      match String.compare edge._to edge'._to with
      | 0 -> compare_type edge._type edge'._type
      | c -> c

    let label (edge : t) : string = 
      match edge._type with 
        | Property prop -> map_default (fun prop -> "P(" ^ prop ^ ")") "P(*)" prop
        | Version prop -> map_default (fun prop -> "V(" ^ prop ^ ")") "V(*)" prop
        | Dependency -> "D" 
        | Argument id -> "ARG(" ^ id ^ ")"
        | Parameter pos -> "param " ^ pos
        | Call -> "CG"
    
    let to_string (edge : t) : string = " --" ^ label edge ^ "-> " ^ edge._to 
end

module EdgeSet = Set.Make(Edge)
type t = {
  edges : EdgeSet.t HashTable.t;
  nodes : Node.t HashTable.t;
  register : unit -> unit;
}

(* =============== F U N C T I O N S =============== *)

(* ------- S T R U C T U R E   F U N C T I O N S ------- *)

(* > EDGES FUNCTIONS : *)
let iter_edges (f : location -> EdgeSet.t -> unit) (graph : t) = HashTable.iter f graph.edges
let fold_edges (f : location -> EdgeSet.t -> 'acc -> 'acc) (graph : t) : 'acc -> 'acc = HashTable.fold f graph.edges
let find_edges_opt (graph : t) : location -> EdgeSet.t option = HashTable.find_opt graph.edges
let find_edges (graph : t) : location -> EdgeSet.t = HashTable.find graph.edges
let mem_edges (graph : t) : location -> bool =  HashTable.mem graph.edges

let replace_edges (graph : t) (location : location) (edges : EdgeSet.t) : unit = 
  let old_edges = find_edges_opt graph location in
  map_default_lazy (fun old_edges -> if not (EdgeSet.subset edges old_edges) then (graph.register ()) ) (lazy (graph.register ())) old_edges;
  HashTable.replace graph.edges location edges

let rec print (graph : t) : unit = 
  iter_edges print_edge graph;
  print_string "\n";

and print_edge (from : location) (edges : EdgeSet.t) : unit = 
  EdgeSet.iter (fun edge -> print_string (from ^ (Edge.to_string edge) ^ "\n")) edges

(* > NODE FUNCTIONS : *)
let iter_nodes (f : location -> Node.t -> unit) (graph : t) = HashTable.iter f graph.nodes

let find_node_opt (graph : t) : location -> Node.t option = HashTable.find_opt graph.nodes

let replace_node (graph : t) (location : location) (node : Node.t) = 
  let old_node = find_node_opt graph location in
  map_default_lazy (fun old_node -> if not (Node.equals old_node node) then (graph.register ()) ) (lazy (graph.register ())) old_node;
  HashTable.replace graph.nodes location node

(* > GRAPH FUNCTIONS : *)
let copy (graph : t) : t = {graph with edges = HashTable.copy graph.edges; nodes = HashTable.copy graph.nodes}
let empty (register : unit -> unit) : t = {edges = HashTable.create 100; nodes = HashTable.create 50; register = register}
let iter (f : location -> EdgeSet.t -> Node.t option -> unit) (graph : t) = iter_edges (fun loc edges -> let node = find_node_opt graph loc in f loc edges node) graph


(* ------- A U X I L I A R Y   F U N C T I O N S -------*)
let get_edges (graph : t) (origin : location) : EdgeSet.t = 
  map_default identity EdgeSet.empty (find_edges_opt graph origin)

let is_version_edge (_to : location) (edge : Edge.t) : bool = Edge.is_version edge && Edge.get_to edge = _to

let has_version (graph : t) (location : location) (_to : location) : bool =
  let edges = get_edges graph location in 
  EdgeSet.exists (is_version_edge _to) edges 

let get_parent_version (graph : t) (location : location) : location option * property option =
  fold_edges (fun from edges acc ->
    if has_version graph from location 
      then let edge = List.find (is_version_edge location) (EdgeSet.elements edges) in 
           (Some from, Edge.get_property edge)
      else acc
  ) graph (None, None)

let is_property_edge (property : property option) (edge : Edge.t) : bool = Edge.is_property edge && (Edge.get_property edge) = property

let has_property (graph : t) (location : location) (property : property option) : bool =
  let edges = get_edges graph location in 
  EdgeSet.exists (is_property_edge property) edges

let get_property (graph : t) (location : location) (property : property option) : location =
  let edges = get_edges graph location in 
  Edge.get_to (List.find (is_property_edge property) (EdgeSet.elements edges))


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

let rec orig (graph : t) (l : location) : location = 
  let parent, _ = get_parent_version graph l in 
  map_default (orig graph) (l) parent

        
let rec lookup (graph : t) (location : location) (property : property) : LocationSet.t =
  let property = if property = "*" then None else Some property in
  lookup' graph [location] LocationSet.empty property

and lookup' (graph : t) (to_process : location list) (result : LocationSet.t) (property : property option) : LocationSet.t =
  match to_process with
  | [] -> result
  | location::ls -> 
    let result = ref result in 
    let to_process = ref ls in 

    (* Direct Lookup - Known Property *)
    if (Option.is_some property && has_property graph location property) then 
      let l' = get_property graph location property in
      result := LocationSet.add l' !result;

    else (
      (* Direct Lookup - Unknown Property *)
      if (has_property graph location None) then 
        let l' = get_property graph location None in 
        result := LocationSet.add l' !result
      else (); 
      
      (* Indirect Lookup - Known and Unknown version *)
      match get_parent_version graph location with
        | Some lp, ((Some _) as vproperty) -> if vproperty != property then 
                                                to_process := lp:: !to_process
        | Some lp, None                    -> to_process := lp :: !to_process
        | _ -> ();
    );

    lookup' graph !to_process !result property



(* ------- G R A P H   M A N I P U L A T I O N ------- *)
let addNode (graph : t) (loc : location) (node : Node.t) : unit =
  replace_node  graph loc node;
  replace_edges graph loc (get_edges graph loc)

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

    if not (has_property graph l_o (Some property)) 
      (* Add Known Property - Non-Existing *)
      then let l_i = alloc graph id in 
           addPropEdge graph l_o l_i (Some property)
  ) _L 

let dynamicAddProperty (graph : t) (_L_obj : LocationSet.t) (_L_prop : LocationSet.t) (id : int) : unit =
  LocationSet.iter (fun l -> 
    let l_o = orig graph l in 

    if has_property graph l None then 
      (* Add Unknown Property - Existing*)
      let l' = get_property graph l None in 
      LocationSet.iter (flip (addDepEdge graph) l') _L_prop
    else (
      (* Add Unknown Property - Non-Existing*)
      let l_i = alloc graph id in 
      addPropEdge graph l_o l_i None;
      LocationSet.iter (flip (addDepEdge graph) l_i) _L_prop 
    )
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
  