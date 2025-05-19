open Graphjs_base

let is_tainted (tainted : Node.Set.t) (node : Node.t) : bool =
  Node.Set.mem node tainted

let taint (tainted : Node.Set.t) (node : Node.t) : Node.Set.t =
  Node.Set.add node tainted

let set_tainted_exports (mdg : Mdg.t) (exported : Exported.t) : Node.t =
  let l_taint = Node.create_taint_source () in
  Mdg.add_node mdg l_taint;
  Fun.flip Hashtbl.iter exported (fun _ (l_node, _) ->
      match l_node.kind with
      | Object _ | Function _ | TaintSink _ ->
        Mdg.add_edge mdg (Edge.create_dependency () l_taint l_node)
      | _ -> () );
  l_taint

let mark_taint (queue : Node.t Queue.t) (node : Node.t) (tainted : Node.Set.t) :
    Node.Set.t =
  if not (is_tainted tainted node) then (
    Queue.add node queue;
    taint tainted node )
  else tainted

let rec mark_nodes (mdg : Mdg.t) (queue : Node.t Queue.t) (tainted : Node.Set.t)
    : Node.Set.t =
  Option.fold (Queue.take_opt queue) ~none:tainted ~some:(fun l_node ->
      let loc = Node.loc l_node in
      let edges = Mdg.get_edges mdg loc in
      let tainted' = Edge.Set.fold (mark_edge mdg queue) edges tainted in
      mark_nodes mdg queue tainted' )

and mark_edge (mdg : Mdg.t) (queue : Node.t Queue.t) (edge : Edge.t)
    (tainted : Node.Set.t) : Node.Set.t =
  match edge.kind with
  | Dependency -> mark_taint queue edge.tar tainted
  | Property _ -> mark_taint_prop mdg queue edge tainted
  | Version _ -> mark_taint queue edge.tar tainted
  | Parameter _ -> mark_taint queue edge.tar tainted
  | _ -> tainted

and mark_taint_prop (mdg : Mdg.t) (queue : Node.t Queue.t) (edge : Edge.t)
    (tainted : Node.Set.t) : Node.Set.t =
  let ls_obj = Node.Set.singleton edge.src in
  let ls_orig = Mdg.object_orig_versions mdg edge.src in
  if Node.Set.equal ls_obj ls_orig then mark_taint queue edge.tar tainted
  else tainted

let mark_tainted (mdg : Mdg.t) (tainted : Node.Set.t) (l_taint : Node.t) :
    Node.Set.t =
  let queue = Queue.create () in
  Queue.push l_taint queue;
  mark_nodes mdg queue tainted

let compute (state : State.t) (exported : Exported.t) : Node.Set.t =
  if not (Exported.is_empty exported) then
    let tainted = Node.Set.empty in
    let l_taint = set_tainted_exports state.mdg exported in
    mark_tainted state.mdg tainted l_taint
  else Node.Set.empty
