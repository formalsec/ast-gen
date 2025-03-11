open Graphjs_base
open Graphjs_share

type entry =
  { mdg : Mdg.t
  ; exported : Node.Set.t
  }

type t =
  { taint_config : Taint_config.t
  ; entries : (Fpath.t, entry) Hashtbl.t
  ; imports : (Fpath.t * Node.t) list
  ; main : Mdg.t
  }

let main (entry : t) : Mdg.t = entry.main

let create_entry ((path, mdg) : Fpath.t * Mdg.t) : Fpath.t * entry =
  (path, { mdg; exported = Jslib.exported_object mdg })

let create_imports ((path, mdg) : Fpath.t * Mdg.t) : (Fpath.t * Node.t) list =
  (* TODO: try to check all nodes of the mdg *)
  let (root, _) = Fpath.split_base path in
  Node.Set.map_list (fun l_import -> (root, l_import)) mdg.imports

let create (taint_config : Taint_config.t) (mdgs : (Fpath.t * Mdg.t) list) : t =
  let mdgs' = List.map (fun (path, mdg) -> (Fpath.rem_ext path, mdg)) mdgs in
  let entries = List.map create_entry mdgs' |> List.to_seq |> Hashtbl.of_seq in
  let imports = List.map create_imports mdgs' |> List.flatten in
  let (_, main) = List.nth mdgs' (List.length mdgs' - 1) in
  { taint_config; entries; imports; main }

let combine_mdgs (merger : t) : t =
  let main = { (Mdg.create ()) with jslib = merger.main.jslib } in
  let merger' = { merger with main } in
  Fun.flip2 Hashtbl.fold merger.entries merger' (fun _ entry acc ->
      { merger with main = Mdg.lub acc.main entry.mdg } )

let find_module (merger : t) (path : Fpath.t) : entry option =
  match Hashtbl.find_opt merger.entries path with
  | Some _ as entry -> entry
  | None -> None (* TODO: Search for the module in the tainted config *)

let find_import_gateway (merger : t) (l_import : Node.t) : Node.t * Node.t =
  match Mdg.get_dependencies merger.main l_import with
  | [ l_retn ] ->
    let l_call = Mdg.get_call_of_return merger.main l_retn in
    (l_call, l_retn)
  | _ -> Log.fail "unexpected subgraphgraph for require operation"

let rec connect_modules (merger : t) (ls_visited : Node.Set.t) (l_node : Node.t)
    (ls_exported : Node.Set.t) : t =
  let merger' = connect_properties merger ls_visited l_node ls_exported in
  let incoming = Mdg.get_trans merger'.main l_node.uid in
  let outgoing = Mdg.get_edges merger'.main l_node.uid in
  let merger'' = { merger' with main = Mdg.remove_node merger'.main l_node } in
  connect_incoming merger'' incoming ls_exported;
  connect_outgoing merger'' outgoing ls_exported;
  merger''

and connect_properties (merger : t) (ls_visited : Node.Set.t) (l_node : Node.t)
    (ls_exported : Node.Set.t) : t =
  let props = Mdg.get_properties merger.main l_node in
  let ls_props = props |> List.split |> snd |> Node.Set.of_list in
  let ls_visited' = Node.Set.union ls_visited ls_props in
  Fun.flip2 List.fold_left merger props (fun merger (prop, l_prop) ->
      if not (Node.Set.mem l_prop ls_visited) then
        Fun.flip2 Node.Set.fold ls_exported merger (fun l_exported merger ->
            let ls_exported' = Mdg.object_lookup merger.main l_exported prop in
            connect_modules merger ls_visited' l_prop ls_exported' )
      else merger )

and connect_incoming (merger : t) (incoming : Edge.Set.t)
    (ls_exported : Node.Set.t) : unit =
  Fun.flip Edge.Set.iter incoming (fun edge ->
      Fun.flip Node.Set.iter ls_exported (fun l_exported ->
          let edge' = { edge with src = edge.tar; tar = l_exported } in
          Mdg.add_edge merger.main edge' ) )

and connect_outgoing (merger : t) (outgoing : Edge.Set.t)
    (ls_exported : Node.Set.t) : unit =
  Fun.flip Edge.Set.iter outgoing (fun edge ->
      Fun.flip Node.Set.iter ls_exported (fun l_exported ->
          let edge' = { edge with src = l_exported } in
          Mdg.add_edge merger.main edge' ) )

let import_module (merger : t) (l_import : Node.t) (root : Fpath.t)
    (name : string) : t =
  let path = Fpath.(root // v name |> rem_ext |> normalize) in
  match find_module merger path with
  | None -> merger
  | Some entry ->
    let (l_call, l_retn) = find_import_gateway merger l_import in
    let main' = Mdg.remove_nodes merger.main [ l_import; l_call ] in
    let merger' = { merger with main = main' } in
    let ls_visited = Node.Set.singleton l_retn in
    connect_modules merger' ls_visited l_retn entry.exported

let merge_modules (merger : t) : t =
  Fun.flip2 List.fold_left merger merger.imports (fun merger (root, l_import) ->
      match l_import.kind with
      | Import path -> import_module merger l_import root path
      | _ -> Log.fail "unexpected node kind in mdg requires" )

let remove_jslib_require (merger : t) : t =
  if Node.Set.cardinal merger.main.imports == 0 then
    match Mdg.get_jslib_node merger.main "require" with
    | None -> merger
    | Some l_require ->
      { merger with main = Mdg.remove_node merger.main l_require }
  else merger

let merge_entries (merger : t) : Mdg.t =
  if List.length merger.imports == 0 then merger.main
  else merger |> combine_mdgs |> merge_modules |> remove_jslib_require |> main
