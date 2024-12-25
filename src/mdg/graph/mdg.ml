open Graphjs_base

type t =
  { nodes : (Location.t, Node.t) Hashtbl.t
  ; edges : (Location.t, Edge.Set.t) Hashtbl.t
  ; literal : Node.t
  ; exported : Node.t
  }

let create () : t =
  let nodes = Hashtbl.create Config.(!dflt_htbl_sz) in
  let edges = Hashtbl.create Config.(!dflt_htbl_sz) in
  let literal = Node.create_literal () in
  let exported = Node.create_invalid () in
  { nodes; edges; literal; exported }

let copy (mdg : t) : t =
  let nodes = Hashtbl.copy mdg.nodes in
  let edges = Hashtbl.copy mdg.edges in
  let literal = mdg.literal in
  let exported = mdg.exported in
  { nodes; edges; literal; exported }

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

let add_edge (mdg : t) (node : Node.t) (edge : Edge.t) : unit =
  let edges = get_edges mdg node.uid in
  Hashtbl.replace mdg.edges node.uid (Edge.Set.add edge edges)

let has_property (mdg : t) (node : Node.t) (prop : string option) : bool =
  get_edges mdg node.uid |> Edge.Set.exists (Edge.is_property ~prop:(Some prop))

let get_property (mdg : t) (node : Node.t) (prp : string option) : Node.t list =
  get_edges mdg node.uid
  |> Edge.Set.filter (Edge.is_property ~prop:(Some prp))
  |> Edge.Set.map_list Edge.tar

let get_properties (mdg : t) (node : Node.t) : (string option * Node.t) list =
  get_edges mdg node.uid
  |> Edge.Set.filter Edge.is_property
  |> Edge.Set.map_list (fun edge -> (Edge.property edge, Edge.tar edge))

let get_versions (m : t) (node : Node.t) : (string option * Node.t) list =
  get_edges m node.uid
  |> Edge.Set.filter Edge.is_ref_parent
  |> Edge.Set.map_list (fun edge -> (Edge.property edge, Edge.tar edge))

let get_parameters (mdg : t) (node : Node.t) : (int * Node.t) list =
  get_edges mdg node.uid
  |> Edge.Set.filter Edge.is_parameter
  |> Edge.Set.map_list (fun edge -> (Edge.argument edge, Edge.tar edge))

let lub (mdg1 : t) (mdg2 : t) : unit =
  Fun.flip Hashtbl.iter mdg2.edges (fun loc edges_2 ->
      let node_2 = get_node mdg2 loc in
      let node_1 = Hashtbl.find_opt mdg1.nodes loc in
      let edges_1 = Hashtbl.find_opt mdg1.edges loc in
      let edges_1' = Option.value ~default:Edge.Set.empty edges_1 in
      if Option.is_none node_1 then Hashtbl.replace mdg1.nodes loc node_2;
      Hashtbl.replace mdg1.edges loc (Edge.Set.union edges_1' edges_2) )

let object_orig_versions (mdg : t) (node : Node.t) : Node.Set.t =
  let rec orig ls_visited node =
    let (_, ls_parent) = List.split (get_versions mdg node) in
    let ls_version =
      if List.is_empty ls_parent then Node.Set.singleton node
      else Node.Set.empty in
    Fun.flip2 List.fold_left ls_version ls_parent (fun acc l_parent ->
        if Node.Set.mem l_parent ls_visited then acc
        else
          let ls_visited' = Node.Set.add l_parent ls_visited in
          Node.Set.union acc (orig ls_visited' l_parent) ) in
  orig (Node.Set.singleton node) node

let object_static_lookup (mdg : t) (node : Node.t) (prp : string) : Node.Set.t =
  let rec lookup ls_visited node =
    let ls_dynamic = Node.Set.of_list (get_property mdg node None) in
    let ls_prop = get_property mdg node (Some prp) in
    match List.is_empty ls_prop with
    | false -> Node.Set.union ls_dynamic (Node.Set.of_list ls_prop)
    | true ->
      Fun.flip2 List.fold_left ls_dynamic (get_versions mdg node)
        (fun acc (_, l_parent) ->
          if Node.Set.mem l_parent ls_visited then acc
          else
            let ls_visited' = Node.Set.add l_parent ls_visited in
            Node.Set.union acc (lookup ls_visited' l_parent) ) in
  lookup (Node.Set.singleton node) node

let object_dynamic_lookup (mdg : t) (node : Node.t) : Node.Set.t =
  let rec lookup seen ls_visited node =
    let check_unseen_prop_f (prop, _) = not (List.mem prop seen) in
    let props = get_properties mdg node in
    let (dynamic, static) = List.partition Fun.(Option.is_none << fst) props in
    let (_, ls_dynamic) = List.split dynamic in
    let static' = List.map (fun (p, n) -> (Option.get p, n)) static in
    let unseen = List.filter check_unseen_prop_f static' in
    let (unseen', ls_unseen) = List.split unseen in
    let seen' = seen @ unseen' in
    let ls_prop = Node.Set.of_list (ls_dynamic @ ls_unseen) in
    Fun.flip2 List.fold_left ls_prop (get_versions mdg node)
      (fun acc (_, l_parent) ->
        if Node.Set.mem l_parent ls_visited then acc
        else
          let ls_visited' = Node.Set.add l_parent ls_visited in
          Node.Set.union acc (lookup seen' ls_visited' l_parent) ) in
  lookup [] (Node.Set.singleton node) node
