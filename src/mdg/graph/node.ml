open Graphjs_base
open Graphjs_ast

module Config = struct
  include Config

  let uid_gen = constant (Location.make_generator ())
  let obj_lid_gen = constant (Location.make_generator ())
  let func_lid_gen = constant (Location.make_generator ())
  let sink_lid_gen = constant (Location.make_generator ())
end

let reset_generators () : unit =
  Location.reset_generator Config.(!uid_gen);
  Location.reset_generator Config.(!obj_lid_gen);
  Location.reset_generator Config.(!func_lid_gen);
  Location.reset_generator Config.(!sink_lid_gen)

type kind =
  | Literal of Literal.t
  | Object of string
  | Function of string
  | Parameter of string
  | Call of string
  | Return of string
  | Import of string
  | TaintSource
  | TaintSink of Tainted.sink

type t =
  { uid : Location.t
  ; lid : Location.t
  ; kind : kind
  ; parent : t option
  ; at : Region.t
  }

let default =
  let id = Location.invalid () in
  let at = Region.default () in
  let kind = Literal (Literal.default ()) in
  let dflt = { uid = id; lid = id; kind; parent = None; at } in
  fun () -> dflt

let create (uid : Location.t) (lid : Location.t) (kind : kind)
    (parent : t option) (at : Region.t) : t =
  { uid; lid; kind; parent; at }

let uid (node : t) : Location.t = node.uid
let lid (node : t) : Location.t = node.lid
let kind (node : t) : kind = node.kind
let parent (node : t) : t option = node.parent
let at (node : t) : Region.t = node.at
let hash (node : t) : int = Location.hash node.uid
let equal (node1 : t) (node2 : t) : bool = Location.equal node1.uid node2.uid
let compare (node1 : t) (node2 : t) : int = Location.compare node1.uid node2.uid

let pp (ppf : Fmt.t) (node : t) : unit =
  match node.kind with
  | Literal lit when Literal.is_default lit -> Literal.pp ppf lit
  | Literal lit -> Fmt.fmt ppf "%a[l_%a]" Literal.pp lit Location.pp node.lid
  | Object name -> Fmt.fmt ppf "%s[l_%a]" name Location.pp node.lid
  | Function name -> Fmt.fmt ppf "%s[f_%a]" name Location.pp node.lid
  | Parameter name -> Fmt.fmt ppf "%s[p_%a]" name Location.pp node.lid
  | Call name -> Fmt.fmt ppf "%s(...)[l_%a]" name Location.pp node.lid
  | Return name -> Fmt.fmt ppf "%s[l_%a]" name Location.pp node.lid
  | Import name -> Fmt.fmt ppf "import(%s)[l_%a]" name Location.pp node.lid
  | TaintSource -> Fmt.pp_str ppf "[[taint]]"
  | TaintSink sink ->
    Fmt.fmt ppf "%s[s_%a]" Tainted.(name !sink) Location.pp node.lid

let str (node : t) : string = Fmt.str "%a" pp node

module Set = struct
  include Set.Make (struct
    type elt = t

    let compare = compare
  end)

  let pp (ppf : Fmt.t) (nodes : t) : unit =
    if is_empty nodes then Fmt.pp_str ppf "{}"
    else Fmt.fmt ppf "{ %a }" Fmt.(pp_iter iter !>", " pp) nodes

  let str (nodes : t) : string = Fmt.str "%a" pp nodes
end

let create_default_literal () : t =
  let uid = Location.create Config.(!uid_gen) in
  let lid = Location.literal () in
  let kind = Literal (Literal.default ()) in
  create uid lid kind None (Region.default ())

let create_literal (literal : Literal.t) : t option -> Region.t -> t =
 fun parent at ->
  let uid = Location.create Config.(!uid_gen) in
  let lid = Location.literal () in
  create uid lid (Literal literal) parent at

let create_object (name : string) : t option -> Region.t -> t =
 fun parent at ->
  let uid = Location.create Config.(!uid_gen) in
  let lid = Location.create Config.(!obj_lid_gen) in
  create uid lid (Object name) parent at

let create_function (name : string) : t option -> Region.t -> t =
 fun parent at ->
  let uid = Location.create Config.(!uid_gen) in
  let lid = Location.create Config.(!func_lid_gen) in
  create uid lid (Function name) parent at

let create_parameter (idx : int) (name : string) : t option -> Region.t -> t =
 fun parent at ->
  let uid = Location.create Config.(!uid_gen) in
  create uid idx (Parameter name) parent at

let create_call (name : string) : t option -> Region.t -> t =
 fun parent at ->
  let uid = Location.create Config.(!uid_gen) in
  let lid = Location.create Config.(!obj_lid_gen) in
  create uid lid (Call name) parent at

let create_return (name : string) : t option -> Region.t -> t =
 fun parent at ->
  let uid = Location.create Config.(!uid_gen) in
  let lid = Location.create Config.(!obj_lid_gen) in
  create uid lid (Return name) parent at

let create_import (name : string) : t option -> Region.t -> t =
 fun parent at ->
  let uid = Location.create Config.(!uid_gen) in
  let lid = Location.create Config.(!obj_lid_gen) in
  create uid lid (Import name) parent at

let create_taint_source () : t =
  let uid = Location.create Config.(!uid_gen) in
  let lid = Location.taint_source () in
  create uid lid TaintSource None (Region.default ())

let create_taint_sink (sink : Tainted.sink) : t option -> Region.t -> t =
 fun parent at ->
  let uid = Location.create Config.(!uid_gen) in
  let lid = Location.create Config.(!obj_lid_gen) in
  create uid lid (TaintSink sink) parent at

let create_candidate_object (name : string) : t =
  let uid = Location.create Config.(!uid_gen) in
  let lid = Location.invalid () in
  create uid lid (Object name) None (Region.default ())

let create_candidate_function (name : string) : t =
  let uid = Location.create Config.(!uid_gen) in
  let lid = Location.invalid () in
  create uid lid (Function name) None (Region.default ())

let create_candidate_sink (sink : Tainted.sink) : t =
  let uid = Location.create Config.(!uid_gen) in
  let lid = Location.invalid () in
  create uid lid (TaintSink sink) None (Region.default ())

let concretize (node : t) : t =
  match node.kind with
  | Object _ -> { node with lid = Location.create Config.(!obj_lid_gen) }
  | Function _ -> { node with lid = Location.create Config.(!func_lid_gen) }
  | TaintSink _ -> { node with lid = Location.create Config.(!sink_lid_gen) }
  | _ -> Log.fail "unexpected kind for the candidate node"

let is_invalid (node : t) : bool = Location.equal node.lid (Location.invalid ())

let is_literal (node : t) : bool =
  match node.kind with Literal _ -> true | _ -> false

let is_object (node : t) : bool =
  match node.kind with
  | Object _ -> not (Location.equal node.lid (Location.literal ()))
  | _ -> false

let is_function (node : t) : bool =
  match node.kind with Function _ -> true | _ -> false

let is_parameter (node : t) : bool =
  match node.kind with Parameter _ -> true | _ -> false

let is_call (node : t) : bool =
  match node.kind with Call _ -> true | _ -> false

let is_return (node : t) : bool =
  match node.kind with Return _ -> true | _ -> false

let is_import (node : t) : bool =
  match node.kind with Import _ -> true | _ -> false

let is_taint_source (node : t) : bool =
  match node.kind with TaintSource -> true | _ -> false

let is_taint_sink (node : t) : bool =
  match node.kind with TaintSink _ -> true | _ -> false

let name (node : t) : string =
  match node.kind with
  | Object name -> name
  | Function name -> name
  | Parameter name -> name
  | Call name -> name
  | Return name -> name
  | TaintSink sink -> Tainted.(name !sink)
  | _ -> Log.fail "unexpected node '%a' without name" pp node

let func (node : t) : t option =
  match node.kind with Function _ -> Some node | _ -> node.parent

let sink (node : t) : Tainted.sink =
  match node.kind with
  | TaintSink sink -> sink
  | _ -> Log.fail "unexpected node '%a' without tainted sink" pp node
