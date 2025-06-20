type kind =
  | Dependency
  | Property of Property.t
  | Version of Property.t
  | Parameter of int
  | Argument of int
  | Caller
  | Return
  | Meta of string

let kind_id (kind : kind) : int =
  match kind with
  | Dependency -> 1
  | Property _ -> 2
  | Version _ -> 3
  | Parameter _ -> 4
  | Argument _ -> 5
  | Caller -> 6
  | Return -> 7
  | Meta _ -> 8

let equal_kind (kind1 : kind) (kind2 : kind) : bool =
  match (kind1, kind2) with
  | (Dependency, Dependency) -> true
  | (Property prop1, Property prop2) -> Property.equal prop1 prop2
  | (Version prop1, Version prop2) -> Property.equal prop1 prop2
  | (Parameter idx1, Parameter idx2) -> Int.equal idx1 idx2
  | (Argument idx1, Argument idx2) -> Int.equal idx1 idx2
  | (Caller, Caller) -> true
  | (Return, Return) -> true
  | (Meta meta1, Meta meta2) -> String.equal meta1 meta2
  | _ -> false

let compare_kind_arg (kind1 : kind) (kind2 : kind) : int =
  match (kind1, kind2) with
  | (Property prop1, Property prop2) | (Version prop1, Version prop2) ->
    Property.compare prop1 prop2
  | (Parameter idx1, Parameter idx2) | (Argument idx1, Argument idx2) ->
    Int.compare idx1 idx2
  | _ -> 0

let compare_kind (kind1 : kind) (kind2 : kind) : int =
  let kind_cmp = Int.compare (kind_id kind1) (kind_id kind2) in
  if kind_cmp == 0 then compare_kind_arg kind1 kind2 else kind_cmp

let pp_kind (ppf : Fmt.t) (kind : kind) : unit =
  match kind with
  | Dependency -> Fmt.fmt ppf "D"
  | Property prop -> Fmt.fmt ppf "P(%a)" Property.pp prop
  | Version prop -> Fmt.fmt ppf "V(%a)" Property.pp prop
  | Parameter idx -> Fmt.fmt ppf "Param(%d)" idx
  | Argument idx -> Fmt.fmt ppf "Arg(%d)" idx
  | Caller -> Fmt.fmt ppf "Call"
  | Return -> Fmt.fmt ppf "Retn"
  | Meta meta -> Fmt.fmt ppf "Meta(%s)" meta

type t =
  { src : Node.t
  ; tar : Node.t
  ; kind : kind
  }

let default =
  let node = Node.default () in
  let dflt = { src = node; tar = node; kind = Dependency } in
  fun () -> dflt

let create (src : Node.t) (tar : Node.t) (kind : kind) : t = { src; tar; kind }
let transpose (edge : t) : t = { edge with src = edge.tar; tar = edge.src }
let src (edge : t) : Node.t = edge.src
let tar (edge : t) : Node.t = edge.tar
let kind (edge : t) : kind = edge.kind
let hash (edge : t) : int = Node.hash edge.tar

let equal (edge1 : t) (edge2 : t) : bool =
  Node.equal edge1.src edge2.src
  && Node.equal edge1.tar edge2.tar
  && equal_kind edge1.kind edge2.kind

let compare (edge1 : t) (edge2 : t) : int =
  let src_cmp = Node.compare edge1.src edge2.src in
  if src_cmp == 0 then
    let tar_cmp = Node.compare edge1.tar edge2.tar in
    if tar_cmp == 0 then compare_kind edge1.kind edge2.kind else tar_cmp
  else src_cmp

let pp (ppf : Fmt.t) (edge : t) : unit =
  Fmt.fmt ppf "%a --< %a >--> %a" Node.pp edge.src pp_kind edge.kind Node.pp
    edge.tar

let str (edge : t) : string = Fmt.str "%a" pp edge

module Set = struct
  include Set.Make (struct
    type elt = t

    let compare = compare
  end)

  let pp (ppf : Fmt.t) (edges : t) : unit =
    Fmt.(pp_iter iter !>"@\n" pp) ppf edges

  let str (edges : t) : string = Fmt.str "%a" pp edges
end

let create_dependency () : Node.t -> Node.t -> t =
 fun src tar -> create src tar Dependency

let create_property (prop : Property.t) : Node.t -> Node.t -> t =
 fun src tar -> create src tar (Property prop)

let create_version (prop : Property.t) : Node.t -> Node.t -> t =
 fun src tar -> create src tar (Version prop)

let create_parameter (idx : int) : Node.t -> Node.t -> t =
 fun src tar -> create src tar (Parameter idx)

let create_argument (idx : int) : Node.t -> Node.t -> t =
 fun src tar -> create src tar (Argument idx)

let create_caller () : Node.t -> Node.t -> t =
 fun src tar -> create src tar Caller

let create_return () : Node.t -> Node.t -> t =
 fun src tar -> create src tar Return

let create_meta (meta : string) : Node.t -> Node.t -> t =
 fun src tar -> create src tar (Meta meta)

let is_dependency (edge : t) : bool =
  match edge.kind with Dependency -> true | _ -> false

let is_property ?(prop : Property.t option) (edge : t) : bool =
  match (prop, edge.kind) with
  | (None, Property _) -> true
  | (Some prop1, Property prop2) -> Property.equal prop1 prop2
  | _ -> false

let is_version ?(prop : Property.t option) (edge : t) : bool =
  match (prop, edge.kind) with
  | (None, Version _) -> true
  | (Some prop1, Version prop2) -> Property.equal prop1 prop2
  | _ -> false

let is_parameter ?(idx : int option) (edge : t) : bool =
  match (idx, edge.kind) with
  | (None, Parameter _) -> true
  | (Some idx1, Parameter idx2) -> idx1 == idx2
  | _ -> false

let is_argument ?(idx : int option) (edge : t) : bool =
  match (idx, edge.kind) with
  | (None, Argument _) -> true
  | (Some idx1, Argument idx2) -> idx1 == idx2
  | _ -> false

let is_caller (edge : t) : bool =
  match edge.kind with Caller -> true | _ -> false

let is_return (edge : t) : bool =
  match edge.kind with Return -> true | _ -> false

let is_meta ?(meta : string option) (edge : t) : bool =
  match (meta, edge.kind) with
  | (None, Meta _) -> true
  | (Some meta1, Meta meta2) -> String.equal meta1 meta2
  | _ -> false

let property (edge : t) : Property.t =
  match edge.kind with
  | Property prop | Version prop -> prop
  | _ -> Log.fail "unexpected edge without an associated property"

let argument (edge : t) : int =
  match edge.kind with
  | Parameter idx | Argument idx -> idx
  | _ -> Log.fail "unexpected edge without an associated param/argument"

let metadata (edge : t) : string =
  match edge.kind with
  | Meta meta -> meta
  | _ -> Log.fail "unexpected edge without associated metadata"
