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

  let pp (ppf : Fmt.t) (interaction : t) : unit =
    match interaction with
    | Lookup (Static prop) -> Fmt.fmt ppf ".%s" prop
    | Lookup Dynamic -> Fmt.pp_str ppf ".*"
    | Call -> Fmt.pp_str ppf "()"

  let str (interaction : t) : string = Fmt.str "%a" pp interaction
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
let mem (exported : t) (node : Node.t) : bool = Hashtbl.mem exported node.loc

let find (exported : t) (node : Node.t) : Scheme.t option =
  Option.map snd (Hashtbl.find_opt exported node.loc)

let replace (exported : t) (node : Node.t) (scheme : Scheme.t) : unit =
  Hashtbl.replace exported node.loc (node, scheme)

let pp (ppf : Fmt.t) (exported : t) : unit =
  let pp_interaction ppf (_, (node, scheme)) =
    Fmt.fmt ppf "%a -> %a" Node.pp node Scheme.pp scheme in
  Fmt.(pp_htbl !>"@\n") pp_interaction ppf exported

let str (exported : t) : string = Fmt.str "%a" pp exported

let empty_exports (state : State.t) (ls_exported : Node.Set.t) : bool =
  (* the ls_exported contains one element when empty (jslib exports node) *)
  if Node.Set.cardinal ls_exported == 1 then
    let l_exported = Node.Set.choose ls_exported in
    let l_exported_orig = Jslib.find state.mdg state.jslib "exports" in
    let l_exported_edges = Mdg.get_edges state.mdg l_exported.loc in
    Node.equal l_exported l_exported_orig
    && Edge.Set.cardinal l_exported_edges == 0
  else false

let add_exported (exported : t) (acc : acc) (l_exported : Node.t)
    (scheme : Scheme.t) : acc =
  if not (mem exported l_exported) then (
    replace exported l_exported scheme;
    (l_exported, scheme) :: acc )
  else acc

let compute_lookups (state : State.t) (exported : t) (prev : Scheme.t)
    (ls_obj : Node.Set.t) : acc =
  let props_f (props, l_prop) acc =
    List.map Interaction.lookup props
    |> Scheme.extend prev
    |> add_exported exported acc l_prop in
  Fun.flip2 Node.Set.fold ls_obj [] (fun l_obj acc ->
      Mdg.object_nested_traversal props_f state.mdg l_obj acc )

let compute_functions_graph (state : State.t) (l_func : Node.t)
    (scheme : Scheme.t) (acc : acc) : acc =
  let ls_retn = Mdg.get_function_returns state.mdg l_func in
  Fun.flip2 List.fold_left acc ls_retn (fun acc l_retn ->
      let scheme' = Scheme.extend scheme [ Call ] in
      (l_retn, scheme') :: acc )

let compute_functions_unfold (cb_unfold_func : Env.cb_unfold_func)
    (state : State.t) (l_func : Node.t) (scheme : Scheme.t) (acc : acc) : acc =
  let state' = cb_unfold_func state l_func in
  Fun.flip2 Node.Set.fold state'.curr_return acc (fun l_retn acc ->
      let scheme' = Scheme.extend scheme [ Call ] in
      (l_retn, scheme') :: acc )

let compute_functions_dispatch (env : Env.t) :
    State.t -> Node.t -> Scheme.t -> acc -> acc =
  match env.return_handler with
  | GraphEdge -> compute_functions_graph
  | Unfold cb_unfold_func -> compute_functions_unfold cb_unfold_func

let compute_functions (env : Env.t) (state : State.t) (props : acc) : acc =
  let compute_func_f = compute_functions_dispatch env in
  Fun.flip2 List.fold_left [] props (fun acc (l_prop, scheme) ->
      if Node.is_function l_prop then compute_func_f state l_prop scheme acc
      else acc )

let rec compute_object (env : Env.t) (state : State.t) (exported : t)
    (prev : Scheme.t) (ls_exported : Node.Set.t) : unit =
  compute_lookups state exported prev ls_exported
  |> compute_functions env state
  |> compute_returns env state exported

and compute_returns (env : Env.t) (state : State.t) (exported : t)
    (returns : acc) : unit =
  Fun.flip List.iter returns (fun (l_retn, scheme) ->
      if not (mem exported l_retn) then
        compute_object env state exported scheme (Node.Set.singleton l_retn) )

let compute (env : Env.t) (state : State.t) : t =
  let exported = create () in
  let ls_exported = Jslib.exported_object state.mdg state.jslib in
  if not (empty_exports state ls_exported) then
    compute_object env state exported [] ls_exported;
  exported

let compute_from_graph (state : State.t) : t =
  compute (Env.create GraphEdge) state

let compute_and_unfold (cb_unfold : Env.cb_unfold_func) (state : State.t) : t =
  compute (Env.create (Unfold cb_unfold)) state
