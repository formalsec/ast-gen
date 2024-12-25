open Graphjs_base
open Graphjs_mdg

module Source = struct
  type t =
    | Param of Node.t * string option list
    | Ret of Node.t

  let uid : t -> int = function Param (n, _) | Ret n -> n.uid [@@inline]
  let hash (reach : t) : int = Location.hash (uid reach)

  let equal (reach1 : t) (reach2 : t) : bool =
    Location.equal (uid reach1) (uid reach2)

  let compare (reach1 : t) (reach2 : t) : int =
    Location.compare (uid reach1) (uid reach2)

  let extend (prop : string option) : t -> t = function
    | Param (node, props) -> Param (node, props @ [ prop ])
    | Ret _ as reach -> reach

  let pp_prop (ppf : Fmt.t) : string option -> unit = function
    | Some prop' -> Fmt.pp_str ppf prop'
    | None -> Fmt.pp_str ppf "*"

  let pp_props (ppf : Fmt.t) (props : string option list) =
    if not (List.is_empty props) then
      Fmt.fmt ppf ", %a" Fmt.(pp_lst !>", " pp_prop) props

  let pp (ppf : Fmt.t) : t -> unit = function
    | Param (node, props) -> Fmt.fmt ppf "P(%d%a)" node.lid pp_props props
    | Ret node -> Fmt.fmt ppf "Ret(%s)" (Node.name node)

  let str (reach : t) : string = Fmt.str "%a" pp reach [@@inline]
end

module Set = struct
  include Set.Make (struct
    type elt = Source.t

    let compare : elt -> elt -> int = compare
  end)

  let pp (ppf : Fmt.t) (nodes : t) : unit =
    if is_empty nodes then Fmt.pp_str ppf "{}"
    else Fmt.fmt ppf "{ %a }" Fmt.(pp_iter iter !>", " Source.pp) nodes

  let str (nodes : t) : string = Fmt.str "%a" pp nodes [@@inline]
end

type t = (Location.t, Set.t) Hashtbl.t

let find (local_flow : t) (node : Node.t) : Set.t option =
  Hashtbl.find_opt local_flow node.uid
[@@inline]

let replace (local_flow : t) (node : Node.t) (sources : Set.t) : unit =
  Hashtbl.replace local_flow node.uid sources
[@@inline]

let get (local_flow : t) (node : Node.t) : Set.t =
  Option.value ~default:Set.empty (find local_flow node)
[@@inline]

let set (local_flow : t) (queue : Node.t Queue.t) (edge : Edge.t)
    (sources : Set.t) : unit =
  let sources' = get local_flow edge.tar in
  if not (Set.equal sources sources') then (
    replace local_flow edge.tar (Set.union sources sources');
    Queue.add edge.tar queue )

let compute_edge (local_flow : t) (queue : Node.t Queue.t) (edge : Edge.t) :
    unit =
  match edge.kind with
  | Parameter _ ->
    let sources = Set.singleton (Param (edge.tar, [])) in
    set local_flow queue edge sources
  | Property prop ->
    let sources = get local_flow edge.src in
    let sources' = Set.map (Source.extend prop) sources in
    set local_flow queue edge sources'
  | Dependency | Argument _ ->
    let sources = get local_flow edge.src in
    set local_flow queue edge sources
  | Return ->
    let sources = Set.singleton (Ret edge.src) in
    set local_flow queue edge sources
  | _ -> ()

let rec compute_node (mdg : Mdg.t) (local_flow : t) (queue : Node.t Queue.t) :
    unit =
  Fun.flip Option.iter (Queue.take_opt queue) (fun node ->
      let edges = Mdg.get_edges mdg node.uid in
      Edge.Set.iter (compute_edge local_flow queue) edges;
      compute_node mdg local_flow queue )

let compute_function (mdg : Mdg.t) (local_flow : t) (node : Node.t) : unit =
  if Option.is_none (find local_flow node) then (
    let queue = Queue.create () in
    Queue.add node queue;
    compute_node mdg local_flow queue )

let compute (mdg : Mdg.t) (local_flow : t) (node : Node.t) : Set.t =
  (* TODO: compute local_flow for global nodes *)
  match node.parent with
  | None -> Set.empty
  | Some parent ->
    replace local_flow node Set.empty;
    compute_function mdg local_flow parent;
    get local_flow node
