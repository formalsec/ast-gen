open Structures
open Auxiliary.Functions
open Normalizer.Structures

(* =============== S T R U C T U R E S =============== *)
module Node = struct
  type _type = 
    | Function of string  | Parameter of string 
    | Object              | None

  type t = {
    location : location;
    _type : _type;
  }

  let empty : t = {location = ""; _type = None}
  let to_string (node : t) : string = node.location
  let with_location (location : location) : t = {empty with location = location}

  (* functions requeired to be a key*)
  let equal (node : t) (node' : t) = String.equal node.location node'.location
  let hash (node : t) = Hashtbl.hash node.location
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
module GraphHT = Hashtbl.Make(Node)
type t = EdgeSet.t GraphHT.t

(* =============== F U N C T I O N S =============== *)

(* ------- S T R U C T U R E   F U N C T I O N S ------- *)
let iter' (f : location -> EdgeSet.t -> unit) (graph : t) = GraphHT.iter (fun node edges -> f node.location edges) graph
let iter : (Node.t -> EdgeSet.t -> unit) -> t -> unit = GraphHT.iter
let fold (f : location -> EdgeSet.t -> 'acc -> 'acc) (graph : t) (acc : 'acc) : 'acc = GraphHT.fold (fun node edges acc' -> f node.location edges acc') graph acc
let copy : t -> t = GraphHT.copy 
let empty : t = GraphHT.create 100
let find_opt (graph : t) (location : location) : EdgeSet.t option = GraphHT.find_opt graph (Node.with_location location)
let find (graph : t) (location : location) : EdgeSet.t = GraphHT.find graph (Node.with_location location)
let add : t -> Node.t -> EdgeSet.t -> unit = GraphHT.add
let mem (graph : t) (location : location) : bool =  GraphHT.mem graph (Node.with_location location)
let replace (graph : t) (location : location) (edges : EdgeSet.t) : unit = 
  GraphHT.filter_map_inplace (fun node' edges' -> if node'.location = location then Some edges else Some edges' ) graph;
  if not (mem graph location) then add graph {Node.empty with location = location} edges

let rec print (graph : t) : unit = 
  iter' print_edge graph;
  print_string "\n";

and print_edge (from : location) (edges : EdgeSet.t) : unit = 
  EdgeSet.iter (fun edge -> print_string (from ^ (Edge.to_string edge) ^ "\n")) edges



(* ------- A U X I L I A R Y   F U N C T I O N S -------*)
let get_edges (graph : t) (origin : location) : EdgeSet.t = 
  map_default identity EdgeSet.empty (find_opt graph origin)

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
let lub (register : unit -> unit) (graph : t) (graph' : t) : unit = 
  (* least upper bound *)
  iter' (fun from edges' -> 
    let edges = get_edges graph from in 
    if not (EdgeSet.subset edges' edges) then register ();
    replace graph from (EdgeSet.union edges edges');
  ) graph'

let alloc (_ : t) (id : int) : location = loc_obj_prefix ^ (Int.to_string id)

let alloc_param (_ : t) (param : string) = loc_par_prefix ^ param
let alloc_function (_ : t) (func : string) = loc_fun_prefix ^ func


(* TODO : test *)
let rec orig (graph : t) (l : location) : location = 
  fold (fun l' edges acc ->
    if (EdgeSet.exists (has_version_edge ~_to':(Some l)) edges) 
      then orig graph l'
      else acc
  ) graph l 

let find_version_edge_origin (graph : t) (_to : location) (property : property option) : bool * location =
  let _to = Some _to in 
  let property' : property option option = if Option.is_some property then None else Some None in 
  fold (fun from edges acc ->
    (* check if version edge exists and if its property is different than the one provided *)
    if (EdgeSet.exists (fun edge -> has_version_edge ~_to':_to ~property':property' edge && map_default ((!=) (Edge.get_property edge._type)) (true) property) edges)
      then true, from
      else acc
  ) graph (false, "!NOT FOUND!")

let rec lookup (graph : t) (l : location) (property : property) : location =
  let direct_edges = find graph l in  

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
let addNode (register : unit -> unit) (graph : t) (loc : location) : unit =
  if not (mem graph loc) || not (EdgeSet.is_empty (find graph loc)) then register ();
  
  let node : Node.t =  {location = loc; _type = Node.Object} in 
  add graph node EdgeSet.empty

let addFuncNode (_ : unit -> unit) (graph : t) (location : location) (func_name : string) : unit = 
  let node : Node.t =  {location = location; _type = Node.Function func_name} in 
  add graph node EdgeSet.empty

let addParamNode (_ : unit -> unit) (graph : t) (location : location) (param : string) : unit = 
  let node : Node.t =  {location = location; _type = Node.Parameter param} in 
  add graph node EdgeSet.empty

let addEdge (register : unit -> unit) (graph : t) (edge : Edge.t) (_to : location) (from : location) : unit = 
  let edges = get_edges graph from in 
  if not (EdgeSet.mem edge edges) then register ();
  replace graph from (EdgeSet.add edge edges)

let addDepEdge (register : unit -> unit) (graph : t) (from : location) (_to : location) : unit = 
  let edge = {Edge._to = _to; _type = Dependency} in 
  addEdge register graph edge _to from

let addPropEdge (register : unit -> unit) (graph : t) (from : location) (_to : location) (property : property option) : unit = 
  let edge = {Edge._to = _to; _type = Property property} in 
  addEdge register graph edge _to from

let addVersionEdge (register : unit -> unit) (graph : t) (from : location) (_to : location) (property : property option) : unit =
  let edge = {Edge._to = _to; _type = Version property} in 
  addEdge register graph edge _to from

let addArgEdge (register : unit -> unit) (graph : t) (from : location) (_to : location) (identifier : string) : unit = 
  let edge = {Edge._to = _to; _type = Argument identifier} in 
  addEdge register graph edge _to from

let addParamEdge (register : unit -> unit) (graph : t) (from : location) (_to : location) (index : string) : unit = 
  let edge = {Edge._to = _to; _type = Parameter index} in 
  addEdge register graph edge _to from

let addCallEdge (register : unit -> unit) (graph : t) (from : location) (_to : location) : unit = 
  let edge = {Edge._to = _to; _type = Call} in 
  addEdge register graph edge _to from

let getFuncNode (graph : t) (func : string) : location option = 
  let res : location option ref= ref None in 
  iter ( fun node _ ->
    match node with 
      | {location; _type=(Node.Function f)} -> if f = func then res := Some location
      | _ -> ()
  ) graph;
  !res



let staticAddProperty (register : unit -> unit) (graph : t) (_L : LocationSet.t) (property : property) (id : int) : unit =
  LocationSet.iter (fun l -> 
    let l_o = orig graph l in 

    let edges = get_edges graph l_o in  
    if not (EdgeSet.exists (has_property_edge (Some property)) edges) 
      then let l_i = alloc graph id in 
           addPropEdge register graph l_o l_i (Some property)
  ) _L 

let dynamicAddProperty (register : unit -> unit)  (graph : t) (_L_obj : LocationSet.t) (_L_prop : LocationSet.t) (id : int) : unit =
  LocationSet.iter (fun l -> 
    let l_o = orig graph l in 

    let edges = get_edges graph l_o in  
    if (EdgeSet.exists (has_property_edge None) edges) then 
      let {Edge._to; _} = List.find (has_property_edge None) (EdgeSet.elements edges) in
      LocationSet.iter (flip (addDepEdge register graph) _to) _L_prop
    else 
    ( let l_i = alloc graph id in 
      addPropEdge register graph l_o l_i None;
      LocationSet.iter (flip (addDepEdge register graph) l_i) _L_prop )

  ) _L_obj  


let sNVStrongUpdate (register : unit -> unit)  (graph : t) (store : Store.t) (l : location) (property : property) (id : int) : LocationSet.t = 
  let l_i = alloc graph id in 
  addVersionEdge register graph l l_i (Some property);
  Store.strong_update register store l l_i;

  (* return *)
  LocationSet.singleton l_i

let sNVWeakUpdate (register : unit -> unit)  (graph : t) (store : Store.t) (_object : string) (_L : LocationSet.t) (property : property) (id : int) : LocationSet.t = 
  let l_i = alloc graph id in 
  LocationSet.iter ( fun l ->
    (* add version edges *)
    addVersionEdge register graph l l_i (Some property);
    
    (* store update *)
    let _new = LocationSet.of_list [l; l_i] in
    Store.weak_update register store l _new
  ) _L;
  Store.update' register store _object (LocationSet.singleton l_i);

  (* return *)
  LocationSet.singleton l_i

let staticNewVersion (register : unit -> unit)  (graph : t) (store : Store.t) (_object : m Expression.t) (_L : LocationSet.t) (property : property) (id : int) : LocationSet.t = 
  if LocationSet.cardinal _L = 1 
    then sNVStrongUpdate register graph store (LocationSet.min_elt _L) property id
    else sNVWeakUpdate register graph store (get_expression_id _object) _L property id


let dNVStrongUpdate (register : unit -> unit) (graph : t) (store : Store.t) (l_obj : location) (_L_prop : LocationSet.t) (id : int) : LocationSet.t = 
  let l_i = alloc graph id in 
  addVersionEdge register graph l_obj l_i None;

  (* add dependency edges *)
  LocationSet.iter (fun l_prop ->
    addDepEdge register graph l_prop l_i 
  ) _L_prop;

  Store.strong_update register store l_obj l_i;

  (* return *)
  LocationSet.singleton l_i

let dNVWeakUpdate (register : unit -> unit)  (graph : t) (store : Store.t) (_object : string) (_L_obj : LocationSet.t) (_L_prop : LocationSet.t) (id : int) : LocationSet.t = 
  let l_i = alloc graph id in 
  LocationSet.iter ( fun l -> 
    (* add version edges *)
    addVersionEdge register graph l l_i None;

    (* store update *)
    let _new = LocationSet.of_list [l; l_i] in
    Store.weak_update register store l _new
  ) _L_obj;
  Store.update' register store _object (LocationSet.singleton l_i);


  (* add dependency edges *)
  LocationSet.iter (fun l_prop ->
    addDepEdge register graph l_prop l_i 
  ) _L_prop;
  
  (* return *)
  LocationSet.singleton l_i

let dynamicNewVersion (register : unit -> unit) (graph : t) (store : Store.t) (_object : m Expression.t) (_L_obj : LocationSet.t) (_L_prop : LocationSet.t) (id : int) : LocationSet.t = 
  if LocationSet.cardinal _L_obj = 1 
    then dNVStrongUpdate register graph store (LocationSet.min_elt _L_obj) _L_prop id
    else dNVWeakUpdate register graph store (get_expression_id _object) _L_obj _L_prop id
  