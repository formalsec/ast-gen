open Graphjs_base

type kind =
  | Dependency
  | Property of string option
  | Version of string option
  (* TODO: add a flag to disable ref parent edges *)
  | RefParent of string option
  | Parameter of int
  | Argument of int
  (* TODO: add a flag to disable ref argument edges *)
  | RefArgument
  | Return
  | RefReturn
  | Call

let kind_equal (kind1 : kind) (kind2 : kind) : bool =
  match (kind1, kind2) with
  | (Dependency, Dependency) -> true
  | (Property prop1, Property prop2) -> Option.equal String.equal prop1 prop2
  | (Version prop1, Version prop2) -> Option.equal String.equal prop1 prop2
  | (RefParent prop1, RefParent prop2) -> Option.equal String.equal prop1 prop2
  | (Parameter idx1, Parameter idx2) -> Int.equal idx1 idx2
  | (Argument idx1, Argument idx2) -> Int.equal idx1 idx2
  | (RefArgument, RefArgument) -> true
  | (Return, Return) -> true
  | (RefReturn, RefReturn) -> true
  | (Call, Call) -> true
  | _ -> false

let kind_id : kind -> int = function
  | Dependency -> 1
  | Property _ -> 2
  | Version _ -> 3
  | RefParent _ -> 4
  | Parameter _ -> 5
  | Argument _ -> 6
  | RefArgument -> 7
  | Return -> 8
  | RefReturn -> 9
  | Call -> 10

let kind_compare (kind1 : kind) (kind2 : kind) : int =
  let (kind_id1, kind_id2) = (kind_id kind1, kind_id kind2) in
  if kind_id1 < kind_id2 then -1
  else if kind_id1 > kind_id2 then 1
  else
    match (kind1, kind2) with
    | (Property prop1, Property prop2)
    | (Version prop1, Version prop2)
    | (RefParent prop1, RefParent prop2) ->
      Option.compare String.compare prop1 prop2
    | (Parameter idx1, Parameter idx2) | (Argument idx1, Argument idx2) ->
      Int.compare idx1 idx2
    | _ -> 0

let kind_pp (ppf : Fmt.t) (kind : kind) : unit =
  let prop_f = Option.value ~default:"*" in
  match kind with
  | Dependency -> Fmt.fmt ppf "D"
  | Property prop -> Fmt.fmt ppf "P(%s)" (prop_f prop)
  | Version prop -> Fmt.fmt ppf "V(%s)" (prop_f prop)
  | RefParent prop -> Fmt.fmt ppf "[[RefParent(%s)]]" (prop_f prop)
  | Parameter idx -> Fmt.fmt ppf "Param(%d)" idx
  | Argument idx -> Fmt.fmt ppf "Arg(%d)" idx
  | RefArgument -> Fmt.fmt ppf "[[RefArg]]"
  | Return -> Fmt.fmt ppf "Ret"
  | RefReturn -> Fmt.fmt ppf "[[RefRet]]"
  | Call -> Fmt.fmt ppf "Call"

type t =
  { src : Node.t
  ; tar : Node.t
  ; kind : kind
  }

let create (src : Node.t) (tar : Node.t) (kind : kind) : t = { src; tar; kind }
let src (edge : t) : Node.t = edge.src [@@inline]
let tar (edge : t) : Node.t = edge.tar [@@inline]
let kind (edge : t) : kind = edge.kind [@@inline]
let hash (edge : t) : int = Node.hash edge.tar

let compare (edge1 : t) (edge2 : t) : int =
  let tar_cmp = Node.compare edge1.tar edge2.tar in
  if tar_cmp != 0 then tar_cmp else kind_compare edge1.kind edge2.kind

let equal (edge1 : t) (edge2 : t) : bool =
  Node.equal edge1.src edge2.src
  && Node.equal edge1.tar edge2.tar
  && kind_equal edge1.kind edge2.kind

let pp (ppf : Fmt.t) (edge : t) : unit =
  Fmt.fmt ppf "%a --< %a >--> %a" Node.pp edge.src kind_pp edge.kind Node.pp
    edge.tar

let str (edge : t) : string = Fmt.str "%a" pp edge [@@inline]

let create_dependency () : Node.t -> Node.t -> t =
 fun src tar -> create src tar Dependency

let create_property (prop : string option) : Node.t -> Node.t -> t =
 fun src tar -> create src tar (Property prop)

let create_version (prop : string option) : Node.t -> Node.t -> t =
 fun src tar -> create src tar (Version prop)

let create_ref_parent (prop : string option) : Node.t -> Node.t -> t =
 fun src tar -> create src tar (RefParent prop)

let create_parameter (idx : int) : Node.t -> Node.t -> t =
 fun src tar -> create src tar (Parameter idx)

let create_argument (idx : int) : Node.t -> Node.t -> t =
 fun src tar -> create src tar (Argument idx)

let create_ref_argument () : Node.t -> Node.t -> t =
 fun src tar -> create src tar RefArgument

let create_return () : Node.t -> Node.t -> t =
 fun src tar -> create src tar Return

let create_ref_return () : Node.t -> Node.t -> t =
 fun src tar -> create src tar RefReturn

let create_call () : Node.t -> Node.t -> t = fun src tar -> create src tar Call

let is_dependency (edge : t) : bool =
  match edge.kind with Dependency -> true | _ -> false

let is_property ?(prop : string option option = None) (edge : t) : bool =
  match (prop, edge.kind) with
  | (None, Property _) -> true
  | (Some prop1, Property prop2) -> Option.equal String.equal prop1 prop2
  | _ -> false

let is_version ?(prop : string option option = None) (edge : t) : bool =
  match (prop, edge.kind) with
  | (None, Version _) -> true
  | (Some prop1, Version prop2) -> Option.equal String.equal prop1 prop2
  | _ -> false

let is_ref_parent ?(prop : string option option = None) (edge : t) : bool =
  match (prop, edge.kind) with
  | (None, RefParent _) -> true
  | (Some prop1, RefParent prop2) -> Option.equal String.equal prop1 prop2
  | _ -> false

let is_parameter ?(idx : int option = None) (edge : t) : bool =
  match (idx, edge.kind) with
  | (None, Parameter _) -> true
  | (Some idx1, Parameter idx2) -> idx1 == idx2
  | _ -> false

let is_argument ?(idx : int option = None) (edge : t) : bool =
  match (idx, edge.kind) with
  | (None, Argument _) -> true
  | (Some idx1, Argument idx2) -> idx1 == idx2
  | _ -> false

let is_ref_argument (edge : t) : bool =
  match edge.kind with RefArgument -> true | _ -> false

let is_return (edge : t) : bool =
  match edge.kind with Return -> true | _ -> false

let is_ref_return (edge : t) : bool =
  match edge.kind with RefReturn -> true | _ -> false

let is_call (edge : t) : bool = match edge.kind with Call -> true | _ -> false

let property (edge : t) : string option =
  match edge.kind with
  | Property prop | Version prop | RefParent prop -> prop
  | _ -> Log.fail "expecting property or version edge"

module Set = struct
  type el = t

  include Set.Make (struct
    type t = el

    let compare : t -> t -> int = compare
  end)

  let pp (ppf : Fmt.t) (edges : t) : unit =
    Fmt.(pp_iter iter !>"@\n" pp) ppf edges

  let str (edges : t) : string = Fmt.str "%a" pp edges [@@inline]
end
