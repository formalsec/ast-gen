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

let get_property (mdg : t) (node : Node.t) (prop : string option) :
    Node.t option =
  edges mdg node.uid
  |> Edge.Set.elements
  |> List.find_opt (Edge.is_property ~prop:(Some prop))
  |> Option.map Edge.tar

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
  Fun.flip Hashtbl.iter mdg2.edges @@ fun loc edges_2 ->
  let node_2 = node mdg2 loc in
  let node_1 = Hashtbl.find_opt mdg1.nodes loc in
  let edges_1 = Hashtbl.find_opt mdg1.edges loc in
  let edges_1' = Option.value ~default:Edge.Set.empty edges_1 in
  if Option.is_none node_1 then Hashtbl.replace mdg1.nodes loc node_2;
  Hashtbl.replace mdg1.edges loc (Edge.Set.union edges_1' edges_2)

let object_orig_versions (mdg : t) (node : Node.t) : Node.Set.t =
  let rec orig unprocessed visited result =
    match unprocessed with
    | [] -> result
    | node :: nodes when List.mem node visited -> orig nodes visited result
    | node :: nodes ->
      let (parent_nodes, _) = List.split (get_versions mdg node) in
      let visited' = node :: visited in
      if parent_nodes == [] then orig nodes visited' (Node.Set.add node result)
      else orig (parent_nodes @ nodes) visited' result in
  orig [ node ] [] Node.Set.empty

let object_lookup_property (mdg : t) (node : Node.t) (prop : string option) :
    Node.Set.t =
  let (visited, seen_props, result) = (ref [], ref [], ref Node.Set.empty) in
  let rec lookup = function
    | [] -> !result
    | node :: nodes ->
      let props = get_properties mdg node in
      let (static, dynamic) = List.partition Fun.(Option.is_some << snd) props in
      let (dynamic_prop_nodes, _) = List.split dynamic in
      (* direct lookup - dynamic object properties *)
      result := Node.Set.union !result (Node.Set.of_list dynamic_prop_nodes);
      (* direct lookup - static object properties *)
      ( match (prop, get_property mdg node prop) with
      | (Some _, Some prop_node) -> result := Node.Set.add prop_node !result
      | (None, _) ->
        let check_unseen_prop_f (_, prop) = not (List.mem prop !seen_props) in
        let static' = List.map (fun (n, p) -> (n, Option.get p)) static in
        let unseen = List.filter check_unseen_prop_f static' in
        let (unseen_prop_nodes, unseen_prop_names) = List.split unseen in
        result := Node.Set.union !result (Node.Set.of_list unseen_prop_nodes);
        seen_props := !seen_props @ unseen_prop_names
      | _ -> () );
      (* indirect lookup - static and dynamic object properties *)
      lookup
      @@ Fun.flip2 List.fold_left nodes (get_versions mdg node)
      @@ fun acc (parent_node, parent_prop) ->
      if not (List.mem parent_node !visited) then
        match parent_prop with
        | Some _ when prop != parent_prop ->
          visited := parent_node :: !visited;
          parent_node :: acc
        | None ->
          visited := parent_node :: !visited;
          parent_node :: acc
        | _ -> acc
      else [] in
  lookup [ node ]
