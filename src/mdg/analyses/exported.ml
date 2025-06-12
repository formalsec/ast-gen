module Computed = struct
  module Tbl = Hashtbl.Make (Node)
  include Tbl

  type t = Node.Set.t Tbl.t
end

module Env = struct
  type cb_unfold =
    State.t -> Node.t -> Node.Set.t -> bool -> State.t * Node.Set.t

  type t =
    { computed : Computed.t
    ; cb_unfold : cb_unfold
    }

  let create (cb_unfold : cb_unfold) : t =
    { computed = Computed.create Config.(!dflt_htbl_sz); cb_unfold }
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

  let extend (prev : t) (next : Interaction.t) : t = prev @ [ next ]

  let pp (ppf : Fmt.t) (scheme : t) : unit =
    Fmt.fmt ppf "<EObj>%a" Fmt.(pp_lst !>"" Interaction.pp) scheme

  let str (scheme : t) : string = Fmt.str "%a" pp scheme
end

type t = (Location.t, Node.t * Scheme.t) Hashtbl.t

let none () : t = Hashtbl.create Config.(!dflt_htbl_sz)
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

type stage =
  | General
  | Proto
  | Prototype

type entry = Node.t * Node.Set.t * Scheme.t
type queue = entry Queue.t

let empty_exports (state : State.t) (ls_exported : Node.Set.t) : bool =
  (* the ls_exported contains one element when empty (jslib exports node) *)
  if Node.Set.cardinal ls_exported == 1 then
    let l_exported = Node.Set.choose ls_exported in
    let l_exported_orig = Jslib.find_node state.mdg state.jslib "exports" in
    let l_exported_edges = Mdg.get_edges state.mdg l_exported.loc in
    Node.equal l_exported l_exported_orig
    && Edge.Set.cardinal l_exported_edges == 0
  else false

let set_exported (exported : t) ((l_exported, _, scheme) : entry) : unit =
  (* TODO: What to do with multiple schemes to the same node? *)
  match find exported l_exported with
  | None -> replace exported l_exported scheme
  | Some _ -> ()

let compute_next_entry (env : Env.t) (queue : queue) (l_next : Node.t)
    (ls_this : Node.Set.t) (scheme : Scheme.t) : unit =
  match Computed.find_opt env.computed l_next with
  | None ->
    Computed.replace env.computed l_next ls_this;
    Queue.push (l_next, ls_this, scheme) queue
  | Some ls_this' ->
    let ls_this_diff = Node.Set.diff ls_this ls_this' in
    let ls_this_union = Node.Set.union ls_this ls_this' in
    Computed.replace env.computed l_next ls_this_union;
    if not (Node.Set.is_empty ls_this_diff) then
      Queue.push (l_next, ls_this_diff, scheme) queue

let compute_function (state : State.t) (env : Env.t) (queue : queue)
    ((l_func, ls_this, scheme) : entry) : unit =
  if Node.is_function l_func then
    let (_, ls_retn) = env.cb_unfold state l_func ls_this true in
    Fun.flip Node.Set.iter ls_retn (fun l_retn ->
        let scheme' = Scheme.extend scheme Call in
        compute_next_entry env queue l_retn Node.Set.empty scheme' )

let compute_lookups (state : State.t) (env : Env.t) (queue : queue)
    ((l_obj, _, scheme) : entry) : unit =
  let f (prop, node) acc = (prop, node) :: acc in
  let props = Mdg.object_dynamic_traversal f state.mdg Node.Set.empty l_obj [] in
  Fun.flip List.iter props (fun (prop, l_prop) ->
      let ls_prop = Mdg.object_tail_versions state.mdg l_prop in
      let ls_this' = Node.Set.singleton l_obj in
      let scheme' = Scheme.extend scheme (Lookup prop) in
      Fun.flip Node.Set.iter ls_prop (fun l_prop' ->
          compute_next_entry env queue l_prop' ls_this' scheme' ) )

let rec compute_object (state : State.t) (env : Env.t) (queue : queue)
    (exported : t) : unit =
  Fun.flip Option.iter (Queue.take_opt queue) (fun entry ->
      set_exported exported entry;
      compute_function state env queue entry;
      compute_lookups state env queue entry;
      compute_object state env queue exported )

let compute_exported (state : State.t) (env : Env.t) (exported : t)
    (ls_exported : Node.Set.t) : unit =
  let queue = Queue.create () in
  Fun.flip Node.Set.iter ls_exported (fun l_exported ->
      Queue.push (l_exported, Node.Set.empty, []) queue );
  compute_object state env queue exported

let compute (cb_unfold : Env.cb_unfold) (state : State.t) : t =
  let env = Env.create cb_unfold in
  let exported = create () in
  let ls_exported = Jslib.exported_object state.mdg state.jslib in
  if not (empty_exports state ls_exported) then
    compute_exported state env exported ls_exported;
  exported
