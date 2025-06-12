open Graphjs_mdg

type t =
  { mdg : Mdg.t
  ; tainted : Tainted.t
  }

let initialize (e_mdg : Builder.ExtendedMdg.t) : t =
  { mdg = e_mdg.mdg; tainted = e_mdg.tainted }

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
  Fun.flip2 Hashtbl.fold engine.mdg.edges Node.Set.empty (fun _ edges acc ->
      Fun.flip2 Edge.Set.fold edges acc (fun edge acc ->
          if Edge.is_property ~prop:Dynamic edge then Node.Set.add edge.tar acc
          else acc ) )

let dynamic_updates (engine : t) : Node.Set.t =
  Fun.flip2 Hashtbl.fold engine.mdg.edges Node.Set.empty (fun _ edges acc ->
      Fun.flip2 Edge.Set.fold edges acc (fun edge acc' ->
          let equal_f edge = Node.equal (Edge.src edge) (Edge.tar edge) in
          if Edge.is_version ~prop:Dynamic edge && not (equal_f edge) then
            Node.Set.add edge.tar acc'
          else acc' ) )
