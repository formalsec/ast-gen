open Graphjs_base
open Graphjs_mdg

module Source = struct
  type t =
    | Param of Node.t * string option list
    | Ret of Node.t

  let id : t -> int = function Param (n, _) | Ret n -> n.uid [@@inline]
  let hash (src : t) : int = Location.hash (id src)
  let equal (src1 : t) (src2 : t) : bool = Location.equal (id src1) (id src2)
  let compare (src1 : t) (src2 : t) : int = Location.compare (id src1) (id src2)

  let extend (prop : string option) : t -> t = function
    | Param (node, props) -> Param (node, props @ [ prop ])
    | Ret _ as reach -> reach

  let pp_props (ppf : Fmt.t) (props : string option list) =
    let pp_prop ppf prop = Fmt.pp_str ppf (Option.value ~default:"*" prop) in
    if not (List.is_empty props) then
      Fmt.fmt ppf ", %a" Fmt.(pp_lst !>"." pp_prop) props

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

let create () : t = Hashtbl.create Config.(!dflt_htbl_sz)

let find (reachability : t) (node : Node.t) : Set.t option =
  Hashtbl.find_opt reachability node.uid

let replace (reachability : t) (node : Node.t) (sources : Set.t) : unit =
  Hashtbl.replace reachability node.uid sources

let get (reachability : t) (node : Node.t) : Set.t =
  Option.value ~default:Set.empty (find reachability node)

let set (reachability : t) (queue : Node.t Queue.t) (edge : Edge.t)
    (sources : Set.t) : unit =
  let sources' = get reachability edge.tar in
  if not (Set.equal sources sources') then (
    replace reachability edge.tar (Set.union sources sources');
    Queue.add edge.tar queue )

let compute_edge (reach : t) (queue : Node.t Queue.t) (edge : Edge.t) : unit =
  match edge.kind with
  | Dependency | Argument _ -> get reach edge.src |> set reach queue edge
  | Parameter _ -> Set.singleton (Param (edge.tar, [])) |> set reach queue edge
  | Return -> Set.singleton (Ret edge.src) |> set reach queue edge
  | Property prop ->
    get reach edge.src |> Set.map (Source.extend prop) |> set reach queue edge
  | _ -> ()

let rec compute_node (mdg : Mdg.t) (reach : t) (queue : Node.t Queue.t) : unit =
  Fun.flip Option.iter (Queue.take_opt queue) (fun node ->
      let edges = Mdg.get_edges mdg node.uid in
      Edge.Set.iter (compute_edge reach queue) edges;
      compute_node mdg reach queue )

let compute_function (mdg : Mdg.t) (reach : t) (node : Node.t) : unit =
  if Option.is_none (find reach node) then (
    let queue = Queue.create () in
    Queue.add node queue;
    compute_node mdg reach queue )

let compute (mdg : Mdg.t) (reach : t) (node : Node.t) : Set.t =
  (* TODO: compute the reachability of global nodes (without parent) *)
  match node.parent with
  | None -> Set.empty
  | Some parent ->
    replace reach node Set.empty;
    compute_function mdg reach parent;
    get reach node
