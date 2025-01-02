open Graphjs_base
open Graphjs_share

module Entry = struct
  type t =
    { mdg : Mdg.t
    ; exported : Node.Set.t
    }

  let mdg (entry : t) : Mdg.t = entry.mdg [@@inline]
end

type t =
  { taint_config : Taint_config.t
  ; entries : (Fpath.t, Entry.t) Hashtbl.t
  ; requires : (Fpath.t * Node.t) list
  ; mdg : Mdg.t
  }

let create_entry ((path, mdg) : Fpath.t * Mdg.t) : Fpath.t * Entry.t =
  (path, { mdg; exported = Mdg.exported_object mdg })

let create_requires ((path, mdg) : Fpath.t * Mdg.t)
    (acc : (Fpath.t * Node.t) list) : (Fpath.t * Node.t) list =
  let (root, _) = Fpath.split_base path in
  Node.Set.map_list (fun l_require -> (root, l_require)) mdg.requires @ acc

let create (taint_config : Taint_config.t) (mdgs : (Fpath.t * Mdg.t) list) : t =
  let mdgs' = List.map (fun (path, mdg) -> (Fpath.rem_ext path, mdg)) mdgs in
  let (_, mdg) = List.nth mdgs' (List.length mdgs' - 1) in
  let entries = List.map create_entry mdgs' |> List.to_seq |> Hashtbl.of_seq in
  let requires = List.fold_right create_requires mdgs' [] in
  { taint_config; entries; requires; mdg }

let combine_mdgs (merger : t) : t =
  let mdg = { (Mdg.create ()) with exported = merger.mdg.exported } in
  let merger' = { merger with mdg } in
  Fun.flip2 Hashtbl.fold merger.entries merger' (fun _ entry acc ->
      { merger with mdg = Mdg.lub acc.mdg (Entry.mdg entry) } )

let find_require_targets (merger : t) (l_require : Node.t) : Node.t * Node.t =
  match Mdg.get_dependencies merger.mdg l_require with
  | [ l_retn ] ->
    let l_call = Mdg.get_call_of_return merger.mdg l_retn in
    (l_call, l_retn)
  | _ -> Log.fail "unexpected subgraphgraph for require operation"

let find_module (merger : t) (path : Fpath.t) : Entry.t option =
  match Hashtbl.find_opt merger.entries path with
  | Some _ as entry -> entry
  | None -> None
(* TODO: Search for the module in the tainted config *)

let rec connect_modules (merger : t) (ls_visited : Node.Set.t) (l_node : Node.t)
    (ls_exported : Node.Set.t) : unit =
  let props = Mdg.get_properties merger.mdg l_node in
  let prop_nodes = props |> List.split |> snd |> Node.Set.of_list in
  let ls_visited' = Node.Set.union ls_visited prop_nodes in
  Fun.flip List.iter props (fun (prop, l_prop) ->
      if not (Node.Set.mem l_prop ls_visited) then
        Fun.flip Node.Set.iter ls_exported (fun l_exported ->
            let ls_exported' = Mdg.object_lookup merger.mdg l_exported prop in
            connect_modules merger ls_visited' l_prop ls_exported' ) );
  let incoming = Mdg.get_trans merger.mdg l_node.uid in
  let outgoing = Mdg.get_edges merger.mdg l_node.uid in
  Mdg.remove_node merger.mdg l_node;
  Fun.flip Edge.Set.iter incoming (fun edge ->
      Fun.flip Node.Set.iter ls_exported (fun l_exported ->
          let edge' = { edge with src = edge.tar; tar = l_exported } in
          Mdg.add_edge merger.mdg edge' ) );
  Fun.flip Edge.Set.iter outgoing (fun edge ->
      Fun.flip Node.Set.iter ls_exported (fun l_exported ->
          let edge' = { edge with src = l_exported } in
          Mdg.add_edge merger.mdg edge' ) )

let require_modules (merger : t) (l_require : Node.t) (root : Fpath.t)
    (name : string) : t =
  let path = Fpath.(root // v name |> rem_ext |> normalize) in
  match find_module merger path with
  | None -> merger
  | Some entry ->
    let (l_call, l_retn) = find_require_targets merger l_require in
    Mdg.remove_node merger.mdg l_require;
    Mdg.remove_node merger.mdg l_call;
    connect_modules merger (Node.Set.singleton l_retn) l_retn entry.exported;
    let requires = Node.Set.remove l_require merger.mdg.requires in
    { merger with mdg = { merger.mdg with requires } }

let merge_modules (merger : t) : t =
  Fun.flip2 List.fold_left merger merger.requires
    (fun merger (root, l_require) ->
      match l_require.kind with
      | Module path -> require_modules merger l_require root path
      | _ -> Log.fail "unexpected node kind in mdg requires" )

let remove_require_function (merger : t) : unit =
  if Node.Set.cardinal merger.mdg.requires == 0 then
    Fun.flip Node.Set.iter merger.mdg.jslib (fun node ->
        match node.kind with
        | Function "require" -> Mdg.remove_node merger.mdg node
        | _ -> () )

let merge_entries (merger : t) : Mdg.t =
  if List.length merger.requires != 0 then
    let merger' = combine_mdgs merger in
    let merger'' = merge_modules merger' in
    let () = remove_require_function merger'' in
    merger''.mdg
  else merger.mdg
