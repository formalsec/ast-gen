open Structures
open Auxiliary.Functions
open Auxiliary.Structures
open Ast.Grammar

(* =============== S T R U C T U R E S =============== *)
module Node = struct            
  type t = 
    | Object of string
    | Function of string
    | Parameter of string 

  let equals (node : t) (node' : t) = match (node, node') with
    | Object x, Object x'
    | Function x, Function x'
    | Parameter x, Parameter x' -> String.equal x x'
    | _ -> false
    
  let label (node : t) = match node with
    | Object obj -> obj 
    | Function func -> func
    | Parameter param -> param
  
end

module Edge = struct
    type _type = 
      | Property of property option
      | Version  of property option
      | Dependency
      | Argument of string   
      | Parameter of string 
      | Call
      | Return 

    type t = {
        _to  : location;
        _type : _type;
      }

    let is_property (edge : t) = match edge._type with Property _ -> true | _ -> false
    let is_version  (edge : t) = match edge._type with Version _ -> true | _ -> false
    let is_param    (edge : t) = match edge._type with Parameter _ -> true | _ -> false
    let get_property (edge : t) : property option = match edge._type with Property p | Version p -> p | _ -> failwith "edge is neither a property edge nor a version edge"
    let get_to (edge : t) : location = edge._to

    let _type_to_int (t : _type) : int =
      match t with
      | Property _  -> 0   | Version  _  -> 1
      | Dependency  -> 2   | Argument _  -> 3
      | Parameter _ -> 4   | Call        -> 5
      | Return      -> 6


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
        | Return -> "RET"
    
    let to_string (edge : t) : string = " --" ^ label edge ^ "-> " ^ edge._to 
end

module EdgeSet = struct
  module  Set' = Set.Make(Edge)
  include Set'

  let map_list (f : Set'.elt -> 'a) (set : Set'.t) : 'a list = 
    List.map f (Set'.elements set)

  let find_pred (f : Set'.elt -> bool) (set : Set'.t) : Set'.elt = 
    List.find f (Set'.elements set)
end

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

let find_node_opt' : Node.t HashTable.t -> location -> Node.t option = HashTable.find_opt
let find_node_opt (graph : t) : location -> Node.t option = find_node_opt' graph.nodes

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

let get_parent_version (graph : t) (location : location) : (location * property option) list =
  fold_edges (fun from edges acc ->
    let version_edges = EdgeSet.filter (is_version_edge location) edges in 
    let result = EdgeSet.map_list (fun edge -> (from, Edge.get_property edge)) version_edges in 
    acc @ result
  ) graph []

let is_property_edge (property : property option) (edge : Edge.t) : bool = Edge.is_property edge && (Edge.get_property edge) = property

let has_property (graph : t) (location : location) (property : property option) : bool =
  let edges = get_edges graph location in 
  EdgeSet.exists (is_property_edge property) edges

let get_properties (graph : t) (location : location) : (location * property option) list = 
  let edges = get_edges graph location in 
  let prop_edges = EdgeSet.filter Edge.is_property edges in 
  EdgeSet.map_list (fun edge -> (Edge.get_to edge, Edge.get_property edge)) prop_edges

let get_property (graph : t) (location : location) (property : property option) : location =
  let edges = get_edges graph location in 
  Edge.get_to (EdgeSet.find_pred (is_property_edge property) edges)

let get_params (graph : t) (location : location) : location list = 
  let edges = get_edges graph location in 
  let params = EdgeSet.filter (Edge.is_param) edges in 
  EdgeSet.map_list (Edge.get_to) params

(* ------- M A I N   F U N C T I O N S -------*)
let lub (graph : t) (graph' : t) : unit = 
  (* least upper bound *)
  iter_edges (fun from edges' -> 
    let edges = get_edges graph from in 
    replace_edges graph from (EdgeSet.union edges edges');
  ) graph'

let alloc (_ : t) (id : int) : location = 
  loc_obj_prefix ^ (Int.to_string id)

let alloc_param : t -> location =
  let id : int ref = ref 0 in
  let alloc (_ : t) : location = 
    id := !id + 1;
    loc_par_prefix ^ (string_of_int !id) 
  in
  alloc

let alloc_function : t -> location =
  let id : int ref = ref 0 in
  let alloc (_ : t) : location = 
    id := !id + 1;
    loc_fun_prefix ^ (string_of_int !id) 
  in
  alloc


let orig (graph : t) (l : location) : LocationSet.t = 
  let rec orig' (to_process : location list) (visited : location list) (acc : LocationSet.t) =
    match to_process with
      | [] -> acc 
      | l :: rest ->
        if not (List.mem l visited) then
          let parents, _ = List.split (get_parent_version graph l) in
          let visited' = l :: visited in 
          if parents = [] 
            then orig' rest visited' (LocationSet.add l acc)
            else orig' (parents @ rest) visited' acc
        
        else orig' rest visited acc
  in
  orig' [l] [] LocationSet.empty

    
let lookup (graph : t) (loc : location) (property : property) : LocationSet.t =
  let rec lookup' (graph : t) (to_process : location list) (visited : location list) (properties : property list) (result : LocationSet.t) (property : property option) : LocationSet.t =
    match to_process with
    | [] -> result
    | location::ls -> 
      let result = ref result in 
      let to_process = ref ls in 
      let visited = ref visited in 
      let seen_properties = ref properties in 
      
      let properties = get_properties graph location in 
      let known, unknown = List.partition (Option.is_some << snd) properties in 

      (* Direct Lookup - Unknown Property *)
      let unknown, _ = List.split unknown in 
      result := LocationSet.union !result (LocationSet.of_list unknown);

      (* Direct Lookup - Known Property *)
      if (Option.is_some property && has_property graph location property) then 
        let l' = get_property graph location property in
        result := LocationSet.add l' !result;

      else (
        (* Direct Lookup - Known Property *)
        if (Option.is_none property) then (
          let known = List.filter (not << (flip List.mem !seen_properties) << Option.get << snd) known in 
          let locations, properties = List.split known in 
          result := LocationSet.union !result (LocationSet.of_list locations);
          seen_properties := !seen_properties @ List.map Option.get properties);

        (* Indirect Lookup - Known and Unknown version *)
        let origins = get_parent_version graph location in
        List.iter (fun origin -> 
          match origin with
          | l_p, ((Some _) as vproperty) -> if not (List.mem l_p !visited) && vproperty != property then 
                                                to_process := l_p :: !to_process;
                                                visited := l_p :: !visited
          | l_p, None                    -> if not (List.mem l_p !visited) then
                                                to_process := l_p :: !to_process;
                                                visited := l_p :: !visited
        ) origins

      );

      lookup' graph !to_process !visited !seen_properties !result property
  in 

  let property = if property = "*" then None else Some property in
  lookup' graph [loc] [] [] LocationSet.empty property


(* ------- G R A P H   M A N I P U L A T I O N ------- *)
let add_node (graph : t) (loc : location) (node : Node.t) : unit =
  replace_node  graph loc node;
  replace_edges graph loc (get_edges graph loc)

let add_obj_node (graph : t) (loc : location) (name : string) : unit =
  let node : Node.t = Object name in 
  add_node graph loc node

let add_func_node (graph : t) (loc : location) (func_name) : unit =
  let node : Node.t = Function func_name in 
  add_node graph loc node
  
let add_param_node (graph : t) (loc : location) (param : string) : unit =
  let node : Node.t = Parameter param in 
  add_node graph loc node


let add_edge (graph : t) (edge : Edge.t) (_to : location) (from : location) : unit = 
  let edges = get_edges graph from in 
  replace_edges graph from (EdgeSet.add edge edges)

let add_dep_edge (graph : t) (from : location) (_to : location) : unit = 
  let edge = {Edge._to = _to; _type = Dependency} in 
  add_edge graph edge _to from

let add_prop_edge (graph : t) (from : location) (_to : location) (property : property option) : unit = 
  let edge = {Edge._to = _to; _type = Property property} in 
  add_edge graph edge _to from

let add_version_edge (graph : t) (from : location) (_to : location) (property : property option) : unit =
  let edge = {Edge._to = _to; _type = Version property} in 
  add_edge graph edge _to from

let add_arg_edge (graph : t) (from : location) (_to : location) (identifier : string) : unit = 
  let edge = {Edge._to = _to; _type = Argument identifier} in 
  add_edge graph edge _to from

let add_param_edge (graph : t) (from : location) (_to : location) (index : string) : unit = 
  let edge = {Edge._to = _to; _type = Parameter index} in 
  add_edge graph edge _to from

let add_call_edge (graph : t) (from : location) (_to : location) : unit = 
  let edge = {Edge._to = _to; _type = Call} in 
  add_edge graph edge _to from

let add_ret_edge (graph : t) (from : location) (_to : location) : unit = 
  let edge = {Edge._to = _to; _type = Return} in 
  add_edge graph edge _to from

let get_func_node (graph : t) (func_name : string) : location option = 
  let res : location option ref = ref None in 
  iter_nodes ( fun location node ->
    match node with 
      | Function func_name' -> if func_name = func_name' then res := Some location
      | _ -> ()
  ) graph;
  !res

let get_param_locations (graph : t) (func_name : string) : location list = 
  let func_loc = get_func_node graph func_name in 
  (* remove this from the parameter list *)
  List.tl (get_params graph (Option.get func_loc))
  

let staticAddProperty (graph : t) (_L : LocationSet.t) (property : property) (id : int) (name : string) : unit =
  LocationSet.iter (fun l -> 
    let l_Os = orig graph l in 

    LocationSet.iter (fun l_o ->
      if not (has_property graph l_o (Some property)) 
        (* Add Known Property - Non-Existing *)
        then (let l_i = alloc graph id in 
              add_obj_node graph l_i name;
              add_prop_edge graph l_o l_i (Some property))
    ) l_Os
  ) _L 

let dynamicAddProperty (graph : t) (_L_obj : LocationSet.t) (_L_prop : LocationSet.t) (id : int) (name : string): unit =
  LocationSet.iter (fun l -> 
    let l_Os = orig graph l in
    
    LocationSet.iter (fun l_o ->
      if has_property graph l_o None then 
        (* Add Unknown Property - Existing*)
        let l' = get_property graph l_o None in 
        LocationSet.iter (flip (add_dep_edge graph) l') _L_prop
      else (
        (* Add Unknown Property - Non-Existing*)
        let l_i = alloc graph id in 
        add_obj_node graph l_i name;
        add_prop_edge graph l_o l_i None;
        LocationSet.iter (flip (add_dep_edge graph) l_i) _L_prop 
      )
    ) l_Os
    
  ) _L_obj  


let sNVStrongUpdate (graph : t) (store : Store.t) (_object : string) (l : location) (property : property) (id : int) : LocationSet.t = 
  let l_i = alloc graph id in 
  add_version_edge graph l l_i (Some property);
  Store.strong_update store l l_i;

  (* return *)
  add_obj_node graph l_i _object;
  LocationSet.singleton l_i

let sNVWeakUpdate (graph : t) (store : Store.t) (_object : string) (_L : LocationSet.t) (property : property) (id : int) : LocationSet.t = 
  let l_i = alloc graph id in 
  LocationSet.iter ( fun l ->
    (* add version edges *)
    add_version_edge graph l l_i (Some property);
    
    (* store update *)
    let _new = LocationSet.of_list [l; l_i] in
    Store.weak_update store l _new
  ) _L;
  Store.update' store _object (LocationSet.singleton l_i);

  (* return *)
  add_obj_node graph l_i _object;
  LocationSet.singleton l_i

let staticNewVersion (graph : t) (store : Store.t) (_object : m Expression.t) (_L : LocationSet.t) (property : property) (id : int) : LocationSet.t = 
  let obj_id = Expression.get_id _object in 
  if LocationSet.cardinal _L = 1 
    then sNVStrongUpdate graph store obj_id (LocationSet.min_elt _L) property id
    else sNVWeakUpdate graph store obj_id _L property id


let dNVStrongUpdate (graph : t) (store : Store.t) (_object : string) (l_obj : location) (_L_prop : LocationSet.t) (id : int) : LocationSet.t = 
  let l_i = alloc graph id in 
  add_version_edge graph l_obj l_i None;

  (* add dependency edges *)
  LocationSet.iter (fun l_prop ->
    add_dep_edge graph l_prop l_i 
  ) _L_prop;

  Store.strong_update store l_obj l_i;

  (* return *)
  add_obj_node graph l_i _object;
  LocationSet.singleton l_i

let dNVWeakUpdate (graph : t) (store : Store.t) (_object : string) (_L_obj : LocationSet.t) (_L_prop : LocationSet.t) (id : int) : LocationSet.t = 
  let l_i = alloc graph id in 
  LocationSet.iter ( fun l -> 
    (* add version edges *)
    add_version_edge graph l l_i None;

    (* store update *)
    let _new = LocationSet.of_list [l; l_i] in
    Store.weak_update store l _new
  ) _L_obj;
  Store.update' store _object (LocationSet.singleton l_i);

  (* add dependency edges *)
  LocationSet.iter (fun l_prop ->
    add_dep_edge graph l_prop l_i 
  ) _L_prop;
  
  (* return *)
  add_obj_node graph l_i _object;
  LocationSet.singleton l_i

let dynamicNewVersion (graph : t) (store : Store.t) (_object : m Expression.t) (_L_obj : LocationSet.t) (_L_prop : LocationSet.t) (id : int) : LocationSet.t = 
  let obj_id = Expression.get_id _object in 
  if LocationSet.cardinal _L_obj = 1 
    then dNVStrongUpdate graph store obj_id (LocationSet.min_elt _L_obj) _L_prop id
    else dNVWeakUpdate graph store obj_id _L_obj _L_prop id
  