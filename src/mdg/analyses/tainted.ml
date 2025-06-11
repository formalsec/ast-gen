type queue = (Node.t * bool) Queue.t

module PolicyTable = struct
  module Tbl = Hashtbl.Make (struct
    type t = Jsmodel.TaintPolicy.kind * string

    let hash ((kind, name) : t) : int =
      Hashtbl.hash (Hashtbl.hash kind, String.hash name)

    let equal ((kind1, name1) : t) ((kind2, name2) : t) : bool =
      match (kind1, kind2) with
      | (`ProtoMethodPolicy, `ProtoMethodPolicy) -> String.equal name1 name2
      | (`BuiltinMethodPolicy builtin1, `BuiltinMethodPolicy builtin2) ->
        Option.equal String.equal builtin1 builtin2 && String.equal name1 name2
      | (`PackageMethodPolicy package1, `PackageMethodPolicy package2) ->
        Option.equal String.equal package1 package2 && String.equal name1 name2
      | _ -> false
  end)

  include Tbl

  type source = Jsmodel.TaintPolicy.source
  type target = Jsmodel.TaintPolicy.target
  type policy = source * target list
  type t = policy Tbl.t

  let resolve_method (mdg : Mdg.t) (l_func : Node.t) (func : string) :
      Jsmodel.TaintPolicy.kind * string =
    match Mdg.get_property_owner mdg l_func with
    | [ (Static prop, { kind = Builtin builtin; _ }) ] ->
      (`BuiltinMethodPolicy (Some builtin), prop)
    | [ (Static prop, { kind = Module package; _ }) ] ->
      (`PackageMethodPolicy (Some package), prop)
    | _ -> (`ProtoMethodPolicy, func)

  let resolve (mdg : Mdg.t) (l_call : Node.t) (func : string) :
      Jsmodel.TaintPolicy.kind * string =
    match Mdg.get_called_functions mdg l_call with
    | [ { kind = Builtin builtin; _ } ] -> (`BuiltinMethodPolicy None, builtin)
    | [ { kind = Module package; _ } ] -> (`PackageMethodPolicy None, package)
    | [ l_func ] -> resolve_method mdg l_func func
    | _ -> (`ProtoMethodPolicy, func)
end

type t =
  { map : (Location.t, Node.t * bool) Hashtbl.t
  ; policies : PolicyTable.t
  }

let none () : t =
  let map = Hashtbl.create Config.(!dflt_htbl_sz) in
  let policies = PolicyTable.create Config.(!dflt_htbl_sz) in
  { map; policies }

let create (jsmodel : Jsmodel.TaintPolicy.t list) : t =
  let tainted = none () in
  Fun.flip List.iter jsmodel (fun policy ->
      PolicyTable.add tainted.policies (policy.kind, policy.name)
        (policy.source, policy.targets) );
  tainted

let is_tainted (tainted : t) (node : Node.t) : bool =
  Hashtbl.mem tainted.map node.loc

let set_tainted (tainted : t) (node : Node.t) (strong : bool) : unit =
  Hashtbl.replace tainted.map node.loc (node, strong)

let get_tainted (tainted : t) : Node.Set.t =
  Fun.flip2 Hashtbl.fold tainted.map Node.Set.empty (fun _ (l_tainted, _) acc ->
      Node.Set.add l_tainted acc )

let propagate (tainted : t) (node : Node.t) (strong : bool) : bool =
  match Hashtbl.find_opt tainted.map node.loc with
  | Some (_, strong') -> strong && not strong'
  | None -> true

let mark_tainted_exports (state : State.t) (exported : Exported.t)
    (l_taint : Node.t) : unit =
  Fun.flip Hashtbl.iter exported (fun _ (l_exported, _) ->
      Mdg.add_edge state.mdg (Edge.create_dependency () l_taint l_exported) )

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
  let seg = String.split_on_char '.' (Node.name edge.tar) in
  let len = List.length seg in
  let func = List.nth seg (len - 1) in
  let arg = Edge.argument edge in
  let args = Mdg.get_arguments state.mdg edge.tar in
  let retn = Mdg.get_return_of_call state.mdg edge.tar in
  let args' = (-1, retn) :: args in
  let targets = mark_tainted_policy state tainted edge.tar func arg in
  set_tainted tainted edge.tar true;
  mark_tainted_policy_targets state queue tainted targets args'

and mark_tainted_policy (state : State.t) (tainted : t) (l_call : Node.t)
    (func : string) (arg : int) : Jsmodel.TaintPolicy.target list =
  let (kind, name) = PolicyTable.resolve state.mdg l_call func in
  let policy = PolicyTable.find_all tainted.policies (kind, name) in
  Fun.flip2 List.fold_left [] policy (fun acc (source, targets) ->
      match source with
      | `This when arg == 0 -> targets @ acc
      | `Arg idx when arg == idx -> targets @ acc
      | `Args idx when arg >= idx -> targets @ acc
      | _ -> acc )

and mark_tainted_policy_targets (state : State.t) (queue : queue) (tainted : t)
    (targets : Jsmodel.TaintPolicy.target list) (args : (int * Node.t) list) =
  Fun.flip List.iter (List.product targets args) (fun (target, (idx, node)) ->
      match target with
      | `This when idx == 0 -> mark_tainted_next queue tainted node true
      | `Retn when idx == -1 -> mark_tainted_next queue tainted node true
      | `Arg idx' when idx == idx' -> mark_tainted_next queue tainted node true
      | `Args idx' when idx >= idx' -> mark_tainted_next queue tainted node true
      | `FArg (idx', target') when idx == idx' ->
        let params = Mdg.get_parameters state.mdg node in
        mark_tainted_policy_targets state queue tainted [ target' ] params
      | _ -> () )

let compute (state : State.t) (model : Jsmodel.t) (exported : Exported.t) : t =
  let l_taint = Jslib.find_node state.mdg state.jslib "taint" in
  mark_tainted_exports state exported l_taint;
  let tainted = create model.policies in
  let queue = Queue.create () in
  Queue.push (l_taint, true) queue;
  mark_tainted_nodes state queue tainted;
  tainted
