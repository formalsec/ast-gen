let is_excess_exports (mdg : Mdg.t) (l_exports : Node.t) : bool =
  let edges = Mdg.get_edges mdg l_exports.loc in
  let trans = Mdg.get_trans mdg l_exports.loc in
  Edge.Set.is_empty edges && Edge.Set.cardinal trans == 1

let is_excess_module (mdg : Mdg.t) (l_module : Node.t) : bool =
  let edges = Mdg.get_edges mdg l_module.loc in
  let trans = Mdg.get_trans mdg l_module.loc in
  Edge.Set.cardinal edges == 1
  && Edge.Set.is_empty trans
  && is_excess_exports mdg (Edge.Set.choose edges).tar

let is_excess_builtin_prop (mdg : Mdg.t) (l_prop : Node.t) : bool =
  let edges = Mdg.get_edges mdg l_prop.loc in
  let trans = Mdg.get_trans mdg l_prop.loc in
  Edge.Set.is_empty edges && Edge.Set.cardinal trans == 1

let is_excess_builtin (mdg : Mdg.t) (l_builtin : Node.t) : bool =
  let edges = Mdg.get_edges mdg l_builtin.loc in
  let trans = Mdg.get_trans mdg l_builtin.loc in
  let prop_edges = Edge.Set.filter Edge.is_property edges in
  Edge.Set.equal edges prop_edges
  && Edge.Set.is_empty trans
  && Fun.flip Edge.Set.for_all prop_edges (fun edge ->
         is_excess_builtin_prop mdg edge.tar )

let is_excess_this (mdg : Mdg.t) (l_this : Node.t) : bool =
  let edges = Mdg.get_edges mdg l_this.loc in
  let trans = Mdg.get_trans mdg l_this.loc in
  Edge.Set.is_empty edges && Edge.Set.cardinal trans == 1

let is_excess_sink (mdg : Mdg.t) (l_sink : Node.t) : bool =
  let edges = Mdg.get_edges mdg l_sink.loc in
  let trans = Mdg.get_trans mdg l_sink.loc in
  Edge.Set.is_empty edges && Edge.Set.is_empty trans

let compute_excess_jslib (state : State.t) (acc : Node.t list) : Node.t list =
  Fun.flip2 Hashtbl.fold state.jslib acc (fun _ node acc ->
      match node.kind with
      | Object "module" when is_excess_module state.mdg node ->
        let prop = Property.Static "exports" in
        let l_exports = Mdg.get_property state.mdg node prop in
        (node :: l_exports) @ acc
      | Builtin _ when is_excess_builtin state.mdg node ->
        let props = Mdg.get_properties state.mdg node in
        let ls_props = List.map snd props in
        (node :: ls_props) @ acc
      | TaintSink _ when is_excess_sink state.mdg node -> node :: acc
      | TaintSource -> node :: acc
      | _ -> acc )

let compute_excess_this (state : State.t) (acc : Node.t list) : Node.t list =
  Fun.flip2 Hashtbl.fold state.mdg.nodes acc (fun _ node acc ->
      match node.kind with
      | Parameter "this" when is_excess_this state.mdg node -> node :: acc
      | _ -> acc )

let compute (state : State.t) : unit =
  compute_excess_jslib state []
  |> compute_excess_this state
  |> Mdg.remove_nodes state.mdg
