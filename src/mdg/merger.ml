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
    (ls_exported : Node.Set.t) : t =
  let merger' = connect_properties merger ls_visited l_node ls_exported in
  let incoming = Mdg.get_trans merger'.mdg l_node.uid in
  let outgoing = Mdg.get_edges merger'.mdg l_node.uid in
  let merger'' = { merger' with mdg = Mdg.remove_node merger'.mdg l_node } in
  connect_incoming merger'' incoming ls_exported;
  connect_outgoing merger'' outgoing ls_exported;
  merger''

and connect_properties (merger : t) (ls_visited : Node.Set.t) (l_node : Node.t)
    (ls_exported : Node.Set.t) : t =
  let props = Mdg.get_properties merger.mdg l_node in
  let prop_nodes = props |> List.split |> snd |> Node.Set.of_list in
  let ls_visited' = Node.Set.union ls_visited prop_nodes in
  Fun.flip2 List.fold_left merger props (fun merger (prop, l_prop) ->
      if not (Node.Set.mem l_prop ls_visited) then
        Fun.flip2 Node.Set.fold ls_exported merger (fun l_exported merger ->
            let ls_exported' = Mdg.object_lookup merger.mdg l_exported prop in
            connect_modules merger ls_visited' l_prop ls_exported' )
      else merger )

and connect_incoming (merger : t) (incoming : Edge.Set.t)
    (ls_exported : Node.Set.t) : unit =
  Fun.flip Edge.Set.iter incoming (fun edge ->
      Fun.flip Node.Set.iter ls_exported (fun l_exported ->
          let edge' = { edge with src = edge.tar; tar = l_exported } in
          Mdg.add_edge merger.mdg edge' ) )

and connect_outgoing (merger : t) (outgoing : Edge.Set.t)
    (ls_exported : Node.Set.t) : unit =
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
    let mdg' = Mdg.remove_node merger.mdg l_require in
    let mdg = Mdg.remove_node mdg' l_call in
    let merger' = { merger with mdg } in
    connect_modules merger' (Node.Set.singleton l_retn) l_retn entry.exported

let merge_modules (merger : t) : t =
  Fun.flip2 List.fold_left merger merger.requires
    (fun merger (root, l_require) ->
      match l_require.kind with
      | Require path -> require_modules merger l_require root path
      | _ -> Log.fail "unexpected node kind in mdg requires" )

let remove_require_function (merger : t) : t =
  if Node.Set.cardinal merger.mdg.requires == 0 then
    Fun.flip2 Node.Set.fold merger.mdg.jslib merger (fun node merger ->
        match node.kind with
        | Function "require" ->
          { merger with mdg = Mdg.remove_node merger.mdg node }
        | _ -> merger )
  else merger

let merge_entries (merger : t) : Mdg.t =
  if List.length merger.requires != 0 then
    merger |> combine_mdgs |> merge_modules |> remove_require_function
    |> fun entry -> entry.mdg
  else merger.mdg
