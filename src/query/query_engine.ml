open Graphjs_mdg

exception Timeout

type t =
  { mdg : Mdg.t
  ; tainted : Tainted.t
  ; curr_time : Time.t
  }

let initialize (e_mdg : Builder.ExtendedMdg.t) : t =
  { mdg = e_mdg.mdg; tainted = e_mdg.tainted; curr_time = e_mdg.curr_time }

let is_tainted (engine : t) (node : Node.t) : bool =
  Tainted.is_tainted engine.tainted node

let tainted_sinks (engine : t) : Node.t list =
  Fun.flip2 Hashtbl.fold engine.mdg.nodes [] (fun _ node acc ->
      if Node.is_taint_sink node then node :: acc else acc )

let tainted_sink_calls (engine : t) : (Node.t * Node.t) list =
  let l_sinks = tainted_sinks engine in
  Fun.flip2 List.fold_left [] l_sinks (fun acc l_sink ->
      let l_calls = Mdg.get_function_callers engine.mdg l_sink in
      List.map (fun l_call -> (l_call, l_sink)) l_calls @ acc )

let tainted_sink_args (engine : t) (l_call : Node.t) (sink : Taint.Sink.t) :
    Node.Set.t =
  Mdg.get_arguments engine.mdg l_call
  |> List.filter (fun (idx, _) -> List.mem idx sink.args)
  |> List.map (fun (_, l_arg) -> l_arg)
  |> Node.Set.of_list

let dynamic_lookups (engine : t) : Node.Set.t =
  let prop_f edge = Edge.is_property ~prop:Dynamic edge in
  Fun.flip2 Hashtbl.fold engine.mdg.edges Node.Set.empty (fun _ edges acc ->
      Fun.flip2 Edge.Set.fold edges acc (fun edge acc' ->
          if prop_f edge then Node.Set.add edge.tar acc' else acc' ) )

let object_versions (engine : t) (l_obj : Node.t) : Node.Set.t =
  let version_f acc (prop, node) =
    if Property.is_dynamic prop && not (Node.Set.mem node acc) then Some node
    else None in
  let rec traverse node acc =
    let versions = Mdg.get_versions engine.mdg node in
    let versions' = List.filter_map (version_f acc) versions in
    let ls_lookup = Node.Set.of_list versions' in
    let acc' = Node.Set.union acc ls_lookup in
    Node.Set.fold traverse ls_lookup acc' in
  traverse l_obj (Node.Set.singleton l_obj) |> Node.Set.remove l_obj
