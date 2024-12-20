open Graphjs_base

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

let get_property (mdg : t) (node : Node.t) (prp : string option) : Node.t list =
  edges mdg node.uid
  |> Edge.Set.filter (Edge.is_property ~prop:(Some prp))
  |> Edge.Set.map_list Edge.tar

let get_properties (mdg : t) (node : Node.t) : (Node.t * string option) list =
  edges mdg node.uid
  |> Edge.Set.filter Edge.is_property
  |> Edge.Set.map_list (fun edge -> (Edge.tar edge, Edge.property edge))

let get_versions (mdg : t) (node : Node.t) : (Node.t * string option) list =
  edges mdg node.uid
  |> Edge.Set.filter Edge.is_ref_parent
  |> Edge.Set.map_list (fun edge -> (Edge.tar edge, Edge.property edge))

let get_parameters (mdg : t) (node : Node.t) : (int * Node.t) list =
  edges mdg node.uid
  |> Edge.Set.filter Edge.is_parameter
  |> Edge.Set.map_list (fun edge -> (Edge.argument edge, Edge.tar edge))

let lub (mdg1 : t) (mdg2 : t) : unit =
  Fun.flip Hashtbl.iter mdg2.edges (fun loc edges_2 ->
      let node_2 = node mdg2 loc in
      let node_1 = Hashtbl.find_opt mdg1.nodes loc in
      let edges_1 = Hashtbl.find_opt mdg1.edges loc in
      let edges_1' = Option.value ~default:Edge.Set.empty edges_1 in
      if Option.is_none node_1 then Hashtbl.replace mdg1.nodes loc node_2;
      Hashtbl.replace mdg1.edges loc (Edge.Set.union edges_1' edges_2) )

let object_orig_versions (mdg : t) (node : Node.t) : Node.Set.t =
  let rec orig visited node =
    let (parent_nodes, _) = List.split (get_versions mdg node) in
    let result =
      if List.is_empty parent_nodes then Node.Set.singleton node
      else Node.Set.empty in
    Fun.flip2 List.fold_left result parent_nodes (fun acc parent_node ->
        if not (Node.Set.mem parent_node visited) then
          let visited' = Node.Set.add parent_node visited in
          Node.Set.union acc (orig visited' parent_node)
        else acc ) in
  orig (Node.Set.singleton node) node

let object_static_lookup (mdg : t) (node : Node.t) (prp : string) : Node.Set.t =
  let rec lookup visited node =
    let dynamic_props = Node.Set.of_list (get_property mdg node None) in
    let props = get_property mdg node (Some prp) in
    match List.is_empty props with
    | false -> Node.Set.union dynamic_props (Node.Set.of_list props)
    | true ->
      Fun.flip2 List.fold_left dynamic_props (get_versions mdg node)
        (fun acc (parent_node, _) ->
          if not (Node.Set.mem parent_node visited) then
            let visited' = Node.Set.add parent_node visited in
            Node.Set.union acc (lookup visited' parent_node)
          else acc ) in
  lookup (Node.Set.singleton node) node

let object_dynamic_lookup (mdg : t) (node : Node.t) : Node.Set.t =
  let rec lookup seen_props visited node =
    let check_unseen_prop_f (_, prop) = not (List.mem prop seen_props) in
    let props = get_properties mdg node in
    let (dynamic, static) = List.partition Fun.(Option.is_none << snd) props in
    let (dynamic_prop_nodes, _) = List.split dynamic in
    let static_props = List.map (fun (n, p) -> (n, Option.get p)) static in
    let unseen_props = List.filter check_unseen_prop_f static_props in
    let (unseen_prop_nodes, unseen_prop_names) = List.split unseen_props in
    let seen_props' = seen_props @ unseen_prop_names in
    let prop_nodes = Node.Set.of_list (dynamic_prop_nodes @ unseen_prop_nodes) in
    Fun.flip2 List.fold_left prop_nodes (get_versions mdg node)
      (fun acc (parent_node, _) ->
        if not (Node.Set.mem parent_node visited) then
          let visited' = Node.Set.add parent_node visited in
          Node.Set.union acc (lookup seen_props' visited' parent_node)
        else acc ) in
  lookup [] (Node.Set.singleton node) node
