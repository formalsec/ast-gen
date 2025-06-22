let is_taint_source (state : State.t) (l_taint : Node.t) : bool =
  let l_taint' = Jslib.find_node state.mdg state.jslib "taint" in
  Node.equal l_taint l_taint'

let is_excess_taint_source (state : State.t) (l_taint : Node.t) : bool =
  let trans = Mdg.get_trans state.mdg l_taint.loc in
  Edge.Set.cardinal trans == 1
  && is_taint_source state (Edge.Set.choose trans).tar

let is_excess_exports (state : State.t) (l_exports : Node.t) : bool =
  let edges = Mdg.get_edges state.mdg l_exports.loc in
  let trans = Mdg.get_trans state.mdg l_exports.loc in
  Edge.Set.is_empty edges && Edge.Set.cardinal trans == 1

let is_excess_module (state : State.t) (l_module : Node.t) : bool =
  let edges = Mdg.get_edges state.mdg l_module.loc in
  let trans = Mdg.get_trans state.mdg l_module.loc in
  Edge.Set.cardinal edges == 1
  && Edge.Set.is_empty trans
  && is_excess_exports state (Edge.Set.choose edges).tar

let is_excess_object (state : State.t) (l_obj : Node.t) : bool =
  let edges = Mdg.get_edges state.mdg l_obj.loc in
  let trans = Mdg.get_trans state.mdg l_obj.loc in
  Edge.Set.is_empty edges
  && (Edge.Set.is_empty trans || is_excess_taint_source state l_obj)

let is_excess_builtin_prop (state : State.t) (l_prop : Node.t) : bool =
  let edges = Mdg.get_edges state.mdg l_prop.loc in
  let trans = Mdg.get_trans state.mdg l_prop.loc in
  Edge.Set.is_empty edges && Edge.Set.cardinal trans == 1

let is_excess_builtin (state : State.t) (l_builtin : Node.t) : bool =
  let edges = Mdg.get_edges state.mdg l_builtin.loc in
  let trans = Mdg.get_trans state.mdg l_builtin.loc in
  let prop_edges = Edge.Set.filter Edge.is_property edges in
  Edge.Set.equal edges prop_edges
  && (Edge.Set.is_empty trans || is_excess_taint_source state l_builtin)
  && Fun.flip Edge.Set.for_all prop_edges (fun edge ->
         is_excess_builtin_prop state edge.tar )

let is_excess_this (state : State.t) (l_this : Node.t) : bool =
  let edges = Mdg.get_edges state.mdg l_this.loc in
  let trans = Mdg.get_trans state.mdg l_this.loc in
  Edge.Set.is_empty edges && Edge.Set.cardinal trans == 1

let is_excess_sink (state : State.t) (l_sink : Node.t) : bool =
  let edges = Mdg.get_edges state.mdg l_sink.loc in
  let trans = Mdg.get_trans state.mdg l_sink.loc in
  Edge.Set.is_empty edges && Edge.Set.is_empty trans

let compute_excess_jslib (state : State.t) (acc : Node.t list) : Node.t list =
  Fun.flip2 Hashtbl.fold state.jslib acc (fun _ node acc ->
      match node.kind with
      | Object "module" when is_excess_module state node ->
        let prop = Property.Static "exports" in
        let l_exports = Mdg.get_property state.mdg node prop in
        (node :: l_exports) @ acc
      | Object "exports" -> acc
      | Object _ when is_excess_object state node -> node :: acc
      | Builtin _ when is_excess_builtin state node ->
        let props = Mdg.get_properties state.mdg node in
        let ls_props = List.map snd props in
        (node :: ls_props) @ acc
      | TaintSink _ when is_excess_sink state node -> node :: acc
      | TaintSource -> node :: acc
      | _ -> acc )

let compute_excess_this (state : State.t) (acc : Node.t list) : Node.t list =
  Fun.flip2 Hashtbl.fold state.mdg.nodes acc (fun _ node acc ->
      match node.kind with
      | Parameter "this" when is_excess_this state node -> node :: acc
      | _ -> acc )

let compute (state : State.t) : unit =
  compute_excess_jslib state []
  |> compute_excess_this state
  |> Mdg.remove_nodes state.mdg
