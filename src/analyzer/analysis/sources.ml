open Graphjs_base
open Graphjs_mdg

module Source = struct
  type t =
    | Param of Node.t * Property.t list
    | Retn of Node.t * Property.t list
    | TaintSource

  let is_taint_source (src : t) : bool =
    match src with TaintSource -> true | _ -> false

  let id (src : t) : Location.t =
    match src with
    | Param (n, _) | Retn (n, _) -> n.uid
    | TaintSource -> Location.taint_source ()

  let equal (src1 : t) (src2 : t) : bool = Location.equal (id src1) (id src2)
  let compare (src1 : t) (src2 : t) : int = Location.compare (id src1) (id src2)

  let extend (prop : Property.t) (src : t) : t =
    match src with
    | Param (l_param, props) -> Param (l_param, props @ [ prop ])
    | Retn (l_call, props) -> Retn (l_call, props @ [ prop ])
    | TaintSource -> src

  let pp_props (ppf : Fmt.t) (props : Property.t list) =
    if not (List.is_empty props) then
      Fmt.fmt ppf ", %a" Fmt.(pp_lst !>"." Property.pp) props

  let pp (ppf : Fmt.t) (src : t) : unit =
    match src with
    | Param (l_param, props) -> Fmt.fmt ppf "P(%d%a)" l_param.lid pp_props props
    | Retn (l_call, props) ->
      Fmt.fmt ppf "Ret(%s%a)" (Node.name l_call) pp_props props
    | TaintSource -> Fmt.pp_str ppf "TaintSource"

  let str (reach : t) : string = Fmt.str "%a" pp reach
end

module Set = struct
  include Set.Make (struct
    type elt = Source.t

    let compare : elt -> elt -> int = compare
  end)

  let pp (ppf : Fmt.t) (nodes : t) : unit =
    if is_empty nodes then Fmt.pp_str ppf "{}"
    else Fmt.fmt ppf "{ %a }" Fmt.(pp_iter iter !>", " Source.pp) nodes

  let str (nodes : t) : string = Fmt.str "%a" pp nodes
end

type t = (Location.t, Node.t * Set.t) Hashtbl.t

let create () : t = Hashtbl.create Config.(!dflt_htbl_sz)
let mem (flow : t) (node : Node.t) : bool = Hashtbl.mem flow node.uid

let find (flow : t) (node : Node.t) : Set.t option =
  Option.map snd (Hashtbl.find_opt flow node.uid)

let replace (flow : t) (node : Node.t) (sources : Set.t) : unit =
  Hashtbl.replace flow node.uid (node, sources)

let get (flow : t) (node : Node.t) : Set.t =
  Option.value ~default:Set.empty (find flow node)

let set (flow : t) (queue : Node.t Queue.t) (edge : Edge.t) (sources : Set.t) :
    unit =
  let sources' = get flow edge.tar in
  if not (Set.equal sources sources') then (
    replace flow edge.tar (Set.union sources sources');
    Queue.add edge.tar queue )

let pp (ppf : Fmt.t) (flow : t) : unit =
  let pp_sources ppf (node, sources) =
    Fmt.fmt ppf "%a -> %a" Node.pp node Set.pp sources in
  Fmt.(pp_htbl !>"@\n" (fun ppf (_, vs) -> pp_sources ppf vs)) ppf flow

let str (flow : t) : string = Fmt.str "%a" pp flow

let rec compute_nodes (flow : t) (mdg : Mdg.t) (queue : Node.t Queue.t) : unit =
  Fun.flip Option.iter (Queue.take_opt queue) (fun node ->
      let edges = Mdg.get_edges mdg node.uid in
      Edge.Set.iter (compute_edge flow queue) edges;
      compute_nodes flow mdg queue )

and compute_edge (flow : t) (queue : Node.t Queue.t) (edge : Edge.t) : unit =
  match edge.kind with
  | Dependency -> get flow edge.src |> set flow queue edge
  | Parameter _ -> Set.singleton (Param (edge.tar, [])) |> set flow queue edge
  | Return -> Set.singleton (Retn (edge.src, [])) |> set flow queue edge
  | Property prop ->
    get flow edge.src |> Set.map (Source.extend prop) |> set flow queue edge
  | _ -> ()

let enqueue_nodes (flow : t) (mdg : Mdg.t) (queue : Node.t Queue.t) : unit =
  Fun.flip Hashtbl.iter mdg.nodes (fun _ node ->
      match node.kind with
      | Function _ | Call _ -> Queue.add node queue
      | TaintSource ->
        replace flow node (Set.singleton TaintSource);
        Queue.add node queue
      | _ -> () )

let compute (mdg : Mdg.t) : t =
  let flow = create () in
  let queue = Queue.create () in
  enqueue_nodes flow mdg queue;
  compute_nodes flow mdg queue;
  flow
