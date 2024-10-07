open Graphjs_base
open Graphjs_ast
open Structures
open Grammar

(* =============== S T R U C T U R E S =============== *)
module Node = struct
  type _type =
    | Object of string
    | Call of string
    | Function of Functions.Id.t * string list
    | Parameter of string
    | Return
    | TaintSource
    | TaintSink of string
    | Literal

  type t =
    { id : int
    ; loc : Location.t
    ; _type : _type
    }

  let id_count : int ref = ref 0

  let gen_id () : int =
    id_count := !id_count + 1;
    !id_count

  let create (_type : _type) (loc : Location.t) : t =
    { id = gen_id (); loc; _type }

  let equal (node : t) (node' : t) =
    let same_type =
      match (node._type, node'._type) with
      | (Object x, Object x')
      | (Call x, Call x')
      | (TaintSink x, TaintSink x')
      | (Parameter x, Parameter x') ->
        String.equal x x'
      | (Function (x, _), Function (x', _)) -> Functions.Id.equal x x'
      | (Return, Return) | (TaintSource, TaintSource) | (Literal, Literal) ->
        true
      | _ -> false in

    node.id = node'.id && same_type

  let label (node : t) =
    match node._type with
    | Object obj -> obj
    | Call func -> func ^ "()"
    | Function (func, _) -> func.name
    | Parameter param -> param
    | TaintSource -> "taint source"
    | TaintSink _ -> "taint sink"
    | Literal -> "literal value"
    | Return -> "RET_OBJ"

  (* get node information *)
  let get_id (node : t) : string = string_of_int node.id

  let get_name (node : t) : string =
    match node._type with
    | Object name -> name
    | _ -> failwith "[ERROR] Node doesn't have a name"

  let get_type (node : t) : string =
    match node._type with
    | TaintSource -> "TAINT_SOURCE"
    | TaintSink _ -> "TAINT_SINK"
    | Call _ -> "PDG_CALL"
    | Function _ -> "PDG_FUNC"
    | Return -> "PDG_RETURN"
    | _ -> "PDG_OBJECT"

  let get_subtype (_ : t) : string = ""

  let get_id_name (node : t) : string =
    match node._type with
    | Object name -> name
    | Call func -> func ^ "()"
    | Function (id, _) -> id.name
    | Parameter name -> name
    | TaintSource -> "TAINT_SOURCE"
    | TaintSink sink -> sink
    | _ -> ""

  let get_raw (_ : t) : string = ""
  let get_structure (_ : t) : string = ""
  let get_location (node : t) : string = Location.to_string node.loc
  let get_code (_ : t) : string = ""
  let get_label : t -> string = get_type

  (* other functions over nodes *)
  let get_func_id (node : t) : Functions.Id.t option =
    match node._type with Function (id, _) -> Some id | _ -> None

  let get_func_params (node : t) : string list =
    match node._type with
    | Function (_, params) -> params
    | _ ->
      failwith
        "[ERROR] Tryed to get params from a node that isnt a function \
         definition one"
end

module Edge = struct
  type _type =
    | Property of property option
    | Version of property option
    | Dependency
    | Argument of string (* argument index *) * string (* argument name *)
    | Parameter of string
    | RefCall
    | Call
    | Return
    | Taint
    | Sink of string

  type t =
    { _to : location
    ; _type : _type
    }

  let is_property (edge : t) =
    match edge._type with Property _ -> true | _ -> false

  let is_version (edge : t) =
    match edge._type with Version _ -> true | _ -> false

  let is_param (edge : t) =
    match edge._type with Parameter _ -> true | _ -> false

  let get_property (edge : t) : property option =
    match edge._type with
    | Property p | Version p -> p
    | _ -> failwith "[ERROR] Edge is neither a property edge nor a version edge"

  let _type_to_int (t : _type) : int =
    match t with
    | Property _ -> 0
    | Version _ -> 1
    | Dependency -> 2
    | Argument _ -> 3
    | Parameter _ -> 4
    | Call -> 5
    | Return -> 6
    | Taint -> 7
    | Sink _ -> 8
    | RefCall -> 9

  let compare_type (t : _type) (t' : _type) : int =
    match (Int.compare (_type_to_int t) (_type_to_int t'), t, t') with
    | (0, Property x, Property x') | (0, Version x, Version x') ->
      Option.compare String.compare x x'
    | (0, Argument (_, x), Argument (_, x'))
    | (0, Parameter x, Parameter x')
    | (0, Sink x, Sink x') ->
      String.compare x x'
    | (c, _, _) -> c

  let compare (edge : t) (edge' : t) : int =
    match String.compare edge._to edge'._to with
    | 0 -> compare_type edge._type edge'._type
    | c -> c

  let label (edge : t) : string =
    match edge._type with
    | Property prop -> Option.apply (fun prop -> "P(" ^ prop ^ ")") ~default:"P(*)" prop
    | Version prop -> Option.apply (fun prop -> "V(" ^ prop ^ ")") ~default:"V(*)" prop
    | Dependency -> "D"
    | Argument (_, id) -> "ARG(" ^ id ^ ")"
    | Parameter pos -> "param " ^ pos
    | RefCall -> "call"
    | Call -> "CG"
    | Return -> "RET"
    | Taint -> "TAINT"
    | Sink sink_name -> "SINK (" ^ sink_name ^ ")"

  let to_string (edge : t) : string = " --" ^ label edge ^ "-> " ^ edge._to

  (* get edge information *)
  let get_to (edge : t) : location = edge._to

  let get_rel_label (edge : t) : string =
    match edge._type with
    | Parameter _ -> "REF"
    | RefCall -> "REF"
    | Call -> "CG"
    | Sink _ -> "SINK"
    | _ -> "PDG"

  let get_rel_type (edge : t) : string =
    match edge._type with
    | Property _ -> "SO"
    | Version _ -> "NV"
    | Dependency -> "DEP"
    | RefCall -> "call"
    | Call -> "CG"
    | Taint -> "TAINT"
    | Sink _ -> "SINK"
    | Parameter _ -> "param"
    | Argument _ -> "ARG"
    | Return -> "RET"

  let get_id_name (edge : t) : string =
    match edge._type with
    | Property name | Version name -> Option.value name ~default:"*"
    | Argument (_, name) -> name
    | Sink name -> name
    | _ -> ""

  let get_arg_i (edge : t) : string =
    match edge._type with (* | Argument (i, _) -> i *)
    | _ -> ""

  let get_par_i (edge : t) : string =
    match edge._type with Parameter i -> i | _ -> ""

  let get_stm_i (_ : t) : string = ""
  let get_elm_i (_ : t) : string = ""
  let get_exp_i (_ : t) : string = ""
  let get_met_i (_ : t) : string = ""
  let get_src_obj (_ : t) : string = ""
  let get_dep_of_prop (_ : t) : string = "false"
end

module EdgeSet = struct
  module Set' = Set.Make (Edge)
  include Set'

  let map_list (f : Set'.elt -> 'a) (set : Set'.t) : 'a list =
    List.map f (Set'.elements set)

  let find_pred (f : Set'.elt -> bool) (set : Set'.t) : Set'.elt =
    List.find f (Set'.elements set)

  let get_to (set : Set'.t) : location list =
    map_list (fun edge -> edge._to) set
end

type t =
  { edges : (string, EdgeSet.t) Hashtbl.t
  ; nodes : (string, Node.t) Hashtbl.t
  ; register : unit -> unit
  }

(* =============== F U N C T I O N S =============== *)

(* ------- S T R U C T U R E   F U N C T I O N S ------- *)

(* > EDGES FUNCTIONS : *)
let iter_edges (f : location -> Edge.t -> unit) (graph : t) =
  Hashtbl.iter (fun loc edges -> EdgeSet.iter (f loc) edges) graph.edges

let fold_edges (f : location -> EdgeSet.t -> 'acc -> 'acc) (graph : t) :
    'acc -> 'acc =
  Hashtbl.fold f graph.edges

let find_edges_opt (graph : t) : location -> EdgeSet.t option =
  Hashtbl.find_opt graph.edges

let find_edges (graph : t) : location -> EdgeSet.t = Hashtbl.find graph.edges
let mem_edges (graph : t) : location -> bool = Hashtbl.mem graph.edges

let num_edges (graph : t) : int =
  Hashtbl.fold (fun _ edges acc -> acc + EdgeSet.cardinal edges) graph.edges 0

let replace_edges (graph : t) (location : location) (edges : EdgeSet.t) : unit =
  let old_edges = find_edges_opt graph location in
  Option.apply_lazy
    (fun old_edges ->
      if not (EdgeSet.subset edges old_edges) then graph.register () )
        ~default:(lazy (graph.register ()))
    old_edges;
  Hashtbl.replace graph.edges location edges

let rec print (graph : t) : unit =
  iter_edges print_edge graph;
  print_string "\n"

and print_edge (from : location) (edge : Edge.t) : unit =
  print_string (from ^ Edge.to_string edge ^ "\n")

(* > NODE FUNCTIONS : *)
let iter_nodes (f : location -> Node.t -> unit) (graph : t) =
  Hashtbl.iter f graph.nodes

let find_node_opt' : (string, Node.t) Hashtbl.t -> location -> Node.t option =
  Hashtbl.find_opt

let find_node_opt (graph : t) : location -> Node.t option =
  find_node_opt' graph.nodes

let find_node (graph : t) : location -> Node.t = Hashtbl.find graph.nodes
let num_nodes (graph : t) : int = Hashtbl.length graph.nodes

let replace_node (graph : t) (location : location) (node : Node.t) =
  let old_node = find_node_opt graph location in
  Option.apply_lazy
    (fun old_node -> if not (Node.equal old_node node) then graph.register ())
      ~default:(lazy (graph.register ()))
    old_node;
  Hashtbl.replace graph.nodes location node

let get_node_id (graph : t) (loc : location) : string =
  let node = find_node graph loc in
  string_of_int node.id

let get_node_name (graph : t) (loc : location) : string =
  let node = find_node graph loc in
  Node.get_name node

(* > GRAPH FUNCTIONS : *)
let copy (graph : t) : t =
  { graph with
    edges = Hashtbl.copy graph.edges
  ; nodes = Hashtbl.copy graph.nodes
  }

let iter (f : location -> EdgeSet.t -> Node.t option -> unit) (graph : t) =
  Hashtbl.iter
    (fun loc edges ->
      let node = find_node_opt graph loc in
      f loc edges node )
    graph.edges

(* ------- A U X I L I A R Y   F U N C T I O N S -------*)
let get_edges (graph : t) (origin : location) : EdgeSet.t =
  Option.value (find_edges_opt graph origin) ~default:EdgeSet.empty

let is_version_edge (_to : location) (edge : Edge.t) : bool =
  Edge.is_version edge && Edge.get_to edge = _to

let get_parent_version (graph : t) (location : location) :
    (location * property option) list =
  fold_edges
    (fun from edges acc ->
      let version_edges = EdgeSet.filter (is_version_edge location) edges in
      let result =
        EdgeSet.map_list
          (fun edge -> (from, Edge.get_property edge))
          version_edges in
      acc @ result )
    graph []

let is_property_edge (property : property option) (edge : Edge.t) : bool =
  Edge.is_property edge && Edge.get_property edge = property

let has_property (graph : t) (location : location) (property : property option)
    : bool =
  let edges = get_edges graph location in
  EdgeSet.exists (is_property_edge property) edges

let get_properties (graph : t) (location : location) :
    (location * property option) list =
  let edges = get_edges graph location in
  let prop_edges = EdgeSet.filter Edge.is_property edges in
  EdgeSet.map_list
    (fun edge -> (Edge.get_to edge, Edge.get_property edge))
    prop_edges

let get_property (graph : t) (location : location) (property : property option)
    : location =
  let edges = get_edges graph location in
  Edge.get_to (EdgeSet.find_pred (is_property_edge property) edges)

let get_params (graph : t) (location : location) : EdgeSet.t =
  let edges = get_edges graph location in
  let params = EdgeSet.filter Edge.is_param edges in
  params

(* ------- M A I N   F U N C T I O N S -------*)
let lub (graph : t) (graph' : t) : unit =
  (* least upper bound *)
  iter
    (fun from edges' node' ->
      let edges = get_edges graph from in
      replace_edges graph from (EdgeSet.union edges edges');

      (* also update node info *)
      let node = find_node_opt graph from in
      if Option.is_none node then Option.iter (replace_node graph from) node' )
    graph'

let alloc (_ : t) (id : int) : location = loc_obj_prefix ^ Int.to_string id

let alloc_tsink (_ : t) (id : int) : location =
  loc_sink_prefix ^ Int.to_string id

let alloc_param : t -> location =
  let id : int ref = ref 0 in
  let alloc (_ : t) : location =
    id := !id + 1;
    loc_par_prefix ^ string_of_int !id in
  alloc

let alloc_function (_ : t) (id : int) : location =
  loc_fun_prefix ^ Int.to_string id

let orig (graph : t) (l : location) : LocationSet.t =
  let rec orig' (to_process : location list) (visited : location list)
      (acc : LocationSet.t) =
    match to_process with
    | [] -> acc
    | l :: rest ->
      if not (List.mem l visited) then
        let (parents, _) = List.split (get_parent_version graph l) in
        let visited' = l :: visited in
        if parents = [] then orig' rest visited' (LocationSet.add l acc)
        else orig' (parents @ rest) visited' acc
      else orig' rest visited acc in
  orig' [ l ] [] LocationSet.empty

let lookup (graph : t) (loc : location) (property : property) : LocationSet.t =
  let rec lookup' (graph : t) (to_process : location list)
      (visited : location list) (properties : property list)
      (result : LocationSet.t) (property : property option) : LocationSet.t =
    match to_process with
    | [] -> result
    | location :: ls ->
      let result = ref result in
      let to_process = ref ls in
      let visited = ref visited in
      let seen_properties = ref properties in

      let properties = get_properties graph location in
      let (known, unknown) = List.partition Fun.(Option.is_some << snd) properties in

      (* Direct Lookup - Unknown Property *)
      let (unknown, _) = List.split unknown in
      result := LocationSet.union !result (LocationSet.of_list unknown);

      (* Direct Lookup - Known Property *)
      if Option.is_some property && has_property graph location property then
        let l' = get_property graph location property in
        result := LocationSet.add l' !result
      else (
        (* Direct Lookup - Known Property *)
        if Option.is_none property then (
          let known =
            List.filter
            Fun.(not << flip List.mem !seen_properties << Option.get << snd)
              known in
          let (locations, properties) = List.split known in
          result := LocationSet.union !result (LocationSet.of_list locations);
          seen_properties := !seen_properties @ List.map Option.get properties );

        (* Indirect Lookup - Known and Unknown version *)
        let origins = get_parent_version graph location in
        List.iter
          (fun origin ->
            match origin with
            | (l_p, (Some _ as vproperty)) ->
              if (not (List.mem l_p !visited)) && vproperty != property then
                to_process := l_p :: !to_process;
              visited := l_p :: !visited
            | (l_p, None) ->
              if not (List.mem l_p !visited) then
                to_process := l_p :: !to_process;
              visited := l_p :: !visited )
          origins );

      lookup' graph !to_process !visited !seen_properties !result property in

  let property = if property = "*" then None else Some property in
  lookup' graph [ loc ] [] [] LocationSet.empty property

let get_static_properties (graph : t) (loc : location) : property list =
  let rec get_static_properties' (graph : t) (to_process : location list)
      (visited : location list) (result : property list) : property list =
    match to_process with
    | [] -> result
    | location :: ls ->
      let properties = get_properties graph location in
      let static = List.filter_map Fun.(id << snd) properties in

      let parents = get_parent_version graph location in
      let parents =
        List.filter_map
          (fun (parent, _) ->
            if not (List.exists (( = ) parent) visited) then Some parent
            else None )
          parents in
      get_static_properties' graph (ls @ parents) visited (result @ static)
  in

  get_static_properties' graph [ loc ] [] []

(* ------- G R A P H   M A N I P U L A T I O N ------- *)
let add_node (graph : t) (loc : location) (node : Node.t) : unit =
  replace_node graph loc node;
  replace_edges graph loc (get_edges graph loc)

let add_obj_node (graph : t) (abs_loc : location) (name : string)
    (crt_loc : Location.t) : unit =
  let node : Node.t = Node.create (Object name) crt_loc in
  add_node graph abs_loc node

let add_call_node (graph : t) (abs_loc : location) (func : string)
    (crt_loc : Location.t) : unit =
  let node : Node.t = Node.create (Call func) crt_loc in
  add_node graph abs_loc node

let add_func_node (graph : t) (abs_loc : location) (func_id : Functions.Id.t)
    (params : string list) (crt_loc : Location.t) : unit =
  let node : Node.t = Node.create (Function (func_id, params)) crt_loc in
  add_node graph abs_loc node

let add_param_node (graph : t) (abs_loc : location) (param : string)
    (crt_loc : Location.t) : unit =
  let node : Node.t = Node.create (Parameter param) crt_loc in
  add_node graph abs_loc node

let add_return_node (graph : t) (abs_loc : location) (crt_loc : Location.t) :
    unit =
  let node : Node.t = Node.create Return crt_loc in
  add_node graph abs_loc node

let add_literal_node (graph : t) : unit =
  let node : Node.t = Node.create Literal (Location.empty ()) in
  add_node graph loc_literal node

let add_taint_source (graph : t) : unit =
  let node : Node.t = Node.create TaintSource (Location.empty ()) in
  add_node graph loc_taint_source node

let add_taint_sink (graph : t) (abs_loc : location) (sink : string)
    (crt_loc : Location.t) : unit =
  let node : Node.t = Node.create (TaintSink sink) crt_loc in
  add_node graph abs_loc node

let empty (register : unit -> unit) : t =
  let graph =
    { edges = Hashtbl.create 100; nodes = Hashtbl.create 50; register } in
  graph

let add_edge (graph : t) (edge : Edge.t) (_to : location) (from : location) :
    unit =
  let edges = get_edges graph from in
  replace_edges graph from (EdgeSet.add edge edges)

let add_dep_edge (graph : t) (from : location) (_to : location) : unit =
  let edge = { Edge._to; _type = Dependency } in
  add_edge graph edge _to from

let add_prop_edge (graph : t) (from : location) (_to : location)
    (property : property option) : unit =
  let edge = { Edge._to; _type = Property property } in
  add_edge graph edge _to from

let add_version_edge (graph : t) (from : location) (_to : location)
    (property : property option) : unit =
  let edge = { Edge._to; _type = Version property } in
  add_edge graph edge _to from

let add_arg_edge (graph : t) (from : location) (_to : location) (index : string)
    (identifier : string) : unit =
  let edge = { Edge._to; _type = Argument (index, identifier) } in
  add_edge graph edge _to from

let add_param_edge (graph : t) (from : location) (_to : location)
    (index : string) : unit =
  let edge = { Edge._to; _type = Parameter index } in
  add_edge graph edge _to from

let add_call_edge (graph : t) (from : location) (_to : location) : unit =
  let edge = { Edge._to; _type = Call } in
  add_edge graph edge _to from

let add_ref_call_edge (graph : t) (from : location) (_to : location) : unit =
  let edge = { Edge._to; _type = RefCall } in
  add_edge graph edge _to from

let add_ret_edge (graph : t) (from : location) (_to : location) : unit =
  let edge = { Edge._to; _type = Return } in
  add_edge graph edge _to from

let add_taint_edge (graph : t) (from : location) (_to : location) : unit =
  let edge = { Edge._to; _type = Taint } in
  add_edge graph edge _to from

let add_sink_edge (graph : t) (from : location) (_to : location) (sink : string)
    : unit =
  let edge = { Edge._to; _type = Sink sink } in
  add_edge graph edge _to from

let get_func_node (graph : t) (func_id : Functions.Id.t) : location option =
  let res : location option ref = ref None in
  iter_nodes
    (fun location node ->
      let func_id' = Node.get_func_id node in
      let is_curr_func =
        Option.apply (Functions.Id.equal func_id) ~default:false func_id' in
      if is_curr_func then res := Some location )
    graph;
  !res

let get_param_locations (graph : t) (func_id : Functions.Id.t) : Store.t =
  let func_loc = get_func_node graph func_id in
  let params = get_params graph (Option.get func_loc) in

  let store = Store.empty () in
  EdgeSet.iter
    (fun edge ->
      let location = Edge.get_to edge in
      let param_name = Node.label (find_node graph location) in
      Store.update' store param_name (LocationSet.singleton location) )
    params;

  store

let get_arg_locations (graph : t) (callee : location) : (string * location) list
    =
  let result = ref [] in
  iter_edges
    (fun loc edge ->
      match edge._type with
      | Argument (index, _) ->
        if edge._to = callee then result := (index, loc) :: !result
      | _ -> () )
    graph;

  !result

let exists_node (graph : t) (location : location) : bool =
  Option.is_some (find_node_opt graph location)

let has_external_function (graph : t) (func_node : location) : bool =
  exists_node graph func_node

let get_function (graph : t) (func_node : location) : t =
  let rec get_function' (graph : t) (to_visit : LocationSet.t)
      (visited : LocationSet.t) (func_graph : t) : t =
    if not (LocationSet.is_empty to_visit) then (
      let (visiting, to_visit') = LocationSet.pop to_visit in
      let node = find_node graph visiting in
      let edges = get_edges graph visiting in
      Hashtbl.replace func_graph.nodes visiting node;
      Hashtbl.replace func_graph.edges visiting edges;

      let tos = LocationSet.from_list (EdgeSet.get_to edges) in
      get_function' graph
        (LocationSet.diff (LocationSet.union to_visit' tos) visited)
        (LocationSet.add visiting visited)
        func_graph )
    else func_graph in

  let func_graph = empty (fun () -> ()) in
  if exists_node graph func_node then
    get_function' graph
      (LocationSet.singleton func_node)
      LocationSet.empty func_graph
  else
    failwith
      ("[ERROR] Graph does not encode function with location " ^ func_node)

let update_arg_edges (graph : t) (call_node : location)
    (parameters : string list) : unit =
  Hashtbl.filter_map_inplace
    (fun _ edges ->
      let new_edges =
        EdgeSet.map
          (fun edge ->
            (* check if it is a argument edge pointing to the call_node*)
            match (edge._to = call_node, edge._type) with
            | (true, Argument (index, _)) ->
              let param_name =
                Option.value
                  ( if index = "this" then Some index
                    else List.nth_opt parameters (int_of_string index) )
                  ~default:"undefined" in
              { edge with _type = Argument (index, param_name) }
            | _ -> edge )
          edges in

      Some new_edges )
    graph.edges

let add_external_func (graph : t) (func_graph : t) (call_node : location)
    (function_node : location) : unit =
  (* add nodes *)
  iter_nodes (fun loc node -> Hashtbl.replace graph.nodes loc node) func_graph;

  (* add edges *)
  iter (fun loc edges _ -> Hashtbl.replace graph.edges loc edges) func_graph;

  (* update argument edges *)
  let f_node = find_node graph function_node in
  let params = Node.get_func_params f_node in
  update_arg_edges graph call_node params

let staticAddProperty (graph : t) (_L : LocationSet.t) (property : property)
    (id : int) (add_node : location -> unit) : unit =
  LocationSet.apply
    (fun l ->
      let l_Os = orig graph l in

      LocationSet.apply
        (fun l_o ->
          if
            not (has_property graph l_o (Some property))
            (* Add Known Property - Non-Existing *)
          then (
            let l_i = alloc graph id in
            add_node l_i;
            add_prop_edge graph l_o l_i (Some property) ) )
        l_Os )
    _L

let dynamicAddProperty (graph : t) (_L_obj : LocationSet.t)
    (_L_prop : LocationSet.t) (id : int) (add_node : location -> unit) : unit =
  LocationSet.apply
    (fun l ->
      let l_Os = orig graph l in

      LocationSet.apply
        (fun l_o ->
          if has_property graph l_o None then
            (* Add Unknown Property - Existing*)
            let l' = get_property graph l_o None in
            LocationSet.apply (Fun.flip (add_dep_edge graph) l') _L_prop
          else
            (* Add Unknown Property - Non-Existing*)
            let l_i = alloc graph id in
            add_node l_i;
            add_prop_edge graph l_o l_i None;
            LocationSet.apply (Fun.flip (add_dep_edge graph) l_i) _L_prop )
        l_Os )
    _L_obj

let sNVStrongUpdate (graph : t) (store : Store.t) (l : location)
    (property : property) (id : int) (add_node : location -> unit) :
    LocationSet.t =
  let l_i = alloc graph id in
  add_version_edge graph l l_i (Some property);
  Store.strong_update store l l_i;

  (* return *)
  add_node l_i;
  LocationSet.singleton l_i

let sNVWeakUpdate (graph : t) (store : Store.t) (_L : LocationSet.t)
    (property : property) (id : int) (add_node : location -> unit) :
    LocationSet.t =
  let l_i = alloc graph id in
  add_node l_i;

  LocationSet.apply
    (fun l ->
      (* add version edges *)
      add_version_edge graph l l_i (Some property);

      (* store update *)
      let _new = LocationSet.of_list [ l; l_i ] in
      Store.weak_update store l _new )
    _L;
  Store.update' store (get_node_name graph l_i) (LocationSet.singleton l_i);

  (* return *)
  LocationSet.singleton l_i

let staticNewVersion (graph : t) (store : Store.t) (_L : LocationSet.t)
    (property : property) (id : int) (add_node : location -> unit) :
    LocationSet.t =
  if LocationSet.cardinal _L = 1 then
    sNVStrongUpdate graph store (LocationSet.min_elt _L) property id add_node
  else sNVWeakUpdate graph store _L property id add_node

let dNVStrongUpdate (graph : t) (store : Store.t) (l_obj : location)
    (_L_prop : LocationSet.t) (id : int) (add_node : location -> unit) :
    LocationSet.t =
  let l_i = alloc graph id in
  add_version_edge graph l_obj l_i None;

  (* add dependency edges *)
  LocationSet.apply (fun l_prop -> add_dep_edge graph l_prop l_i) _L_prop;

  Store.strong_update store l_obj l_i;

  (* return *)
  add_node l_i;
  LocationSet.singleton l_i

let dNVWeakUpdate (graph : t) (store : Store.t) (_L_obj : LocationSet.t)
    (_L_prop : LocationSet.t) (id : int) (add_node : location -> unit) :
    LocationSet.t =
  let l_i = alloc graph id in
  add_node l_i;

  LocationSet.apply
    (fun l ->
      (* add version edges *)
      add_version_edge graph l l_i None;

      (* store update *)
      let _new = LocationSet.of_list [ l; l_i ] in
      Store.weak_update store l _new )
    _L_obj;
  Store.update' store (get_node_name graph l_i) (LocationSet.singleton l_i);

  (* add dependency edges *)
  LocationSet.apply (fun l_prop -> add_dep_edge graph l_prop l_i) _L_prop;

  (* return *)
  LocationSet.singleton l_i

let dynamicNewVersion (graph : t) (store : Store.t) (_L_obj : LocationSet.t)
    (_L_prop : LocationSet.t) (id : int) (add_node : location -> unit) :
    LocationSet.t =
  if LocationSet.cardinal _L_obj = 1 then
    dNVStrongUpdate graph store (LocationSet.min_elt _L_obj) _L_prop id add_node
  else dNVWeakUpdate graph store _L_obj _L_prop id add_node
