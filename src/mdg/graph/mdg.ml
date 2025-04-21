open Graphjs_base

type t =
  { nodes : (Location.t, Node.t) Hashtbl.t
  ; edges : (Location.t, Edge.Set.t) Hashtbl.t
  ; trans : (Location.t, Edge.Set.t) Hashtbl.t
  ; jslib : (string, Node.t) Hashtbl.t
  }

let create () : t =
  let nodes = Hashtbl.create Config.(!dflt_htbl_sz) in
  let edges = Hashtbl.create Config.(!dflt_htbl_sz) in
  let trans = Hashtbl.create Config.(!dflt_htbl_sz) in
  let jslib = Hashtbl.create Config.(!dflt_htbl_sz) in
  { nodes; edges; trans; jslib }

let copy (mdg : t) : t =
  let nodes = Hashtbl.copy mdg.nodes in
  let edges = Hashtbl.copy mdg.edges in
  let trans = Hashtbl.copy mdg.trans in
  let jslib = Hashtbl.copy mdg.jslib in
  { nodes; edges; trans; jslib }

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

let get_jslib_template (mdg : t) (name : string) : Node.t =
  match Hashtbl.find_opt mdg.jslib name with
  | None -> Log.fail "expecting jslib location with name '%s' in mdg" name
  | Some node -> node

let get_jslib_node (mdg : t) (name : string) : Node.t option =
  Hashtbl.find_opt mdg.nodes (get_jslib_template mdg name).uid

let pp_node (mdg : t) (ppf : Fmt.t) (node : Node.t) : unit =
  let edges = get_edges mdg node.uid in
  if Edge.Set.is_empty edges then Fmt.fmt ppf "%a -" Node.pp node
  else Edge.Set.pp ppf edges

let pp (ppf : Fmt.t) (mdg : t) : unit =
  let nodes = Hashtbl.to_seq_values mdg.nodes |> List.of_seq in
  let nodes' = List.sort Node.compare nodes in
  Fmt.(pp_lst !>"@\n" (pp_node mdg)) ppf nodes'

let str (mdg : t) : string = Fmt.str "%a" pp mdg

let add_node (mdg : t) (node : Node.t) : unit =
  Hashtbl.replace mdg.nodes node.uid node;
  Hashtbl.replace mdg.edges node.uid Edge.Set.empty;
  Hashtbl.replace mdg.trans node.uid Edge.Set.empty

let add_edge (mdg : t) (edge : Edge.t) : unit =
  let tran = Edge.transpose edge in
  let edges = get_edges mdg edge.src.uid in
  let trans = get_trans mdg edge.tar.uid in
  Hashtbl.replace mdg.edges edge.src.uid (Edge.Set.add edge edges);
  Hashtbl.replace mdg.trans edge.tar.uid (Edge.Set.add tran trans)

let set_jslib (mdg : t) (name : string) (l_jslib : Node.t) : unit =
  Hashtbl.replace mdg.jslib name l_jslib

let remove_node (mdg : t) (node : Node.t) : t =
  let edges = get_edges mdg node.uid in
  let trans = get_trans mdg node.uid in
  Fun.flip Edge.Set.iter edges (fun edge ->
      let edge' = Edge.transpose edge in
      let trans = get_trans mdg edge'.src.uid in
      Hashtbl.replace mdg.trans edge'.src.uid (Edge.Set.remove edge' trans) );
  Fun.flip Edge.Set.iter trans (fun edge ->
      let edge' = Edge.transpose edge in
      let edges = get_edges mdg edge'.src.uid in
      Hashtbl.replace mdg.edges edge'.src.uid (Edge.Set.remove edge' edges) );
  Hashtbl.remove mdg.nodes node.uid;
  Hashtbl.remove mdg.edges node.uid;
  Hashtbl.remove mdg.trans node.uid;
  mdg

let remove_nodes (mdg : t) (nodes : Node.t list) : t =
  List.fold_left remove_node mdg nodes

let remove_edge (mdg : t) (edge : Edge.t) : unit =
  let tran = Edge.transpose edge in
  let edges = get_edges mdg edge.src.uid in
  let trans = get_trans mdg tran.src.uid in
  Hashtbl.replace mdg.edges edge.src.uid (Edge.Set.remove edge edges);
  Hashtbl.replace mdg.trans tran.src.uid (Edge.Set.remove tran trans)

let remove_edges (mdg : t) (edges : Edge.t list) : unit =
  List.iter (remove_edge mdg) edges

let lub (mdg1 : t) (mdg2 : t) : t =
  Fun.flip Hashtbl.iter mdg2.edges (fun loc edges2 ->
      let node2 = get_node mdg2 loc in
      let trans2 = get_trans mdg2 loc in
      let node1 = Hashtbl.find_opt mdg1.nodes loc in
      let edges1 = Hashtbl.find_opt mdg1.edges loc in
      let trans1 = Hashtbl.find_opt mdg1.trans loc in
      let edges1' = Option.value ~default:Edge.Set.empty edges1 in
      let trans1' = Option.value ~default:Edge.Set.empty trans1 in
      if Option.is_none node1 then Hashtbl.replace mdg1.nodes loc node2;
      Hashtbl.replace mdg1.edges loc (Edge.Set.union edges1' edges2);
      Hashtbl.replace mdg1.trans loc (Edge.Set.union trans1' trans2) );
  mdg1

let get_dependencies (mdg : t) (node : Node.t) : Node.t list =
  get_edges mdg node.uid
  |> Edge.Set.filter Edge.is_dependency
  |> Edge.Set.map_list Edge.tar

let has_property (mdg : t) (node : Node.t) (prop : Property.t) : bool =
  get_edges mdg node.uid |> Edge.Set.exists (Edge.is_property ~prop)

let get_property (mdg : t) (node : Node.t) (prop : Property.t) : Node.t list =
  get_edges mdg node.uid
  |> Edge.Set.filter (Edge.is_property ~prop)
  |> Edge.Set.map_list Edge.tar

let get_properties (mdg : t) (node : Node.t) : (Property.t * Node.t) list =
  get_edges mdg node.uid
  |> Edge.Set.filter Edge.is_property
  |> Edge.Set.map_list (fun edge -> (Edge.property edge, Edge.tar edge))

let get_property_owners (mdg : t) (node : Node.t) : Node.t list =
  get_trans mdg node.uid
  |> Edge.Set.filter Edge.is_property
  |> Edge.Set.map_list Edge.tar

let get_versions (mdg : t) (node : Node.t) : (Property.t * Node.t) list =
  get_edges mdg node.uid
  |> Edge.Set.filter Edge.is_version
  |> Edge.Set.map_list (fun edge -> (Edge.property edge, Edge.tar edge))

let get_parents (mdg : t) (node : Node.t) : (Property.t * Node.t) list =
  get_trans mdg node.uid
  |> Edge.Set.filter Edge.is_version
  |> Edge.Set.map_list (fun edge -> (Edge.property edge, Edge.tar edge))

let get_parameter (mdg : t) (node : Node.t) (idx : int) : Node.t =
  get_edges mdg node.uid
  |> Edge.Set.filter (Edge.is_parameter ~idx)
  |> Edge.Set.choose (* functions can only have a single parameter per index *)
  |> Edge.tar

let get_parameters (mdg : t) (node : Node.t) : (int * Node.t) list =
  get_edges mdg node.uid
  |> Edge.Set.filter Edge.is_parameter
  |> Edge.Set.map_list (fun edge -> (Edge.argument edge, Edge.tar edge))

let get_argument (mdg : t) (node : Node.t) (idx : int) : Node.t list =
  get_trans mdg node.uid
  |> Edge.Set.filter (Edge.is_argument ~idx)
  |> Edge.Set.map_list Edge.tar

let get_arguments (mdg : t) (node : Node.t) : (int * Node.t) list =
  get_trans mdg node.uid
  |> Edge.Set.filter Edge.is_argument
  |> Edge.Set.map_list (fun edge -> (Edge.argument edge, Edge.tar edge))

let get_called_functions (mdg : t) (node : Node.t) : Node.t list =
  get_edges mdg node.uid
  |> Edge.Set.filter Edge.is_caller
  |> Edge.Set.map_list Edge.tar

let get_return_of_call (mdg : t) (node : Node.t) : Node.t =
  get_edges mdg node.uid
  |> Edge.Set.filter Edge.is_dependency
  |> Edge.Set.choose (* calls can only have a single return *)
  |> Edge.tar

let get_call_of_return (mdg : t) (node : Node.t) : Node.t =
  get_trans mdg node.uid
  |> Edge.Set.filter Edge.is_dependency
  |> Edge.Set.choose (* returns can only have a single call *)
  |> Edge.tar

let get_function_returns (mdg : t) (node : Node.t) : Node.t list =
  get_edges mdg node.uid
  |> Edge.Set.filter Edge.is_return
  |> Edge.Set.map_list Edge.tar

let visit (visit_f : Edge.t -> bool) (node_f : Node.t -> 'a -> 'a)
    (edge_f : Edge.t -> 'a -> 'a) (mdg : t) (nodes : Node.t list) (acc : 'a)
    (forward : bool) : 'a =
  let get_edges_f = if forward then get_edges else get_trans in
  let worklist = Queue.create () in
  let visited = Hashtbl.create Config.(!dflt_htbl_sz) in
  List.iter (fun node -> Queue.add node worklist) nodes;
  List.iter (fun node -> Hashtbl.add visited (Node.uid node) ()) nodes;
  let visit_edge edge acc =
    if visit_f edge then (
      if not (Hashtbl.mem visited edge.tar.uid) then (
        Queue.add edge.tar worklist;
        Hashtbl.add visited edge.tar.uid () );
      edge_f edge acc )
    else acc in
  let visit_node node acc =
    let acc' = node_f node acc in
    Edge.Set.fold visit_edge (get_edges_f mdg node.uid) acc' in
  let rec visit_nodes acc =
    Option.fold (Queue.take_opt worklist) ~none:acc ~some:(fun node ->
        visit_nodes (visit_node node acc) ) in
  visit_nodes acc

let visit_forwards (visit_f : Edge.t -> bool) (node_f : Node.t -> 'a -> 'a)
    (edge_f : Edge.t -> 'a -> 'a) (mdg : t) (node : Node.t) (acc : 'a) : 'a =
  visit visit_f node_f edge_f mdg [ node ] acc true

let visit_backwards (visit_f : Edge.t -> bool) (node_f : Node.t -> 'a -> 'a)
    (edge_f : Edge.t -> 'a -> 'a) (mdg : t) (node : Node.t) (acc : 'a) : 'a =
  visit visit_f node_f edge_f mdg [ node ] acc false

let visit_multiple_forwards (visit_f : Edge.t -> bool)
    (node_f : Node.t -> 'a -> 'a) (edge_f : Edge.t -> 'a -> 'a) (mdg : t)
    (nodes : Node.t list) (acc : 'a) : 'a =
  visit visit_f node_f edge_f mdg nodes acc true

let visit_multiple_backwards (visit_f : Edge.t -> bool)
    (node_f : Node.t -> 'a -> 'a) (edge_f : Edge.t -> 'a -> 'a) (mdg : t)
    (nodes : Node.t list) (acc : 'a) : 'a =
  visit visit_f node_f edge_f mdg nodes acc false

let object_parents_traversal (f : Node.Set.t -> Node.t -> 'a -> 'a) (mdg : t)
    (ls_visited : Node.Set.t) (node : Node.t) (acc : 'a) : 'a =
  Fun.flip2 List.fold_left acc (get_parents mdg node) (fun acc (_, l_parent) ->
      if Node.Set.mem l_parent ls_visited then acc
      else f (Node.Set.add l_parent ls_visited) l_parent acc )

let object_lineage_traversal (f : Node.t -> 'a -> 'a) (mdg : t)
    (lineage_f : t -> Node.t -> (Property.t * Node.t) list)
    (ls_visited : Node.Set.t) (node : Node.t) (acc : 'a) : 'a =
  let no_lineage_f lineage = List.is_empty lineage in
  let rec_lineage_f node lineage = List.equal Node.equal [ node ] lineage in
  let rec traverse ls_visited node acc =
    let (_, lineage) = List.split (lineage_f mdg node) in
    let final_node = no_lineage_f lineage || rec_lineage_f node lineage in
    let acc' = if final_node then f node acc else acc in
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

let object_final_traversal (final : bool) (f : Node.Set.t -> Node.t -> 'a -> 'a)
    (mdg : t) (ls_visited : Node.Set.t) (node : Node.t) (acc : 'a) : 'a =
  if final then
    let ls_final = object_tail_versions mdg node in
    let ls_visited' = Node.Set.union ls_visited ls_final in
    Node.Set.fold (f ls_visited') ls_final acc
  else
    let ls_visited' = Node.Set.add node ls_visited in
    f ls_visited' node acc

let object_static_traversal ?(final = true) (f : Node.t -> 'a -> 'a) (mdg : t)
    (ls_visited : Node.Set.t) (node : Node.t) (prop : string) (acc : 'a) : 'a =
  let rec traverse ls_visited node acc =
    let ls_dynamic = get_property mdg node Dynamic in
    let ls_prop = get_property mdg node (Static prop) in
    let acc' = List.fold_right f ls_dynamic acc in
    if not (List.is_empty ls_prop) then List.fold_right f ls_prop acc'
    else object_parents_traversal traverse mdg ls_visited node acc' in
  object_final_traversal final traverse mdg ls_visited node acc

let object_dynamic_traversal ?(final = true)
    (f : Property.t * Node.t -> 'a -> 'a) (mdg : t) (ls_visited : Node.Set.t)
    (node : Node.t) (acc : 'a) : 'a =
  let rec traverse seen ls_visited node acc =
    let dynamic_f (prop, _) = Property.is_dynamic prop in
    let unseen_f (prop, _) = not (List.exists (Property.equal prop) seen) in
    let (dynamic, static) = List.partition dynamic_f (get_properties mdg node) in
    let unseen = List.filter unseen_f static in
    let seen' = seen @ List.map fst unseen in
    let acc' = List.fold_right f (dynamic @ unseen) acc in
    object_parents_traversal (traverse seen') mdg ls_visited node acc' in
  object_final_traversal final (traverse []) mdg ls_visited node acc

let object_nested_traversal ?(final = true)
    (f : Property.t list * Node.t -> 'a -> 'a) (mdg : t) (node : Node.t)
    (acc : 'a) : 'a =
  let f' node acc = node :: acc in
  let rec traverse ls_visited nodes acc =
    match nodes with
    | [] -> acc
    | (props, node) :: nodes' ->
      let found = object_dynamic_traversal ~final f' mdg ls_visited node [] in
      let found' = List.map (fun (p, n) -> (props @ [ p ], n)) found in
      let (_, ls_found) = List.split found' in
      let ls_visited' = Node.Set.union ls_visited (Node.Set.of_list ls_found) in
      let nodes'' = nodes' @ found' in
      let acc' = List.fold_right f found' acc in
      traverse ls_visited' nodes'' acc' in
  traverse (Node.Set.singleton node) [ ([], node) ] (f ([], node) acc)

let object_static_lookup (mdg : t) (node : Node.t) (p : string) : Node.Set.t =
  let f node acc = Node.Set.add node acc in
  object_static_traversal f mdg (Node.Set.singleton node) node p Node.Set.empty

let object_dynamic_lookup (mdg : t) (node : Node.t) : Node.Set.t =
  let f (_, node) acc = Node.Set.add node acc in
  object_dynamic_traversal f mdg (Node.Set.singleton node) node Node.Set.empty

let object_lookup (mdg : t) (node : Node.t) (prop : Property.t) : Node.Set.t =
  match prop with
  | Static prop' -> object_static_lookup mdg node prop'
  | Dynamic -> object_dynamic_lookup mdg node
