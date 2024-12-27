open Graphjs_base

type t =
  { nodes : (Location.t, Node.t) Hashtbl.t
  ; edges : (Location.t, Edge.Set.t) Hashtbl.t
  ; exported : Location.t
  ; requires : Node.Set.t
  }

let create () : t =
  let nodes = Hashtbl.create Config.(!dflt_htbl_sz) in
  let edges = Hashtbl.create Config.(!dflt_htbl_sz) in
  let exported = Location.invalid_loc () in
  let requires = Node.Set.empty in
  { nodes; edges; exported; requires }

let copy (mdg : t) : t =
  let nodes = Hashtbl.copy mdg.nodes in
  let edges = Hashtbl.copy mdg.edges in
  let exported = mdg.exported in
  let requires = mdg.requires in
  { nodes; edges; exported; requires }

let rec transpose (mdg : t) : t =
  let nodes = Hashtbl.copy mdg.nodes in
  let edges = Hashtbl.create Config.(!dflt_htbl_sz) in
  let exported = mdg.exported in
  let requires = mdg.requires in
  transpose_edges mdg.edges edges;
  { nodes; edges; exported; requires }

and transpose_edges (edges : (Location.t, Edge.Set.t) Hashtbl.t)
    (edges' : (Location.t, Edge.Set.t) Hashtbl.t) : unit =
  Fun.flip Hashtbl.iter edges (fun loc edge_set ->
      Fun.flip Edge.Set.iter edge_set (fun edge ->
          Hashtbl.find_opt edges' loc
          |> Option.value ~default:Edge.Set.empty
          |> Edge.Set.add (Edge.transpose edge)
          |> Hashtbl.replace edges' loc ) )

let get_node (mdg : t) (loc : Location.t) : Node.t =
  match Hashtbl.find_opt mdg.nodes loc with
  | None -> Log.fail "expecting node with location '%a' in mdg" Location.pp loc
  | Some node -> node

let get_edges (mdg : t) (loc : Location.t) : Edge.Set.t =
  match Hashtbl.find_opt mdg.edges loc with
  | None -> Log.fail "expecting edge from location '%a' in mdg" Location.pp loc
  | Some edges -> edges

let pp_node (mdg : t) (ppf : Fmt.t) (node : Node.t) : unit =
  let edges = get_edges mdg node.uid in
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

let add_edge (mdg : t) (edge : Edge.t) : unit =
  let edges = get_edges mdg edge.src.uid in
  Hashtbl.replace mdg.edges edge.src.uid (Edge.Set.add edge edges)

let add_requires (mdg : t) (node : Node.t) : t =
  { mdg with requires = Node.Set.add node mdg.requires }

let remove_node (mdg : t) (node : Node.t) : unit =
  (* ensure that all the incoming edges are also remove to avoid problems *)
  Hashtbl.remove mdg.nodes node.uid;
  Hashtbl.remove mdg.edges node.uid

let remove_edge (mdg : t) (edge : Edge.t) : unit =
  let edges = get_edges mdg edge.src.uid in
  Hashtbl.replace mdg.edges edge.src.uid (Edge.Set.remove edge edges)

let lub (mdg1 : t) (mdg2 : t) : unit =
  Fun.flip Hashtbl.iter mdg2.edges (fun loc edges_2 ->
      let node_2 = get_node mdg2 loc in
      let node_1 = Hashtbl.find_opt mdg1.nodes loc in
      let edges_1 = Hashtbl.find_opt mdg1.edges loc in
      let edges_1' = Option.value ~default:Edge.Set.empty edges_1 in
      if Option.is_none node_1 then Hashtbl.replace mdg1.nodes loc node_2;
      Hashtbl.replace mdg1.edges loc (Edge.Set.union edges_1' edges_2) )

let has_property (mdg : t) (node : Node.t) (prop : string option) : bool =
  get_edges mdg node.uid |> Edge.Set.exists (Edge.is_property ~prop:(Some prop))

let get_property (mdg : t) (node : Node.t) (prp : string option) : Node.t list =
  get_edges mdg node.uid
  |> Edge.Set.filter (Edge.is_property ~prop:(Some prp))
  |> Edge.Set.map_list Edge.tar

let get_properties' (mdg : t) (node : Node.t) : Edge.Set.t =
  get_edges mdg node.uid |> Edge.Set.filter Edge.is_property

let get_properties (mdg : t) (node : Node.t) : (string option * Node.t) list =
  get_edges mdg node.uid
  |> Edge.Set.filter Edge.is_property
  |> Edge.Set.map_list (fun edge -> (Edge.property edge, Edge.tar edge))

let get_versions (mdg : t) (node : Node.t) : (string option * Node.t) list =
  get_edges mdg node.uid
  |> Edge.Set.filter Edge.is_version
  |> Edge.Set.map_list (fun edge -> (Edge.property edge, Edge.tar edge))

let get_parents (mdg : t) (node : Node.t) : (string option * Node.t) list =
  get_edges mdg node.uid
  |> Edge.Set.filter Edge.is_ref_parent
  |> Edge.Set.map_list (fun edge -> (Edge.property edge, Edge.tar edge))

let get_parameters (mdg : t) (node : Node.t) : (int * Node.t) list =
  get_edges mdg node.uid
  |> Edge.Set.filter Edge.is_parameter
  |> Edge.Set.map_list (fun edge -> (Edge.argument edge, Edge.tar edge))

let get_function_returns (mdg : t) (node : Node.t) : Node.t list =
  get_edges mdg node.uid
  |> Edge.Set.filter Edge.is_ref_return
  |> Edge.Set.map_list Edge.tar

let object_traverse_parents (traverse_f : Node.Set.t -> Node.t -> 'a -> 'a)
    (mdg : t) (ls_visited : Node.Set.t) (node : Node.t) (acc : 'a) : 'a =
  Fun.flip2 List.fold_left acc (get_parents mdg node) (fun acc (_, l_parent) ->
      if Node.Set.mem l_parent ls_visited then acc
      else traverse_f (Node.Set.add l_parent ls_visited) l_parent acc )

let object_lineage_traversal (f : Node.t -> 'a -> 'a) (mdg : t)
    (lineage_f : t -> Node.t -> (string option * Node.t) list)
    (ls_visited : Node.Set.t) (node : Node.t) (acc : 'a) : 'a =
  let no_lineage_f lineage = List.is_empty lineage in
  let rec_lineage_f node lineage = List.equal Node.equal [ node ] lineage in
  let rec traverse ls_visited node acc =
    let (_, lineage) = List.split (lineage_f mdg node) in
    let in_lineage = no_lineage_f lineage || rec_lineage_f node lineage in
    let acc' = if in_lineage then f node acc else acc in
    Fun.flip2 List.fold_left acc' lineage (fun acc l_lineage ->
        if Node.Set.mem l_lineage ls_visited then acc
        else traverse (Node.Set.add l_lineage ls_visited) l_lineage acc ) in
  traverse ls_visited node acc

let object_static_traversal (f : Node.t -> 'a -> 'a) (mdg : t)
    (ls_visited : Node.Set.t) (node : Node.t) (prop : string) (acc : 'a) : 'a =
  let prop' = Some prop in
  let rec traverse ls_visited node acc =
    let ls_dynamic = get_property mdg node None in
    let ls_prop = get_property mdg node prop' in
    let acc' = List.fold_right f ls_dynamic acc in
    if not (List.is_empty ls_prop) then List.fold_right f ls_prop acc'
    else object_traverse_parents traverse mdg ls_visited node acc' in
  traverse ls_visited node acc

let object_dynamic_traversal (f : string option * Node.t -> 'a -> 'a) (mdg : t)
    (ls_visited : Node.Set.t) (node : Node.t) (acc : 'a) : 'a =
  let rec traverse seen_props ls_visited node acc =
    let dynamic_f (prop, _) = Option.is_none prop in
    let unseen_f (prop, _) = not (List.mem prop seen_props) in
    let static_f (prop, node) = (Option.get prop, node) in
    let (dynamic, static) = List.partition dynamic_f (get_properties mdg node) in
    let static' = List.map static_f static in
    let unseen = List.filter unseen_f static' in
    let seen_props' = seen_props @ List.map fst unseen in
    let acc' = List.fold_right f (dynamic @ static) acc in
    object_traverse_parents (traverse seen_props') mdg ls_visited node acc'
  in
  traverse [] ls_visited node acc

let object_nested_traversal (f : string option list * Node.t -> 'a -> 'a)
    (mdg : t) (node : Node.t) (acc : 'a) : 'a =
  (* TODO: Implement a way of reaching every single property *)
  let f' el found = el :: found in
  let rec traverse ls_visited nodes acc =
    match nodes with
    | [] -> acc
    | (prev, node) :: nodes' ->
      let found = object_dynamic_traversal f' mdg ls_visited node [] in
      let found' = List.map (fun (p, n) -> (prev @ [ p ], n)) found in
      let (_, ls_props) = List.split found' in
      let ls_visited' = Node.Set.union ls_visited (Node.Set.of_list ls_props) in
      let nodes'' = nodes' @ found' in
      let acc' = List.fold_right f found' acc in
      traverse ls_visited' nodes'' acc' in
  traverse (Node.Set.singleton node) [ ([], node) ] (f ([], node) acc)

let object_orig_versions (mdg : t) (node : Node.t) : Node.Set.t =
  object_lineage_traversal Node.Set.add mdg get_parents
    (Node.Set.singleton node) node Node.Set.empty

let object_tail_versions (mdg : t) (node : Node.t) : Node.Set.t =
  object_lineage_traversal Node.Set.add mdg get_versions
    (Node.Set.singleton node) node Node.Set.empty

let object_static_lookup (mdg : t) (node : Node.t) (p : string) : Node.Set.t =
  let f node acc = Node.Set.add node acc in
  object_static_traversal f mdg (Node.Set.singleton node) node p Node.Set.empty

let object_dynamic_lookup (mdg : t) (node : Node.t) : Node.Set.t =
  let f (_, node) acc = Node.Set.add node acc in
  object_dynamic_traversal f mdg (Node.Set.singleton node) node Node.Set.empty

let exported_object (mdg : t) : Node.Set.t =
  match Hashtbl.find_opt mdg.nodes mdg.exported with
  | None -> Node.Set.empty
  | Some l_module ->
    let ls_module = object_tail_versions mdg l_module in
    Fun.flip2 Node.Set.fold ls_module Node.Set.empty (fun l_module acc ->
        Node.Set.union acc (object_static_lookup mdg l_module "exports") )
