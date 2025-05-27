module Env = struct
  type cb_unfold_func = State.t -> Node.t -> State.t

  type return_handler =
    | GraphEdge
    | Unfold of cb_unfold_func

  type t = { return_handler : return_handler }

  let create (return_handler : return_handler) : t = { return_handler }
end

module Interaction = struct
  type t =
    | Lookup of Property.t
    | Call

  let lookup (prop : Property.t) : t = Lookup prop

  let pp (ppf : Fmt.t) (itx : t) : unit =
    match itx with
    | Lookup (Static prop) -> Fmt.fmt ppf ".%s" prop
    | Lookup Dynamic -> Fmt.pp_str ppf ".*"
    | Call -> Fmt.pp_str ppf "()"

  let str (itx : t) : string = Fmt.str "%a" pp itx
end

module Scheme = struct
  type t = Interaction.t list

  let extend (prev : t) (next : t) : t = prev @ next

  let pp (ppf : Fmt.t) (scheme : t) : unit =
    Fmt.fmt ppf "<EObj>%a" Fmt.(pp_lst !>"" Interaction.pp) scheme

  let str (scheme : t) : string = Fmt.str "%a" pp scheme
end

type t = (Location.t, Node.t * Scheme.t) Hashtbl.t
type acc = (Node.t * Scheme.t) list

let create () : t = Hashtbl.create Config.(!dflt_htbl_sz)
let is_empty (exported : t) : bool = Hashtbl.length exported == 0

let mem (exported : t) (l_node : Node.t) : bool =
  Hashtbl.mem exported l_node.loc

let find (exported : t) (l_node : Node.t) : Scheme.t option =
  Option.map snd (Hashtbl.find_opt exported l_node.loc)

let replace (exported : t) (l_node : Node.t) (scheme : Scheme.t) : unit =
  Hashtbl.replace exported l_node.loc (l_node, scheme)

let pp (ppf : Fmt.t) (exported : t) : unit =
  let pp_itx ppf (_, (l_node, scheme)) =
    Fmt.fmt ppf "%a -> %a" Node.pp l_node Scheme.pp scheme in
  Fmt.(pp_htbl !>"@\n") pp_itx ppf exported

let str (exported : t) : string = Fmt.str "%a" pp exported

let add_interactable (exported : t) (acc : acc) (l_node : Node.t)
    (scheme : Scheme.t) : acc =
  match find exported l_node with
  | None -> replace exported l_node scheme |> fun () -> (l_node, scheme) :: acc
  | Some _ -> acc

let compute_lookups (state : State.t) (exported : t) (prev : Scheme.t)
    (ls_obj : Node.Set.t) : acc =
  let props_f (props, l_node) acc =
    List.map Interaction.lookup props
    |> Scheme.extend prev
    |> add_interactable exported acc l_node in
  Fun.flip2 Node.Set.fold ls_obj [] (fun l_node acc ->
      Mdg.object_nested_traversal props_f state.mdg l_node acc )

let compute_returns_graph (state : State.t) (l_func : Node.t)
    (scheme : Scheme.t) (acc : acc) : acc =
  let ls_retn = Mdg.get_function_returns state.mdg l_func in
  Fun.flip2 List.fold_left acc ls_retn (fun acc l_retn ->
      let scheme' = Scheme.extend scheme [ Call ] in
      (l_retn, scheme') :: acc )

let compute_returns_unfold (cb_unfold_func : Env.cb_unfold_func)
    (state : State.t) (l_func : Node.t) (scheme : Scheme.t) (acc : acc) : acc =
  let state' = cb_unfold_func state l_func in
  Fun.flip2 Node.Set.fold state'.curr_return acc (fun l_retn acc ->
      let scheme' = Scheme.extend scheme [ Call ] in
      (l_retn, scheme') :: acc )

let compute_returns_dispatch (env : Env.t) :
    State.t -> Node.t -> Scheme.t -> acc -> acc =
  match env.return_handler with
  | GraphEdge -> compute_returns_graph
  | Unfold cb_unfold_func -> compute_returns_unfold cb_unfold_func

let compute_returns (env : Env.t) (state : State.t) (props : acc) : acc =
  let compute_func_f = compute_returns_dispatch env in
  let funcs = List.filter (fun (node, _) -> Node.is_function node) props in
  Fun.flip2 List.fold_left [] funcs (fun acc (l_func, scheme) ->
      compute_func_f state l_func scheme acc )

let rec compute_object (env : Env.t) (state : State.t) (exported : t)
    (prev : Scheme.t) (ls_exported : Node.Set.t) : unit =
  compute_lookups state exported prev ls_exported
  |> compute_returns env state
  |> compute_returns_rec env state exported

and compute_returns_rec (env : Env.t) (state : State.t) (exported : t)
    (returns : acc) : unit =
  Fun.flip List.iter returns (fun (l_retn, scheme) ->
      if not (mem exported l_retn) then
        compute_object env state exported scheme (Node.Set.singleton l_retn) )

let empty_exports (state : State.t) (ls_exported : Node.Set.t) : bool =
  if Node.Set.cardinal ls_exported == 1 then
    let l_exported = Node.Set.choose ls_exported in
    let l_exported_orig = Jslib.find state.mdg state.jslib "exports" in
    let l_exported_edges = Mdg.get_edges state.mdg l_exported.loc in
    Node.equal l_exported l_exported_orig
    && Edge.Set.cardinal l_exported_edges == 0
  else false

let compute (env : Env.t) (state : State.t) : t =
  let exported = create () in
  let ls_exported = Jslib.exported_object state.mdg state.jslib in
  if not (empty_exports state ls_exported) then
    compute_object env state exported [] ls_exported;
  exported

let compute_from_graph (state : State.t) : t =
  let env = Env.create GraphEdge in
  compute env state

let compute_and_unfold (cb_unfold : Env.cb_unfold_func) (state : State.t) : t =
  let env = Env.create (Unfold cb_unfold) in
  compute env state
