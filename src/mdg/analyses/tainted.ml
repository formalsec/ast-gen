type queue = (Node.t * bool) Queue.t

let mark_tainted_exports (state : State.t) (exported : Exported.t)
    (l_taint : Node.t) : unit =
  Fun.flip Hashtbl.iter exported (fun _ (l_exported, _) ->
      match l_exported.kind with
      | Blank _ | Object _ | Function _ | Module _ | TaintSink _ ->
        Mdg.add_edge state.mdg (Edge.create_dependency () l_taint l_exported)
      | _ -> () )

let is_tainted (ls_tainted : Node.Set.t) (node : Node.t) : bool =
  Node.Set.mem node ls_tainted

let taint (ls_tainted : Node.Set.t) (node : Node.t) : Node.Set.t =
  Node.Set.add node ls_tainted

let rec mark_nodes (state : State.t) (queue : queue) (ls_tainted : Node.Set.t) :
    Node.Set.t =
  Option.fold (Queue.take_opt queue) ~none:ls_tainted
    ~some:(fun (node, strong) ->
      let loc = Node.loc node in
      let edges = Mdg.get_edges state.mdg loc in
      let trans = Mdg.get_trans state.mdg loc in
      let mark_edge_f = mark_edge state queue strong in
      let mark_trans_f = mark_trans state queue in
      let ls_tainted' = Edge.Set.fold mark_edge_f edges ls_tainted in
      let ls_tainted'' = Edge.Set.fold mark_trans_f trans ls_tainted' in
      mark_nodes state queue ls_tainted'' )

and mark_edge (state : State.t) (queue : queue) (strong : bool) (edge : Edge.t)
    (ls_tainted : Node.Set.t) : Node.Set.t =
  match edge.kind with
  | Dependency -> mark_next queue edge.tar strong ls_tainted
  | Property _ when strong -> mark_next queue edge.tar strong ls_tainted
  | Version _ -> mark_next queue edge.tar false ls_tainted
  | Parameter _ -> mark_next queue edge.tar true ls_tainted
  | Argument _ -> mark_call state queue edge ls_tainted
  | _ -> ls_tainted

and mark_trans (_ : State.t) (queue : queue) (edge : Edge.t)
    (ls_tainted : Node.Set.t) : Node.Set.t =
  match edge.kind with
  | Property _ -> mark_next queue edge.tar false ls_tainted
  | _ -> ls_tainted

and mark_next (queue : queue) (node : Node.t) (strong : bool)
    (ls_tainted : Node.Set.t) : Node.Set.t =
  if not (is_tainted ls_tainted node) then (
    Queue.add (node, strong) queue;
    taint ls_tainted node )
  else ls_tainted

and mark_call (state : State.t) (queue : queue) (edge : Edge.t)
    (ls_tainted : Node.Set.t) : Node.Set.t =
  let call_name = Node.name edge.tar in
  let segs = String.split_on_char '.' call_name in
  let segs_len = List.length segs in
  let func = List.nth segs (segs_len - 1) in
  let arg_idx = Edge.argument edge in
  mark_call_components state queue edge ls_tainted
    ( if segs_len == 1 then mark_func_call_policy func arg_idx
      else mark_method_call_policy func arg_idx )

and mark_func_call_policy (func : string) (arg : int) : int list =
  match (func, arg) with _ -> [ -1 ]

and mark_method_call_policy (func : string) (arg : int) : int list =
  match (func, arg) with
  | ("forEach", 0) -> [ 1 ]
  | ("map", 0) -> [ 1 ]
  | ("push", 1) -> [ 0 ]
  | ("get", _) -> [ -1; 2 ]
  | ("post", _) -> [ 2 ]
  | _ -> [ -1 ]

and mark_call_components (state : State.t) (queue : queue) (edge : Edge.t)
    (ls_tainted : Node.Set.t) (to_mark : int list) : Node.Set.t =
  let ls_args = Mdg.get_arguments state.mdg edge.tar in
  let l_retn = Mdg.get_return_of_call state.mdg edge.tar in
  let components = (-1, l_retn) :: ls_args in
  let ls_tainted' = Node.Set.add edge.tar ls_tainted in
  Fun.flip2 List.fold_left ls_tainted' to_mark (fun acc idx ->
      let matched = List.find_all (fun (idx', _) -> idx == idx') components in
      Fun.flip2 List.fold_left acc matched (fun acc (_, node) ->
          mark_next queue node true acc ) )

let compute (state : State.t) (exported : Exported.t) : Node.Set.t =
  let l_taint = Jslib.find state.mdg state.jslib "taint" in
  mark_tainted_exports state exported l_taint;
  let ls_tainted = Node.Set.singleton l_taint in
  let queue = Queue.create () in
  Queue.push (l_taint, true) queue;
  mark_nodes state queue ls_tainted
