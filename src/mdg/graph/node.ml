open Graphjs_base
open Graphjs_ast

open struct
  let uid_gen : Location.t Generator.t = Location.make_generator ()
  let obj_lid_gen : Location.t Generator.t = Location.make_generator ()
  let func_lid_gen : Location.t Generator.t = Location.make_generator ()
  let sink_lid_gen : Location.t Generator.t = Location.make_generator ()
end

type kind =
  | Literal
  | TaintSource
  | TaintSink of Tainted.sink
  | Object of string
  | Function of string
  | Parameter of string
  | Call of string
  | Return of string

type t =
  { uid : Location.t
  ; lid : Location.t
  ; region : Region.t
  ; kind : kind
  ; parent : t option
  }

let default : unit -> t =
  let region = Region.default () in
  let dflt = { uid = -1; lid = -1; region; kind = Literal; parent = None } in
  fun () -> dflt

let create (uid : Location.t) (lid : Location.t) (region : Region.t)
    (kind : kind) (parent : t option) : t =
  { uid; lid; kind; region; parent }

let kind (node : t) : kind = node.kind [@@inline]
let parent (node : t) : t option = node.parent [@@inline]
let is_literal (node : t) : bool = Location.is_literal node.uid [@@inline]
let hash (node : t) : int = Location.hash node.uid
let equal (node1 : t) (node2 : t) : bool = Location.equal node1.uid node2.uid
let compare (node1 : t) (node2 : t) : int = Location.compare node1.uid node2.uid

let pp (ppf : Fmt.t) (node : t) : unit =
  match node.kind with
  | Literal -> Fmt.fmt ppf "[[literal]]"
  | TaintSource -> Fmt.fmt ppf "[[taint-source]]"
  | TaintSink sink ->
    Fmt.fmt ppf "%s[s_%a]" Tainted.(name !sink) Location.pp node.lid
  | Object name -> Fmt.fmt ppf "%s[l_%a]" name Location.pp node.lid
  | Function name -> Fmt.fmt ppf "%s[f_%a]" name Location.pp node.lid
  | Parameter name -> Fmt.fmt ppf "%s[p_%a]" name Location.pp node.lid
  | Call name -> Fmt.fmt ppf "%s(...)[l_%a]" name Location.pp node.lid
  | Return name -> Fmt.fmt ppf "%s[l_%a]" name Location.pp node.lid

let str (node : t) : string = Fmt.str "%a" pp node [@@inline]

let name (node : t) : string =
  match node.kind with
  | TaintSink sink -> Tainted.(name !sink)
  | Object name -> name
  | Function name -> name
  | Parameter name -> name
  | Call name -> name
  | Return name -> name
  | _ -> Log.fail "unexpected node without name"

let label (node : t) : string =
  (* TODO: add a flag to show the graph locations in the labels *)
  match node.kind with
  | Literal -> "{ Literal Node }"
  | TaintSource -> "{ Taint Source }"
  | TaintSink sink -> Fmt.str "%s sink" Tainted.(name !sink)
  | Object name -> Fmt.str "%s" name
  | Function name -> Fmt.str "function %s" name
  | Parameter name -> Fmt.str "%s" name
  | Call name -> Fmt.str "%s(...)" name
  | Return name -> Fmt.str "%s" name

let create_literal () : t =
  let literal_loc = Location.literal () in
  let region = Region.default () in
  create literal_loc literal_loc region Literal None

let create_sink (sink : Tainted.sink) : t =
  let uid = Location.create uid_gen in
  let lid = Location.create sink_lid_gen in
  let region = Region.default () in
  create uid lid region (TaintSink sink) None

let create_object (name : string) : Region.t -> t option -> t =
 fun region parent ->
  let uid = Location.create uid_gen in
  let lid = Location.create obj_lid_gen in
  create uid lid region (Object name) parent

let create_function (name : string) : Region.t -> t option -> t =
 fun region parent ->
  let uid = Location.create uid_gen in
  let lid = Location.create func_lid_gen in
  create uid lid region (Function name) parent

let create_parameter (idx : int) (name : string) : Region.t -> t option -> t =
 fun region parent ->
  let uid = Location.create uid_gen in
  create uid idx region (Parameter name) parent

let create_call (name : string) : Region.t -> t option -> t =
 fun region parent ->
  let uid = Location.create uid_gen in
  let lid = Location.create obj_lid_gen in
  create uid lid region (Call name) parent

let create_return (name : string) : Region.t -> t option -> t =
 fun region parent ->
  let uid = Location.create uid_gen in
  let lid = Location.create obj_lid_gen in
  create uid lid region (Return name) parent

module Set = struct
  include Set.Make (struct
    type elt = t

    let compare : elt -> elt -> int = compare
  end)

  let pp (ppf : Fmt.t) (nodes : t) : unit =
    if is_empty nodes then Fmt.pp_str ppf "{}"
    else Fmt.fmt ppf "{ %a }" Fmt.(pp_iter iter !>", " pp) nodes

  let str (nodes : t) : string = Fmt.str "%a" pp nodes [@@inline]
end
