type queue = (Node.t * bool) Queue.t
type t = (Location.t, Node.t * bool) Hashtbl.t

let create () : t = Hashtbl.create Config.(!dflt_htbl_sz)
let none () : t = Hashtbl.create Config.(!dflt_htbl_sz)

let is_tainted (tainted : t) (node : Node.t) : bool =
  Hashtbl.mem tainted node.loc

let set_tainted (tainted : t) (node : Node.t) (strong : bool) : unit =
  Hashtbl.replace tainted node.loc (node, strong)

let get_tainted (tainted : t) : Node.Set.t =
  Fun.flip2 Hashtbl.fold tainted Node.Set.empty (fun _ (l_tainted, _) acc ->
      Node.Set.add l_tainted acc )

let propagate (tainted : t) (node : Node.t) (strong : bool) : bool =
  match Hashtbl.find_opt tainted node.loc with
  | Some (_, strong') -> strong && not strong'
  | None -> true

let mark_tainted_exports (state : State.t) (exported : Exported.t)
    (l_taint : Node.t) : unit =
  Fun.flip Hashtbl.iter exported (fun _ (l_exported, _) ->
      match l_exported.kind with
      | Blank _ | Object _ | Function _ | Module _ | TaintSink _ ->
        Mdg.add_edge state.mdg (Edge.create_dependency () l_taint l_exported)
      | _ -> () )

let rec mark_tainted_nodes (state : State.t) (queue : queue) (tainted : t) :
    unit =
  Fun.flip Option.iter (Queue.take_opt queue) (fun (node, strong) ->
      let loc = Node.loc node in
      let edges = Mdg.get_edges state.mdg loc in
      let trans = Mdg.get_trans state.mdg loc in
      Edge.Set.iter (mark_tainted_edge state queue tainted strong) edges;
      Edge.Set.iter (mark_tainted_tran state queue tainted strong) trans;
      mark_tainted_nodes state queue tainted )

and mark_tainted_edge (state : State.t) (queue : queue) (tainted : t)
    (strong : bool) (edge : Edge.t) : unit =
  Log.debug "%a" Edge.pp edge;
  match edge.kind with
  | Dependency -> mark_tainted_next queue tainted edge.tar strong
  | Property _ when strong -> mark_tainted_prop state queue tainted edge
  | Version _ -> mark_tainted_next queue tainted edge.tar false
  | Parameter _ -> mark_tainted_next queue tainted edge.tar true
  | Argument _ -> mark_tainted_call state queue tainted edge
  | _ -> ()

and mark_tainted_tran (_ : State.t) (queue : queue) (tainted : t) (_ : bool)
    (edge : Edge.t) : unit =
  match edge.kind with
  | Property _ -> mark_tainted_next queue tainted edge.tar false
  | _ -> ()

and mark_tainted_next (queue : queue) (tainted : t) (node : Node.t)
    (strong : bool) : unit =
  if propagate tainted node strong then (
    Queue.add (node, strong) queue;
    set_tainted tainted node strong )

and mark_tainted_prop (state : State.t) (queue : queue) (tainted : t)
    (edge : Edge.t) : unit =
  let ls_orig = Mdg.object_orig_versions state.mdg edge.src in
  if Node.Set.mem edge.src ls_orig then
    mark_tainted_next queue tainted edge.tar true

and mark_tainted_call (state : State.t) (queue : queue) (tainted : t)
    (edge : Edge.t) : unit =
  let call_name = Node.name edge.tar in
  let segs = String.split_on_char '.' call_name in
  let segs_len = List.length segs in
  let func = List.nth segs (segs_len - 1) in
  let arg_idx = Edge.argument edge in
  mark_tainted_call_components state queue tainted edge
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

and mark_tainted_call_components (state : State.t) (queue : queue) (tainted : t)
    (edge : Edge.t) (to_mark : int list) : unit =
  let ls_args = Mdg.get_arguments state.mdg edge.tar in
  let l_retn = Mdg.get_return_of_call state.mdg edge.tar in
  let components = (-1, l_retn) :: ls_args in
  set_tainted tainted edge.tar true;
  Fun.flip List.iter to_mark (fun idx ->
      let matched = List.find_all (fun (idx', _) -> idx == idx') components in
      Fun.flip List.iter matched (fun (_, node) ->
          mark_tainted_next queue tainted node true ) )

let compute (state : State.t) (exported : Exported.t) : t =
  let l_taint = Jslib.find state.mdg state.jslib "taint" in
  mark_tainted_exports state exported l_taint;
  let tainted = create () in
  let queue = Queue.create () in
  Queue.push (l_taint, true) queue;
  mark_tainted_nodes state queue tainted;
  tainted
