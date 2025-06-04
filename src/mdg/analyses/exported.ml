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
let none () : t = Hashtbl.create Config.(!dflt_htbl_sz)
let is_empty (exported : t) : bool = Hashtbl.length exported == 0
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

let compute_function_this (state : State.t) (l_func : Node.t)
    (scheme : Scheme.t) (entries : acc) : acc =
  let l_this = Mdg.get_parameter state.mdg l_func 0 in
  let ls_this = Mdg.object_tail_versions state.mdg l_this in
  Fun.flip2 Node.Set.fold ls_this entries (fun l_this acc ->
      (l_this, scheme) :: acc )

let compute_function_return (env : Env.t) (state : State.t) (l_func : Node.t) :
    Node.Set.t =
  match env.return_handler with
  | GraphEdge -> Mdg.get_function_returns state.mdg l_func |> Node.Set.of_list
  | Unfold cb_unfold_func -> (cb_unfold_func state l_func).curr_return

let compute_function (env : Env.t) (state : State.t) (l_func : Node.t)
    (scheme : Scheme.t) (entries : acc) : acc =
  let ls_retn = compute_function_return env state l_func in
  let entries' = compute_function_this state l_func scheme entries in
  Fun.flip2 Node.Set.fold ls_retn entries' (fun l_retn acc ->
      let scheme' = Scheme.extend scheme [ Call ] in
      (l_retn, scheme') :: acc )

let compute_functions (env : Env.t) (state : State.t) (scheme : Scheme.t)
    (ls_entries : Node.Set.t) : acc =
  Fun.flip2 Node.Set.fold ls_entries [] (fun l_entry acc ->
      let acc' = (l_entry, scheme) :: acc in
      if not (Node.is_function l_entry) then acc'
      else compute_function env state l_entry scheme acc' )

let compute_lookups (state : State.t) (entries : acc) : acc =
  let props_f prev (props, l_prop) acc =
    let next = List.map Interaction.lookup props in
    let scheme = Scheme.extend prev next in
    (l_prop, scheme) :: acc in
  Fun.flip2 List.fold_left [] entries (fun acc (l_entry, scheme) ->
      Mdg.object_nested_traversal (props_f scheme) state.mdg l_entry acc )

let rec compute_object (env : Env.t) (state : State.t) (exported : t)
    (scheme : Scheme.t) (ls_entries : Node.Set.t) : unit =
  compute_functions env state scheme ls_entries
  |> compute_lookups state
  |> compute_recursive env state exported

and compute_recursive (env : Env.t) (state : State.t) (exported : t)
    (entries : acc) : unit =
  Fun.flip List.iter entries (fun (l_entry, scheme) ->
      if not (mem exported l_entry) then (
        replace exported l_entry scheme;
        compute_object env state exported scheme (Node.Set.singleton l_entry) ) )

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
