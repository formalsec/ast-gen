open Graphjs_base
open Graphjs_ast

module Config = struct
  include Config

  let invalid_loc : Location.t t = constant (-1)
  let literal_loc : Location.t t = constant 0
end

open struct
  let uid_gen : Location.t Generator.t = Location.make_generator ()
  let obj_lid_gen : Location.t Generator.t = Location.make_generator ()
  let func_lid_gen : Location.t Generator.t = Location.make_generator ()
  let sink_lid_gen : Location.t Generator.t = Location.make_generator ()
end

type kind =
  | Literal
  | Object of string
  | Function of string
  | Parameter of string
  | Call of string
  | Return of string
  | Module of string
  | TaintSink of Tainted.sink

type t =
  { uid : Location.t
  ; lid : Location.t
  ; kind : kind
  ; parent : t option
  ; at : Region.t
  }

let default : unit -> t =
  let at = Region.default () in
  let id = Config.(!invalid_loc) in
  let dflt = { uid = id; lid = id; kind = Literal; parent = None; at } in
  fun () -> dflt

let reset () : unit =
  Location.reset uid_gen;
  Location.reset obj_lid_gen;
  Location.reset func_lid_gen;
  Location.reset sink_lid_gen

let create (uid : Location.t) (lid : Location.t) (kind : kind)
    (parent : t option) (at : Region.t) : t =
  { uid; lid; kind; parent; at }

let kind (node : t) : kind = node.kind [@@inline]
let parent (node : t) : t option = node.parent [@@inline]
let at (node : t) : Region.t = node.at [@@inline]
let hash (node : t) : int = Location.hash node.uid [@@inline]
let equal (node1 : t) (node2 : t) : bool = Location.equal node1.uid node2.uid
let compare (node1 : t) (node2 : t) : int = Location.compare node1.uid node2.uid

let pp (ppf : Fmt.t) (node : t) : unit =
  match node.kind with
  | Literal -> Fmt.pp_str ppf "[[literal]]"
  | Object name -> Fmt.fmt ppf "%s[l_%a]" name Location.pp node.lid
  | Function name -> Fmt.fmt ppf "%s[f_%a]" name Location.pp node.lid
  | Parameter name -> Fmt.fmt ppf "%s[p_%a]" name Location.pp node.lid
  | Call name -> Fmt.fmt ppf "%s(...)[l_%a]" name Location.pp node.lid
  | Return name -> Fmt.fmt ppf "%s[l_%a]" name Location.pp node.lid
  | Module name -> Fmt.fmt ppf "require(%s)[l_%a]" name Location.pp node.lid
  | TaintSink sink ->
    Fmt.fmt ppf "%s[s_%a]" Tainted.(name !sink) Location.pp node.lid

let str (node : t) : string = Fmt.str "%a" pp node [@@inline]

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

let create_literal () : t =
  let uid = Config.(!literal_loc) in
  let lid = Config.(!literal_loc) in
  let at = Region.default () in
  create uid lid Literal None at

let create_literal_object (name : string) : t option -> Region.t -> t =
 fun parent at ->
  let uid = Location.create uid_gen in
  let lid = Config.(!literal_loc) in
  create uid lid (Object name) parent at

let create_object (name : string) : t option -> Region.t -> t =
 fun parent at ->
  let uid = Location.create uid_gen in
  let lid = Location.create obj_lid_gen in
  create uid lid (Object name) parent at

let create_function (name : string) : t option -> Region.t -> t =
 fun parent at ->
  let uid = Location.create uid_gen in
  let lid = Location.create func_lid_gen in
  create uid lid (Function name) parent at

let create_sink (sink : Tainted.sink) : t =
  let uid = Location.create uid_gen in
  let lid = Location.create sink_lid_gen in
  let at = Region.default () in
  create uid lid (TaintSink sink) None at

let create_parameter (idx : int) (name : string) : t option -> Region.t -> t =
 fun parent at ->
  let uid = Location.create uid_gen in
  create uid idx (Parameter name) parent at

let create_call (name : string) : t option -> Region.t -> t =
 fun parent at ->
  let uid = Location.create uid_gen in
  let lid = Location.create obj_lid_gen in
  create uid lid (Call name) parent at

let create_return (name : string) : t option -> Region.t -> t =
 fun parent at ->
  let uid = Location.create uid_gen in
  let lid = Location.create obj_lid_gen in
  create uid lid (Return name) parent at

let create_module (name : string) : t option -> Region.t -> t =
 fun parent at ->
  let uid = Location.create uid_gen in
  let lid = Location.create obj_lid_gen in
  create uid lid (Module name) parent at

let is_literal (node : t) : bool =
  match node.kind with Literal -> true | _ -> false

let is_literal_object (node : t) : bool =
  match node.kind with
  | Object _ when node.lid == Config.(!literal_loc) -> true
  | _ -> false

let is_module (node : t) : bool =
  match node.kind with Module _ -> true | _ -> false

let name (node : t) : string =
  match node.kind with
  | Object name -> name
  | Function name -> name
  | Parameter name -> name
  | Call name -> name
  | Return name -> name
  | TaintSink sink -> Tainted.(name !sink)
  | _ -> Log.fail "unexpected node without an associated name"
