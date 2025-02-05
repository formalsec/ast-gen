open Graphjs_base
open Graphjs_mdg

module Source = struct
  type t =
    | Param of Node.t * string option list
    | Ret of Node.t
    | TaintSink of Node.t
    | TaintSource

  let id : t -> int = function
    | Param (n, _) | Ret n | TaintSink n -> n.uid
    | TaintSource -> Location.taint_source_loc ()

  let is_taint_source : t -> bool = function TaintSource -> true | _ -> false
  let hash (src : t) : int = Location.hash (id src)
  let equal (src1 : t) (src2 : t) : bool = Location.equal (id src1) (id src2)
  let compare (src1 : t) (src2 : t) : int = Location.compare (id src1) (id src2)

  let extend (prop : string option) : t -> t = function
    | Param (node, props) -> Param (node, props @ [ prop ])
    | source -> source

  let pp_props (ppf : Fmt.t) (props : string option list) =
    let pp_prop ppf prop = Fmt.pp_str ppf (Option.value ~default:"*" prop) in
    if not (List.is_empty props) then
      Fmt.fmt ppf ", %a" Fmt.(pp_lst !>"." pp_prop) props

  let pp (ppf : Fmt.t) : t -> unit = function
    | Param (node, props) ->
      Fmt.fmt ppf "P(%s%a)" (Node.name node) pp_props props
    | Ret node -> Fmt.fmt ppf "Ret(%s)" (Node.name node)
    | TaintSink node -> Fmt.fmt ppf "Sink(%s)" (Node.name node)
    | TaintSource -> Fmt.pp_str ppf "TaintSource"

  let str (reach : t) : string = Fmt.str "%a" pp reach [@@inline]
end

module Sources = struct
  include Set.Make (struct
    type elt = Source.t

    let compare : elt -> elt -> int = compare
  end)

  let pp (ppf : Fmt.t) (nodes : t) : unit =
    if is_empty nodes then Fmt.pp_str ppf "{}"
    else Fmt.fmt ppf "{ %a }" Fmt.(pp_iter iter !>", " Source.pp) nodes

  let str (nodes : t) : string = Fmt.str "%a" pp nodes [@@inline]
end

type t = (Location.t, Sources.t) Hashtbl.t

let create () : t = Hashtbl.create Config.(!dflt_htbl_sz)

let mem (reachability : t) (node : Node.t) : bool =
  Hashtbl.mem reachability node.uid

let find_opt (reachability : t) (node : Node.t) : Sources.t option =
  Hashtbl.find_opt reachability node.uid

let find (reachability : t) (node : Node.t) : Sources.t =
  Option.value ~default:Sources.empty (find_opt reachability node)

let replace (reachability : t) (node : Node.t) (sources : Sources.t) : unit =
  Hashtbl.replace reachability node.uid sources

let set (reachability : t) (node : Node.t) (sources : Sources.t) :
    bool * Sources.t =
  replace reachability node sources;
  (true, sources)

let is_tainted (mdg : Mdg.t) (node : Node.t) =
  let f edge = Edge.is_dependency edge && Node.is_taint_source edge.tar in
  let edges = Mdg.get_trans mdg node.uid in
  if Edge.Set.exists f edges then Sources.singleton TaintSource
  else Sources.empty

let rec compute_node (reachability : t) (mdg : Mdg.t) (ls_visited : Node.Set.t)
    (props : string option list) (node : Node.t) : bool * Sources.t =
  match find_opt reachability node with
  | Some sources -> (true, sources)
  | None -> compute_unknown_node reachability mdg ls_visited props node

and compute_unknown_node (reachability : t) (mdg : Mdg.t)
    (ls_visited : Node.Set.t) (props : string option list) (node : Node.t) :
    bool * Sources.t =
  let add_f source = Sources.add source (is_tainted mdg node) in
  match node.kind with
  | TaintSource -> set reachability node (Sources.singleton TaintSource)
  | Parameter _ -> set reachability node (add_f (Param (node, [])))
  | Return _ -> set reachability node (add_f (Ret node))
  | TaintSink _ -> set reachability node (add_f (TaintSink node))
  | _ ->
    let ls_visited' = Node.Set.add node ls_visited in
    let res = compute_edges reachability mdg ls_visited' props node in
    let (resolved, sources) = res in
    if resolved then replace reachability node sources;
    res

and compute_edges (reachability : t) (mdg : Mdg.t) (ls_visited : Node.Set.t)
    (props : string option list) (node : Node.t) : bool * Sources.t =
  let edges = Mdg.get_trans mdg node.uid in
  Fun.flip2 Edge.Set.fold edges (true, Sources.empty)
    (fun edge (resolved, sources) ->
      match (Node.Set.mem edge.tar ls_visited, edge.kind) with
      | (true, _) -> (false, Sources.union sources (find reachability edge.tar))
      | (false, (Dependency | Argument _)) ->
        let (resolved', sources') =
          compute_node reachability mdg ls_visited props edge.tar in
        (resolved && resolved', Sources.union sources sources')
      | (false, Property prop) ->
        let (resolved', sources') =
          compute_node reachability mdg ls_visited props edge.tar in
        let sources'' = Sources.map (Source.extend prop) sources' in
        (resolved && resolved', Sources.union sources sources'')
      | _ -> (true, Sources.empty) )

let compute (reachability : t) (mdg : Mdg.t) (node : Node.t) : Sources.t =
  match find_opt reachability node with
  | Some sources -> sources
  | None ->
    let ls_visited = Node.Set.singleton node in
    let (_, sources) = compute_node reachability mdg ls_visited [] node in
    replace reachability node sources;
    sources
