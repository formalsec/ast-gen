open Graphjs_base
open Graphjs_mdg

module Source = struct
  type t =
    | Param of Node.t * string option list
    | Ret of Node.t
    | Tainted

  let id : t -> int = function
    | Param (n, _) | Ret n -> n.uid
    | Tainted -> Location.taint_source_loc ()

  let hash (src : t) : int = Location.hash (id src)
  let equal (src1 : t) (src2 : t) : bool = Location.equal (id src1) (id src2)
  let compare (src1 : t) (src2 : t) : int = Location.compare (id src1) (id src2)

  let extend (prop : string option) : t -> t = function
    | Param (node, props) -> Param (node, props @ [ prop ])
    | Ret _ as reach -> reach
    | Tainted as tainted -> tainted

  let pp_props (ppf : Fmt.t) (props : string option list) =
    let pp_prop ppf prop = Fmt.pp_str ppf (Option.value ~default:"*" prop) in
    if not (List.is_empty props) then
      Fmt.fmt ppf ", %a" Fmt.(pp_lst !>"." pp_prop) props

  let pp (ppf : Fmt.t) : t -> unit = function
    | Param (node, props) ->
      Fmt.fmt ppf "P(%s%a)" (Node.name node) pp_props props
    | Ret node -> Fmt.fmt ppf "Ret(%s)" (Node.name node)
    | Tainted -> Fmt.pp_str ppf "Tainted"

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

let mem (reachability : t) (node : Node.t) : bool =
  Hashtbl.mem reachability node.uid

let find_opt (reachability : t) (node : Node.t) : Set.t option =
  Hashtbl.find_opt reachability node.uid

let find (reachability : t) (node : Node.t) : Set.t =
  Option.value ~default:Set.empty (find_opt reachability node)

let replace (reachability : t) (node : Node.t) (sources : Set.t) : unit =
  Hashtbl.replace reachability node.uid sources

let add (reachability : t) (node : Node.t) (source : Source.t) : bool * Set.t =
  let sources = Set.singleton source in
  replace reachability node sources;
  (true, sources)

let rec compute_node (reachability : t) (mdg : Mdg.t) (ls_visited : Node.Set.t)
    (props : string option list) (node : Node.t) : bool * Set.t =
  match (find_opt reachability node, node.kind) with
  | (Some sources, _) -> (true, sources)
  | (None, TaintSource) -> add reachability node Tainted
  | (None, Parameter _) -> add reachability node (Param (node, []))
  | (None, Return _) -> add reachability node (Ret node)
  | (None, _) ->
    let ls_visited' = Node.Set.add node ls_visited in
    let res = compute_edges reachability mdg ls_visited' props node in
    let (resolved, sources) = res in
    if resolved then replace reachability node sources;
    res

and compute_edges (reachability : t) (mdg : Mdg.t) (ls_visited : Node.Set.t)
    (props : string option list) (node : Node.t) : bool * Set.t =
  let edges = Mdg.get_trans mdg node.uid in
  Fun.flip2 Edge.Set.fold edges (true, Set.empty)
    (fun edge (resolved, sources) ->
      match (Node.Set.mem edge.tar ls_visited, edge.kind) with
      | (true, _) -> (false, Set.union sources (find reachability edge.tar))
      | (false, (Dependency | Argument _)) ->
        let (resolved', sources') =
          compute_node reachability mdg ls_visited props edge.tar in
        (resolved && resolved', Set.union sources sources')
      | (false, Property prop) ->
        let (resolved', sources') =
          compute_node reachability mdg ls_visited props edge.tar in
        let sources'' = Set.map (Source.extend prop) sources' in
        (resolved && resolved', Set.union sources sources'')
      | _ -> (true, Set.empty) )

let compute (reachability : t) (mdg : Mdg.t) (node : Node.t) : Set.t =
  match find_opt reachability node with
  | Some sources -> sources
  | None ->
    let ls_visited = Node.Set.singleton node in
    let (_, sources) = compute_node reachability mdg ls_visited [] node in
    replace reachability node sources;
    sources
