let mark_exports (state : State.t) (exported : Exported.t) (l_taint : Node.t) :
    unit =
  Fun.flip Hashtbl.iter exported (fun _ (l_exported, _) ->
      match l_exported.kind with
      | Blank _ | Object _ | Function _ | TaintSink _ ->
        Mdg.add_edge state.mdg (Edge.create_dependency () l_taint l_exported)
      | _ -> () )

let is_tainted (ls_tainted : Node.Set.t) (node : Node.t) : bool =
  Node.Set.mem node ls_tainted

let taint (ls_tainted : Node.Set.t) (node : Node.t) : Node.Set.t =
  Node.Set.add node ls_tainted

let rec mark_nodes (state : State.t) (queue : Node.t Queue.t)
    (tainted : Node.Set.t) : Node.Set.t =
  Option.fold (Queue.take_opt queue) ~none:tainted ~some:(fun node ->
      let loc = Node.loc node in
      let edges = Mdg.get_edges state.mdg loc in
      let ls_tainted = Edge.Set.fold (mark_edge state queue) edges tainted in
      mark_nodes state queue ls_tainted )

and mark_edge (state : State.t) (queue : Node.t Queue.t) (edge : Edge.t)
    (tainted : Node.Set.t) : Node.Set.t =
  match edge.kind with
  | Dependency -> mark_next queue edge.tar tainted
  | Property _ -> mark_prop state queue edge tainted
  | Version _ -> mark_next queue edge.tar tainted
  | Parameter _ -> mark_next queue edge.tar tainted
  | Argument _ -> mark_call state queue edge.tar tainted
  | _ -> tainted

and mark_next (queue : Node.t Queue.t) (node : Node.t) (tainted : Node.Set.t) :
    Node.Set.t =
  if not (is_tainted tainted node) then (
    Queue.add node queue;
    taint tainted node )
  else tainted

and mark_prop (state : State.t) (queue : Node.t Queue.t) (edge : Edge.t)
    (ls_tainted : Node.Set.t) : Node.Set.t =
  let ls_obj = Node.Set.singleton edge.src in
  let ls_orig = Mdg.object_orig_versions state.mdg edge.src in
  if Node.Set.equal ls_obj ls_orig then mark_next queue edge.tar ls_tainted
  else ls_tainted

and mark_call (state : State.t) (queue : Node.t Queue.t) (node : Node.t)
    (ls_tainted : Node.Set.t) : Node.Set.t =
  match state.env.func_eval_mode with
  | Opaque -> ls_tainted
  | Unfold | UnfoldRec | UnfoldDepth _ ->
    let l_retn = Mdg.get_return_of_call state.mdg node in
    let ls_tainted' = Node.Set.add node ls_tainted in
    mark_next queue l_retn ls_tainted'

let compute (state : State.t) (exported : Exported.t) : Node.Set.t =
  let l_taint = Jslib.find state.mdg state.jslib "taint" in
  mark_exports state exported l_taint;
  let ls_tainted = Node.Set.singleton l_taint in
  let queue = Queue.create () in
  Queue.push l_taint queue;
  mark_nodes state queue ls_tainted
