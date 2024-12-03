open Graphjs_base
open Graphjs_ast

type t =
  { nodes : (Location.t, Node.t) Hashtbl.t
  ; edges : (Location.t, Edge.Set.t) Hashtbl.t
  }

let create () : t =
  let nodes = Hashtbl.create Config.(!dflt_htbl_sz) in
  let edges = Hashtbl.create Config.(!dflt_htbl_sz) in
  { nodes; edges }

let copy (mdg : t) : t =
  let nodes = Hashtbl.copy mdg.nodes in
  let edges = Hashtbl.copy mdg.edges in
  { nodes; edges }

let node (mdg : t) (loc : Location.t) : Node.t =
  match Hashtbl.find_opt mdg.nodes loc with
  | None -> Log.fail "expecting node with location '%a' in mdg" Location.pp loc
  | Some node -> node

let edges (mdg : t) (loc : Location.t) : Edge.Set.t =
  match Hashtbl.find_opt mdg.edges loc with
  | None -> Log.fail "expecting edge from location '%a' in mdg" Location.pp loc
  | Some edges -> edges

let pp_node (mdg : t) (ppf : Fmt.t) (node : Node.t) : unit =
  let edges = edges mdg node.uid in
  if Edge.Set.is_empty edges then Fmt.fmt ppf "%a -" Node.pp node
  else Edge.Set.pp ppf edges

let pp (ppf : Fmt.t) (mdg : t) : unit =
  let nodes = Hashtbl.to_seq_values mdg.nodes |> List.of_seq in
  let nodes' = List.sort Node.compare nodes in
  Fmt.(pp_lst !>"@\n" (pp_node mdg)) ppf nodes'

let str (mdg : t) : string = Fmt.str "%a" pp mdg [@@inline]

let add_node (mdg : t) (node : Node.t) : unit =
  Hashtbl.replace mdg.nodes node.uid node;
  Hashtbl.replace mdg.edges node.uid Edge.Set.empty

let add_edge (mdg : t) (src : Node.t) (edge : Edge.t) : unit =
  let edges = edges mdg src.uid in
  Hashtbl.replace mdg.edges src.uid (Edge.Set.add edge edges)

let has_property (mdg : t) (node : Node.t) (prop : string option) : bool =
  edges mdg node.uid |> Edge.Set.exists (Edge.is_property ~prop:(Some prop))

let get_properties (mdg : t) (node : Node.t) : (Node.t * string option) list =
  edges mdg node.uid
  |> Edge.Set.elements
  |> List.filter Edge.is_property
  |> List.map (fun edge -> (Edge.tar edge, Edge.property edge))

let get_property (mdg : t) (node : Node.t) (prop : string option) :
    Node.t option =
  edges mdg node.uid
  |> Edge.Set.elements
  |> List.find_opt (Edge.is_property ~prop:(Some prop))
  |> Option.map Edge.tar

let get_versions (mdg : t) (node : Node.t) : (Node.t * string option) list =
  edges mdg node.uid
  |> Edge.Set.elements
  |> List.filter Edge.is_ref_parent
  |> List.map (fun edge -> (Edge.tar edge, Edge.property edge))

let get_parameters (mdg : t) (node : Node.t) : Node.t list =
  edges mdg node.uid
  |> Edge.Set.elements
  |> List.filter Edge.is_parameter
  |> List.map Edge.tar

let object_orig_versions (mdg : t) (node : Node.t) : Node.Set.t =
  let rec orig unprocessed visited result =
    match unprocessed with
    | [] -> result
    | node :: nodes when List.mem node visited -> orig nodes visited result
    | node :: nodes ->
      let (parents, _) = List.split (get_versions mdg node) in
      let visited' = node :: visited in
      if parents == [] then orig nodes visited' (Node.Set.add node result)
      else orig (parents @ nodes) visited' result in
  orig [ node ] [] Node.Set.empty

let object_lookup_property (mdg : t) (node : Node.t) (prop : string option) :
    Node.Set.t =
  let visited = ref [] in
  let seen_props = ref [] in
  let result = ref Node.Set.empty in
  let rec lookup = function
    | [] -> !result
    | node :: nodes ->
      let props = get_properties mdg node in
      let (known, unknown) = List.partition Fun.(Option.is_some << snd) props in
      let (unknown_prop_nodes, _) = List.split unknown in
      (* direct lookup - unknown object properties *)
      result := Node.Set.union !result (Node.Set.of_list unknown_prop_nodes);
      (* direct lookup - known object properties *)
      ( match (prop, get_property mdg node prop) with
      | (Some _, Some prop_node) -> result := Node.Set.add prop_node !result
      | (None, _) ->
        let check_unseen_prop_f (_, prop) = not (List.mem prop !seen_props) in
        let known' = List.map (fun (n, prop) -> (n, Option.get prop)) known in
        let unseen = List.filter check_unseen_prop_f known' in
        let (unseen_prop_nodes, unseen_prop_names) = List.split unseen in
        result := Node.Set.union !result (Node.Set.of_list unseen_prop_nodes);
        seen_props := !seen_props @ unseen_prop_names
      | _ -> () );
      (* indirect lookup *)
      let parents = get_versions mdg node in
      let unprocessed =
        List.fold_left
          (fun acc (parent, parent_prop) ->
            if not (List.mem parent !visited) then (
              visited := parent :: !visited;
              if prop != parent_prop then parent :: acc else [] )
            else [] )
          nodes parents in
      lookup unprocessed in
  lookup [ node ]

let lub (mdg1 : t) (mdg2 : t) : unit =
  Fun.flip Hashtbl.iter mdg2.edges @@ fun loc edges_2 ->
  let node_2 = node mdg2 loc in
  let node_1 = Hashtbl.find_opt mdg1.nodes loc in
  let edges_1 = Hashtbl.find_opt mdg1.edges loc in
  let edges_1' = Option.value ~default:Edge.Set.empty edges_1 in
  if Option.is_none node_1 then Hashtbl.replace mdg1.nodes loc node_2;
  Hashtbl.replace mdg1.edges loc (Edge.Set.union edges_1' edges_2)

(*


s



   type t = {
        edges : EdgeSet.t HashTable.t;
        nodes : Node.t HashTable.t;
        callers : (string, Node.t list) Hashtbl.t;
        returners : (string, Node.t list) Hashtbl.t;
        sinks : NodeSet.t ref;
        register : unit -> unit;
      }

      (* =============== F U N C T I O N S =============== *)

      (* ------- S T R U C T U R E   F U N C T I O N S ------- *)

      (* > EDGES FUNCTIONS : *)
      let iter_edges (f : location -> Edge.t -> unit) (graph : t) = HashTable.iter (fun loc edges -> EdgeSet.iter (f loc) edges) graph.edges
      let find_edges_opt (graph : t) : location -> EdgeSet.t option = HashTable.find_opt graph.edges
      let find_edges (graph : t) : location -> EdgeSet.t = HashTable.find graph.edges
      let mem_edges (graph : t) : location -> bool =  HashTable.mem graph.edges
      let num_edges (graph : t) : int = HashTable.fold (fun _ edges acc -> acc + EdgeSet.cardinal edges) graph.edges 0

      let replace_edges (graph : t) (location : location) (edges : EdgeSet.t) : unit =
        let old_edges = find_edges_opt graph location in
        map_default_lazy (fun old_edges -> if not (EdgeSet.subset edges old_edges) then (graph.register ()) ) (lazy (graph.register ())) old_edges;
        HashTable.replace graph.edges location edges

      let rec print (graph : t) : unit =
        iter_edges print_edge graph;
        print_string "\n";

      and print_edge (from : location) (edge : Edge.t) : unit =
        print_string (from ^ (Edge.to_string edge) ^ "\n")

      (* > NODE FUNCTIONS : *)
      let iter_nodes (f : location -> Node.t -> unit) (graph : t) = HashTable.iter f graph.nodes

      let find_node_opt' : Node.t HashTable.t -> location -> Node.t option = HashTable.find_opt
      let find_node_opt (graph : t) : location -> Node.t option = find_node_opt' graph.nodes
      let find_node (graph : t) : location -> Node.t = HashTable.find graph.nodes
      let num_nodes (graph : t) : int = HashTable.length graph.nodes

      let replace_node (graph : t) (location : location) (node : Node.t) =
        let old_node = find_node_opt graph location in
        map_default_lazy (fun old_node -> if not (Node.equal old_node node) then (graph.register ()) ) (lazy (graph.register ())) old_node;
        HashTable.replace graph.nodes location node

      let get_node_id (graph : t) (loc : location) : string =
        let node = find_node graph loc in
        string_of_int (node.id)

      let get_node_name (graph : t) (loc : location) : string =
        let node = find_node graph loc in
        Node.get_name node


      let get_callers_old (graph: t) (name: string) =
      match Hashtbl.find graph.callers name with
      | exception Not_found -> []
      | vs -> vs

      let get_callers (graph: t) (loc: string) =
        let l_nodes = HashTable.to_seq_keys graph.nodes |> List.of_seq in
        let all_edges = List.map (fun l_node -> l_node, (find_edges graph l_node |> EdgeSet.filter (fun e -> e._type = Call && String.equal e._to loc))) l_nodes in
        all_edges |> List.filter (fun (_, edges) -> EdgeSet.cardinal edges > 0) |> List.map (fun (l_node, _) -> find_node graph l_node)


      (* ------- A U X I L I A R Y   F U N C T I O N S -------*)

      let get_edges (graph : t) (origin : location) : EdgeSet.t =
        Option.value (find_edges_opt graph origin) ~default:EdgeSet.empty

      let is_version_edge (_to : location) (edge : Edge.t) : bool = Edge.is_version edge && Edge.get_to edge = _to




      let get_versions (graph : t) (location : location) : (location * property option) list =
        let edges = get_edges graph location in
        let version_edges = EdgeSet.filter Edge.is_version edges in
        EdgeSet.map_list (fun edge -> (Edge.get_to edge, Edge.get_property edge)) version_edges



      let get_params (graph : t) (location : location) : EdgeSet.t  =
        let edges = get_edges graph location in
        let params = EdgeSet.filter (Edge.is_param) edges in
        params

      (* ------- C A L L   N O D E S ------- *)
      let register_call_node (graph : t) (func_name : string) (node : Node.t) : unit =
        let callers = Option.value (Hashtbl.find_opt graph.callers func_name) ~default:[] in
        Hashtbl.replace graph.callers func_name (node :: callers)

      let register_call_nodes (graph: t) (func_name : string) (nodes : Node.t list) : unit =
        let callers = Option.value (Hashtbl.find_opt graph.callers func_name) ~default:[] in
        Hashtbl.replace graph.callers func_name (nodes @ callers)

      (* ------- M A I N   F U N C T I O N S -------*)

      let alloc (_ : t) (id : int) : location =
        loc_obj_prefix ^ (Int.to_string id)

      let alloc_tsink (_ : t) (id : int) : location =
        loc_sink_prefix ^ (Int.to_string id)



      let alloc_function (_ : t) (id : int) : location =
        loc_fun_prefix ^ (Int.to_string id)


      let get_static_properties (graph : t) (loc : location) : property list =
        let rec get_static_properties' (graph : t) (to_process : location list) (visited : location list) (result : property list) : property list =
          match to_process with
            | [] -> result
            | location::ls ->
              let properties = get_properties graph location in
              let static = List.filter_map (identity << snd) properties in

              let parents = get_parent_version graph location in
              let parents = List.filter_map (fun (parent, _) -> if not (List.exists ((=) parent) visited) then Some parent else None) parents in
              get_static_properties' graph (ls @ parents) visited (result @ static)
        in

        get_static_properties' graph [loc] [] []

      let get_all_property_nodes (graph: t) (loc: location): Node.t list =
        let rec get_all_property_nodes' graph unprocessed visited result =
          match unprocessed with
            | [] -> List.map (find_node graph) result
            | l :: ls when List.mem l visited ->  get_all_property_nodes' graph ls visited result
            | l :: ls ->
              (* Format.printf "debug analysing -> %s@." l;  *)
              let l_props = get_properties graph l |> List.map fst in
              (* Format.printf "debug l_props -> %s@." (String.concat ", " l_props); *)
              let parents = get_parent_version graph l in
              let parents = List.filter_map (fun (parent, _) -> if not (List.exists ((=) parent) visited) then Some parent else None) parents in
              (* Format.printf "debug parents -> %s@\n@." (String.concat ", " parents); *)
              get_all_property_nodes' graph (parents @ l_props @ ls) (l :: visited) (l :: result)
        in
        get_all_property_nodes' graph [ loc ] [] []

      (* ------- G R A P H   M A N I P U L A T I O N ------- *)
      let add_node (graph : t) (loc : location) (node : Node.t) : unit =
        replace_node  graph loc node;
        replace_edges graph loc (get_edges graph loc)

      let add_obj_node (graph : t) (curr_func : location option) (abs_loc : location) (name : string) (code_loc : Location.t): unit =
        let node : Node.t = Node.create (Object name) abs_loc code_loc curr_func in
        add_node graph abs_loc node

      let add_call_node (graph : t) (curr_func : location option) (abs_loc : location) (func : string) (code_loc : Location.t) : Node.t =
        let node : Node.t = Node.create (Call func) abs_loc code_loc curr_func in
        add_node graph abs_loc node;
        node

      let add_func_node (graph : t) (curr_func : location option) (abs_loc : location) (func_id : Functions.Id.t) (params : string list) (code_loc : Location.t): unit =
        let node : Node.t = Node.create (Function (func_id, params)) abs_loc code_loc curr_func in
        add_node graph abs_loc node

      let add_param_node (graph : t) (curr_func : location option) (abs_loc : location) (param : string) (code_loc : Location.t) : unit =
        let node : Node.t = Node.create (Parameter param) abs_loc code_loc curr_func in
        add_node graph abs_loc node

      let add_return_node (graph : t) (curr_func : location option) (abs_loc : location) (code_loc : Location.t) : unit =
        let node : Node.t = Node.create Return abs_loc code_loc curr_func in
        add_node graph abs_loc node



      let add_taint_sink (graph : t) (curr_func : location option) (abs_loc : location) (vuln_type : string) (sink : string) (code_loc : Location.t): unit =
        let node : Node.t = Node.create (TaintSink (sink, vuln_type)) abs_loc code_loc curr_func in
        graph.sinks := NodeSet.add node !(graph.sinks);
        add_node graph abs_loc node

      let empty (register : unit -> unit) : t =
        let graph = {edges = HashTable.create 100; nodes = HashTable.create 50; callers = Hashtbl.create 50; returners = Hashtbl.create 50; sinks = ref NodeSet.empty; register = register} in
        graph


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

      let add_arg_edge (graph : t) (from : location) (_to : location) (index : int) (identifier : string) : unit =
        let edge = {Edge._to = _to; _type = Argument (index, identifier)} in
        add_edge graph edge _to from

      let add_param_edge (graph : t) (from : location) (_to : location) (index : int) : unit =
        let edge = {Edge._to = _to; _type = Parameter index} in
        add_edge graph edge _to from

      let add_call_edge (graph : t) (from : location) (_to : location) : unit =
        let edge = {Edge._to = _to; _type = Call} in
        add_edge graph edge _to from

      let add_ref_call_edge (graph : t) (from : location) (_to : location) : unit =
        let edge = {Edge._to = _to; _type= RefCall } in
        add_edge graph edge _to from

      let add_ret_edge (graph : t) (from : location) (_to : location) : unit =
        let edge = {Edge._to = _to; _type = Return} in
        add_edge graph edge _to from

      let add_taint_edge (graph : t) (from : location) (_to : location) : unit =
        let edge = {Edge._to = _to; _type = Taint} in
        add_edge graph edge _to from

      let add_sink_edge (graph : t) (from : location) (_to : location) (sink : string): unit =
        let edge = {Edge._to = _to; _type = Sink sink} in
        add_edge graph edge _to from

      let update_func_def (graph : t) (location : location) (new_func : location option) : unit =
        let node = find_node graph location in
        if Option.is_none node.func then (
          HashTable.replace graph.nodes location {node with func = new_func}
        )

      let get_func_node (graph : t) (func_id : Functions.Id.t) : location option =
        let res : location option ref = ref None in
        iter_nodes ( fun location node ->
          let func_id' = Node.get_func_id node in
          let is_curr_func = map_default (Functions.Id.equal func_id) false func_id' in
          if is_curr_func then
            res := Some location
        ) graph;
        !res

      let get_param_locations (graph : t) (func_id : Functions.Id.t) : Store.t =
        let func_loc = get_func_node graph func_id in
        let params = get_params graph (Option.get func_loc) in

        let store = Store.empty () in
        EdgeSet.iter (fun edge ->
          let location = Edge.get_to edge in
          let param_name = Node.label (find_node graph location) in
          Store.update' store param_name (LocationSet.singleton location)
        ) params;

        store

      let get_arg_locations (graph : t) (callee : location) : (int * location) list =
        let result = ref [] in
        iter_edges (fun loc edge ->
          match edge._type with
            | Argument (index, _) ->
              if edge._to = callee then
                result := (index, loc) :: !result
            | _ -> ()
        ) graph;
        !result


      let exists_node (graph : t) (location : location) : bool =
        Option.is_some (find_node_opt graph location)

      let has_external_function (graph : t) (func_node : location) : bool =
        exists_node graph func_node

      let get_function (graph : t) (func_node : location) : t =
        let process_additional_info (graph : t) (node : Node.t) : unit =
          match node._type with
            | Call func_name -> register_call_node graph func_name node
            | TaintSink _ -> graph.sinks := NodeSet.add node !(graph.sinks)
            | _ -> ()
          in

        let rec get_function' (graph : t) (to_visit : LocationSet.t) (visited : LocationSet.t) (func_graph : t) : t =
          if not (LocationSet.is_empty to_visit)
            then (
              let visiting, to_visit' = LocationSet.pop to_visit in
              let node = find_node graph visiting in
              let edges = get_edges graph visiting in

              process_additional_info func_graph node;
              HashTable.replace func_graph.nodes visiting node;
              HashTable.replace func_graph.edges visiting edges;


              let tos = LocationSet.of_list (EdgeSet.get_to edges) in
              get_function' graph (LocationSet.diff (LocationSet.union to_visit' tos) visited) (LocationSet.add visiting visited) func_graph
            )
            else func_graph
        in

        let func_graph = empty (fun () -> ()) in
        if exists_node graph func_node
          then get_function' graph (LocationSet.singleton func_node) (LocationSet.empty) func_graph
          else failwith ("[ERROR] Graph does not encode function with location " ^ func_node)


      let update_arg_edges (graph : t) (call_node : location) (parameters : string list) : unit =
        HashTable.filter_map_inplace (fun _ edges ->
          let new_edges = EdgeSet.map (fun edge ->
            (* check if it is a argument edge pointing to the call_node*)
            match edge._to = call_node, edge._type with
              | true, Argument (index, _) ->
                let param_name = Option.value (if index = 0 then Some "this" else List.nth_opt parameters index) ~default:"undefined" in
                {edge with _type = Argument (index, param_name)}

              | _ -> edge
          ) edges in

          Some new_edges
        ) graph.edges

      let add_external_func (graph : t) (func_graph : t) (call_node : location) (function_node : location) : unit =
        (* add callers *)
        Hashtbl.iter (fun func_name callers ->
          register_call_nodes graph func_name callers
        ) func_graph.callers;

        (* merge sinks *)
        graph.sinks := NodeSet.union !(graph.sinks) !(func_graph.sinks);

        (* add nodes *)
        iter_nodes (fun loc node ->
          HashTable.replace graph.nodes loc node
        ) func_graph;

        (* add edges *)
        iter (fun loc edges _ ->
          HashTable.replace graph.edges loc edges
        ) func_graph;

        (* update argument edges *)
        let f_node = find_node graph function_node in
        let params = Node.get_func_params f_node in
        update_arg_edges graph call_node params




      (* ------- T R A V E R S E ------- *)
      let print_path (nodes : Node.t list) : unit = print_endline (String.concat " <- " (List.map Node.get_abs_loc nodes))

      let rec reaches graph src target : Node.t list list =
        reaches' graph [ [ src ] ] []  target

      and reaches' graph cur_paths ret_paths target : Node.t list list =
        match cur_paths with
        | [] -> ret_paths
        | (cur::_ as cur_path)::tail_paths when cur = target ->
          (* found a possible path *)
          reaches' graph tail_paths (cur_path::ret_paths) target
        | (cur::_ as cur_path)::tail_paths ->
          (* no path found yet, need to keep exploring the current path *)
          let nghbrs = get_neighbors graph cur in
          let nghbrs = List.filter (fun nghbr -> not (in_path nghbr cur_path)) nghbrs in
          let fst_paths = List.map (fun cur' -> cur'::cur_path) nghbrs in
          reaches' graph (fst_paths @ tail_paths) ret_paths target
        | _ -> failwith "current path is empty"

      and in_path (node : Node.t) (path : Node.t list) : bool =
        let node_loc = Node.get_abs_loc node in
        List.exists (fun path_node -> Node.get_abs_loc path_node = node_loc) path

      and get_neighbors (graph : t) (node : Node.t) : Node.t list =
        let valid_edge: Edge._type -> bool = function
          | Property _
          | Dependency
          | Argument _
          | Version _
          | Parameter _ -> true
          | _ -> false
        in
        let neighbour_edges = get_edges graph node.abs_loc in
        EdgeSet.fold (fun edge acc -> if (valid_edge edge._type) then (find_node graph edge._to) :: acc else acc) neighbour_edges []



      let get_call_node (graph : t) (sink_node : Node.t) : Node.t =
        match sink_node._type with
          | TaintSink (_, _) ->
            let call_node = ref None in
            iter_edges (fun from edge ->
              if edge._to = sink_node.abs_loc then (
                match edge._type with
                  | Sink _ -> call_node := Some (find_node graph from);
                  | _ -> ()
              )
            ) graph;
            Option.get !call_node

          | _ -> failwith "[ERROR] provided node is not a sink node"

      let set_attacker_controlable (graph : t) (location : location) : unit =
        let node = find_node_opt graph location in
        option_may (fun node ->
          HashTable.replace graph.nodes location {node with isSource = true};

          (* add taint edges to params (to function nodes) *)
          let edges = get_edges graph location in
          EdgeSet.iter (fun (edge : Edge.t) ->
            match edge._type with
              | Edge.Parameter _ -> add_taint_edge graph loc_taint_source edge._to
              | _ -> ()
          ) edges
        ) node


      let get_class_methods (graph : t) (location : location) : location list =
        let rec traverse_prototype graph unprocessed visited result =
          match unprocessed with
            | [] -> result
            | l :: ls when List.mem l visited -> traverse_prototype graph ls visited result
            | l :: ls ->
              let l_props = get_properties graph l |> List.filter_map (fun (loc, prop) -> if Option.is_some prop then Some loc else None) in
              let l_versn = get_versions graph l |> List.filter_map (fun (loc, prop) -> if Option.is_some prop && not (List.mem loc visited) then Some loc else None) in
              traverse_prototype graph (ls @ l_versn) (l :: visited) (result @ l_props)
        in

        let prototype = LocationSet.elements @@ lookup graph location "prototype" in
        List.flatten @@
        List.map (fun proto -> traverse_prototype graph [ proto ] [] []) prototype

      let get_argument_index (graph : t) (argument : Node.t) (call_node : Node.t) : int list =
        let edges = EdgeSet.elements @@ get_edges graph (Node.get_abs_loc argument) in
        let indexes = List.filter_map (fun (edge : Edge.t) ->
          match edge._type with
            | Argument (index, _) when edge._to = call_node.abs_loc -> Some index
            | _ -> None
        ) edges in
        indexes

      let get_param_index (graph : t) (param : Node.t) (func_def : Node.t) : int list =
        let edges = EdgeSet.elements @@ find_edges graph func_def.abs_loc in
        let indexes = List.filter_map (fun (edge : Edge.t) ->
          match edge._type with
            | Parameter index when edge._to = param.abs_loc -> Some index
            | _ -> None
        ) edges in
        indexes


      let get_sensitive_inputs (graph : t) (sink_node : Node.t) (call_node : Node.t) : int list =
        let arg_locs = get_arg_locations graph call_node.abs_loc in
        IntSet.elements (List.fold_left (fun acc (i, loc) ->
          let arg_edges = find_edges graph loc in
          let is_sensitive = EdgeSet.exists (fun edge ->
            match edge._type with
              | Dependency when edge._to = sink_node.abs_loc -> true
              | _ -> false
          ) arg_edges in

          if is_sensitive
            then IntSet.add i acc
            else acc
        ) IntSet.empty arg_locs)
*)
