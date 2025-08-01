type t =
  { nodes : (Location.t, Node.t) Hashtbl.t
  ; edges : (Location.t, Edge.Set.t) Hashtbl.t
  ; trans : (Location.t, Edge.Set.t) Hashtbl.t
  }

let create () : t =
  let nodes = Hashtbl.create Config.(!dflt_htbl_sz) in
  let edges = Hashtbl.create Config.(!dflt_htbl_sz) in
  let trans = Hashtbl.create Config.(!dflt_htbl_sz) in
  { nodes; edges; trans }

let copy (mdg : t) : t =
  let nodes = Hashtbl.copy mdg.nodes in
  let edges = Hashtbl.copy mdg.edges in
  let trans = Hashtbl.copy mdg.trans in
  { nodes; edges; trans }

let has_node (mdg : t) (loc : Location.t) : bool = Hashtbl.mem mdg.nodes loc

let get_node (mdg : t) (loc : Location.t) : Node.t =
  match Hashtbl.find_opt mdg.nodes loc with
  | None -> Log.fail "expecting node with location '%a' in mdg" Location.pp loc
  | Some node -> node

let get_edges (mdg : t) (loc : Location.t) : Edge.Set.t =
  match Hashtbl.find_opt mdg.edges loc with
  | None -> Log.fail "expecting edge from location '%a' in mdg" Location.pp loc
  | Some edges -> edges

let get_trans (mdg : t) (loc : Location.t) : Edge.Set.t =
  match Hashtbl.find_opt mdg.trans loc with
  | None -> Log.fail "expecting edge to location '%a' in mdg" Location.pp loc
  | Some edges -> edges

let pp_node (mdg : t) (ppf : Fmt.t) (node : Node.t) : unit =
  let edges = get_edges mdg node.loc in
  if Edge.Set.is_empty edges then Fmt.fmt ppf "%a -" Node.pp node
  else Edge.Set.pp ppf edges

let pp (ppf : Fmt.t) (mdg : t) : unit =
  let nodes = Hashtbl.to_seq_values mdg.nodes |> List.of_seq in
  let nodes' = List.sort Node.compare nodes in
  Fmt.(pp_lst !>"@\n" (pp_node mdg)) ppf nodes'

let str (mdg : t) : string = Fmt.str "%a" pp mdg

let add_node (mdg : t) (node : Node.t) : unit =
  Hashtbl.replace mdg.nodes node.loc node;
  Hashtbl.replace mdg.edges node.loc Edge.Set.empty;
  Hashtbl.replace mdg.trans node.loc Edge.Set.empty

let add_edge (mdg : t) (edge : Edge.t) : unit =
  let tran = Edge.transpose edge in
  let edges = get_edges mdg edge.src.loc in
  let trans = get_trans mdg edge.tar.loc in
  Hashtbl.replace mdg.edges edge.src.loc (Edge.Set.add edge edges);
  Hashtbl.replace mdg.trans edge.tar.loc (Edge.Set.add tran trans)

let remove_node (mdg : t) (node : Node.t) : unit =
  let edges = get_edges mdg node.loc in
  let trans = get_trans mdg node.loc in
  Fun.flip Edge.Set.iter edges (fun edge ->
      let tran = Edge.transpose edge in
      let trans = get_trans mdg tran.src.loc in
      Hashtbl.replace mdg.trans tran.src.loc (Edge.Set.remove tran trans) );
  Fun.flip Edge.Set.iter trans (fun tran ->
      let edge = Edge.transpose tran in
      let edges = get_edges mdg edge.src.loc in
      Hashtbl.replace mdg.edges edge.src.loc (Edge.Set.remove edge edges) );
  Hashtbl.remove mdg.nodes node.loc;
  Hashtbl.remove mdg.edges node.loc;
  Hashtbl.remove mdg.trans node.loc

let remove_nodes (mdg : t) (nodes : Node.t list) : unit =
  List.iter (remove_node mdg) nodes

let remove_edge (mdg : t) (edge : Edge.t) : unit =
  let tran = Edge.transpose edge in
  let edges = get_edges mdg edge.src.loc in
  let trans = get_trans mdg tran.src.loc in
  Hashtbl.replace mdg.edges edge.src.loc (Edge.Set.remove edge edges);
  Hashtbl.replace mdg.trans tran.src.loc (Edge.Set.remove tran trans)

let remove_edges (mdg : t) (edges : Edge.t list) : unit =
  List.iter (remove_edge mdg) edges

let has_dependency (mdg : t) (node1 : Node.t) (node2 : Node.t) : bool =
  get_trans mdg node1.loc
  |> Edge.Set.filter Edge.is_dependency
  |> Edge.Set.exists (fun edge -> Node.equal edge.tar node2)

let get_dependencies (mdg : t) (node : Node.t) : Node.t list =
  get_trans mdg node.loc
  |> Edge.Set.filter Edge.is_dependency
  |> Edge.Set.map_list Edge.tar

let get_dependents (mdg : t) (node : Node.t) : Node.t list =
  get_edges mdg node.loc
  |> Edge.Set.filter Edge.is_dependency
  |> Edge.Set.map_list Edge.tar

let has_property (mdg : t) (node : Node.t) (prop : Property.t) : bool =
  get_edges mdg node.loc |> Edge.Set.exists (Edge.is_property ~prop)

let get_property (mdg : t) (node : Node.t) (prop : Property.t) : Node.t list =
  get_edges mdg node.loc
  |> Edge.Set.filter (Edge.is_property ~prop)
  |> Edge.Set.map_list Edge.tar

let get_properties (mdg : t) (node : Node.t) : (Property.t * Node.t) list =
  get_edges mdg node.loc
  |> Edge.Set.filter Edge.is_property
  |> Edge.Set.map_list (fun edge -> (Edge.property edge, Edge.tar edge))

let get_property_owner (mdg : t) (node : Node.t) : (Property.t * Node.t) list =
  get_trans mdg node.loc
  |> Edge.Set.filter Edge.is_property
  |> Edge.Set.map_list (fun edge -> (Edge.property edge, Edge.tar edge))

let get_object_of_property (mdg : t) (node : Node.t) (prop : Property.t) :
    Node.t list =
  get_trans mdg node.loc
  |> Edge.Set.filter (Edge.is_property ~prop)
  |> Edge.Set.map_list Edge.tar

let get_versions (mdg : t) (node : Node.t) : (Property.t * Node.t) list =
  get_edges mdg node.loc
  |> Edge.Set.filter Edge.is_version
  |> Edge.Set.map_list (fun edge -> (Edge.property edge, Edge.tar edge))

let get_parents (mdg : t) (node : Node.t) : (Property.t * Node.t) list =
  get_trans mdg node.loc
  |> Edge.Set.filter Edge.is_version
  |> Edge.Set.map_list (fun edge -> (Edge.property edge, Edge.tar edge))

let get_parameter (mdg : t) (node : Node.t) (idx : int) : Node.t =
  get_edges mdg node.loc
  |> Edge.Set.filter (Edge.is_parameter ~idx)
  |> Edge.Set.choose (* functions can only have one parameter per index *)
  |> Edge.tar

let get_parameter_opt (mdg : t) (node : Node.t) (idx : int) : Node.t option =
  get_edges mdg node.loc
  |> Edge.Set.filter (Edge.is_parameter ~idx)
  |> Edge.Set.choose_opt (* functions can only have one parameter per index *)
  |> Option.map Edge.tar

let get_parameters (mdg : t) (node : Node.t) : (int * Node.t) list =
  get_edges mdg node.loc
  |> Edge.Set.filter Edge.is_parameter
  |> Edge.Set.map_list (fun edge -> (Edge.argument edge, Edge.tar edge))

let get_argument (mdg : t) (node : Node.t) (idx : int) : Node.t list =
  get_trans mdg node.loc
  |> Edge.Set.filter (Edge.is_argument ~idx)
  |> Edge.Set.map_list Edge.tar

let get_arguments (mdg : t) (node : Node.t) : (int * Node.t) list =
  get_trans mdg node.loc
  |> Edge.Set.filter Edge.is_argument
  |> Edge.Set.map_list (fun edge -> (Edge.argument edge, Edge.tar edge))

let get_called_functions (mdg : t) (node : Node.t) : Node.t list =
  get_edges mdg node.loc
  |> Edge.Set.filter Edge.is_caller
  |> Edge.Set.map_list Edge.tar

let get_function_callers (mdg : t) (node : Node.t) : Node.t list =
  get_trans mdg node.loc
  |> Edge.Set.filter Edge.is_caller
  |> Edge.Set.map_list Edge.tar

let get_return_of_call (mdg : t) (node : Node.t) : Node.t =
  get_edges mdg node.loc
  |> Edge.Set.filter Edge.is_dependency
  |> Edge.Set.choose (* calls can only have a single return *)
  |> Edge.tar

let get_call_of_return (mdg : t) (node : Node.t) : Node.t =
  get_trans mdg node.loc
  |> Edge.Set.filter Edge.is_dependency
  |> Edge.Set.choose (* returns can only have a single call *)
  |> Edge.tar

let get_function_returns (mdg : t) (node : Node.t) : Node.t list =
  get_edges mdg node.loc
  |> Edge.Set.filter Edge.is_return
  |> Edge.Set.map_list Edge.tar

let has_metadata (mdg : t) (node1 : Node.t) (node2 : Node.t) (meta : string) :
    bool =
  let meta_f = Edge.is_meta ~meta in
  get_edges mdg node1.loc
  |> Edge.Set.exists (fun edge -> meta_f edge && Node.equal edge.tar node2)

let get_metadata (mdg : t) (node : Node.t) : (Node.t * string) list =
  get_edges mdg node.loc
  |> Edge.Set.filter Edge.is_meta
  |> Edge.Set.map_list (fun edge -> (Edge.tar edge, Edge.metadata edge))

let object_lineage_traversal (f : Node.t -> 'a -> 'a) (mdg : t)
    (lineage_f : t -> Node.t -> (Property.t * Node.t) list)
    (ls_visited : Node.Set.t) (node : Node.t) (acc : 'a) : 'a =
  let no_lineage_f lineage = List.is_empty lineage in
  let rec_lineage_f node lineage = List.equal Node.equal [ node ] lineage in
  let rec traverse ls_visited node acc =
    let (_, lineage) = List.split (lineage_f mdg node) in
    let end_lineage = no_lineage_f lineage || rec_lineage_f node lineage in
    let acc' = if end_lineage then f node acc else acc in
    Fun.flip2 List.fold_left acc' lineage (fun acc l_lineage ->
        if Node.Set.mem l_lineage ls_visited then acc
        else traverse (Node.Set.add l_lineage ls_visited) l_lineage acc ) in
  traverse ls_visited node acc

let object_orig_versions (mdg : t) (node : Node.t) : Node.Set.t =
  object_lineage_traversal Node.Set.add mdg get_parents
    (Node.Set.singleton node) node Node.Set.empty

let object_tail_versions (mdg : t) (node : Node.t) : Node.Set.t =
  object_lineage_traversal Node.Set.add mdg get_versions
    (Node.Set.singleton node) node Node.Set.empty

let object_parents_traversal (f : Node.Set.t -> Node.t -> 'a -> 'a) (mdg : t)
    (ls_visited : Node.Set.t) (node : Node.t) (acc : 'a) : 'a =
  let ls_parents = get_parents mdg node in
  let ls_parents' = List.map (fun (_, n) -> n) ls_parents in
  let ls_visited' = Node.Set.union ls_visited (Node.Set.of_list ls_parents') in
  Fun.flip2 List.fold_left acc ls_parents' (fun acc l_parent ->
      if Node.Set.mem l_parent ls_visited then acc
      else f ls_visited' l_parent acc )

let object_static_traversal (f : Node.t -> 'a -> 'a) (mdg : t)
    (ls_visited : Node.Set.t) (node : Node.t) (prop : string) (acc : 'a) : 'a =
  let rec traverse ls_visited node acc =
    let ls_dynamic = get_property mdg node Dynamic in
    let ls_prop = get_property mdg node (Static prop) in
    let acc' = List.fold_right f ls_dynamic acc in
    if not (List.is_empty ls_prop) then List.fold_right f ls_prop acc'
    else object_parents_traversal traverse mdg ls_visited node acc' in
  traverse (Node.Set.add node ls_visited) node acc

let object_dynamic_traversal (f : Property.t * Node.t -> 'a -> 'a) (mdg : t)
    (ls_visited : Node.Set.t) (node : Node.t) (acc : 'a) : 'a =
  let rec traverse seen ls_visited node acc =
    let dynamic_f (prop, _) = Property.is_dynamic prop in
    let unseen_f (prop, _) = not (List.exists (Property.equal prop) seen) in
    let (dynamic, static) = List.partition dynamic_f (get_properties mdg node) in
    let unseen = List.filter unseen_f static in
    let seen' = seen @ List.map fst unseen in
    let acc' = List.fold_right f (dynamic @ unseen) acc in
    object_parents_traversal (traverse seen') mdg ls_visited node acc' in
  traverse [] (Node.Set.add node ls_visited) node acc

let object_static_lookup (mdg : t) (node : Node.t) (p : string) : Node.Set.t =
  let f node acc = Node.Set.add node acc in
  object_static_traversal f mdg Node.Set.empty node p Node.Set.empty
  |> Node.Set.map_flat (object_tail_versions mdg)

let object_dynamic_lookup (mdg : t) (node : Node.t) : Node.Set.t =
  let f (_, node) acc = Node.Set.add node acc in
  object_dynamic_traversal f mdg Node.Set.empty node Node.Set.empty
  |> Node.Set.map_flat (object_tail_versions mdg)

let object_dynamic_property_lookup (mdg : t) (node : Node.t) :
    (Property.t * Node.Set.t) list =
  let f (prop, node) acc = (prop, node) :: acc in
  let props = object_dynamic_traversal f mdg Node.Set.empty node [] in
  Fun.flip2 List.fold_left [] props (fun acc (prop, l_prop) ->
      (prop, object_tail_versions mdg l_prop) :: acc )

let object_lookup (mdg : t) (node : Node.t) (prop : Property.t) : Node.Set.t =
  match prop with
  | Static prop' -> object_static_lookup mdg node prop'
  | Dynamic -> object_dynamic_lookup mdg node

let visit (get_f : t -> Location.t -> Edge.Set.t) (visit_f : Edge.t -> bool)
    (node_f : Node.t -> 'a -> 'a) (edge_f : Edge.t -> 'a -> 'a) (mdg : t)
    (nodes : Node.t list) (acc : 'a) : 'a =
  let worklist = Queue.create () in
  let visited = Hashtbl.create Config.(!dflt_htbl_sz) in
  List.iter (fun node -> Queue.add node worklist) nodes;
  List.iter (fun node -> Hashtbl.add visited (Node.loc node) ()) nodes;
  let visit_edges edge acc =
    if visit_f edge then (
      if not (Hashtbl.mem visited edge.tar.loc) then (
        Queue.add edge.tar worklist;
        Hashtbl.add visited edge.tar.loc () );
      edge_f edge acc )
    else acc in
  let rec visit_nodes acc =
    Option.fold (Queue.take_opt worklist) ~none:acc ~some:(fun node ->
        let acc' = node_f node acc in
        let acc'' = Edge.Set.fold visit_edges (get_f mdg node.loc) acc' in
        visit_nodes acc'' ) in
  visit_nodes acc

let visit_forwards (visit_f : Edge.t -> bool) (node_f : Node.t -> 'a -> 'a)
    (edge_f : Edge.t -> 'a -> 'a) (mdg : t) (node : Node.t) (acc : 'a) : 'a =
  visit get_edges visit_f node_f edge_f mdg [ node ] acc

let visit_backwards (visit_f : Edge.t -> bool) (node_f : Node.t -> 'a -> 'a)
    (edge_f : Edge.t -> 'a -> 'a) (mdg : t) (node : Node.t) (acc : 'a) : 'a =
  visit get_trans visit_f node_f edge_f mdg [ node ] acc

let visit_multiple_forwards (visit_f : Edge.t -> bool)
    (node_f : Node.t -> 'a -> 'a) (edge_f : Edge.t -> 'a -> 'a) (mdg : t)
    (nodes : Node.t list) (acc : 'a) : 'a =
  visit get_edges visit_f node_f edge_f mdg nodes acc

let visit_multiple_backwards (visit_f : Edge.t -> bool)
    (node_f : Node.t -> 'a -> 'a) (edge_f : Edge.t -> 'a -> 'a) (mdg : t)
    (nodes : Node.t list) (acc : 'a) : 'a =
  visit get_trans visit_f node_f edge_f mdg nodes acc
