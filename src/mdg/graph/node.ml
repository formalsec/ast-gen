open Graphjs_base
open Graphjs_ast

type kind =
  | Literal of Literal.t
  | Object of string
  | Function of string
  | Parameter of string
  | Call of string
  | Return of string
  | Module of string
  | TaintSource
  | TaintSink of Tainted.sink

type t =
  { loc : Location.t
  ; kind : kind
  ; parent : t option
  ; at : Region.t
  }

let default =
  let loc = Location.invalid () in
  let at = Region.default () in
  let kind = Literal (Literal.default ()) in
  let dflt = { loc; kind; parent = None; at } in
  fun () -> dflt

let create (loc : Location.t) (kind : kind) (parent : t option) (at : Region.t)
    : t =
  { loc; kind; parent; at }

let loc (node : t) : Location.t = node.loc
let kind (node : t) : kind = node.kind
let parent (node : t) : t option = node.parent
let at (node : t) : Region.t = node.at
let hash (node : t) : int = Location.hash node.loc
let equal (node1 : t) (node2 : t) : bool = Location.equal node1.loc node2.loc
let compare (node1 : t) (node2 : t) : int = Location.compare node1.loc node2.loc

let pp (ppf : Fmt.t) (node : t) : unit =
  match node.kind with
  | Literal lit when Literal.is_default lit -> Fmt.fmt ppf "%a" Literal.pp lit
  | Literal lit -> Fmt.fmt ppf "%a[%a]" Literal.pp lit Location.pp node.loc
  | Object name -> Fmt.fmt ppf "%s[%a]" name Location.pp node.loc
  | Function name -> Fmt.fmt ppf "%s[%a]" name Location.pp node.loc
  | Parameter name -> Fmt.fmt ppf "%s[%a]" name Location.pp node.loc
  | Call name -> Fmt.fmt ppf "%s(...)[%a]" name Location.pp node.loc
  | Return name -> Fmt.fmt ppf "%s[%a]" name Location.pp node.loc
  | Module name -> Fmt.fmt ppf "[[module]] %s[%a]" name Location.pp node.loc
  | TaintSource -> Fmt.pp_str ppf "[[taint]]"
  | TaintSink sink -> Fmt.fmt ppf "[[sink]] %s[%a]" sink.name Location.pp node.loc

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
  let loc = Location.create () in
  let kind = Literal (Literal.default ()) in
  create loc kind None (Region.default ())

let create_literal (literal : Literal.t) : t option -> Region.t -> t =
 fun parent at ->
  let loc = Location.create () in
  create loc (Literal literal) parent at

let create_object (name : string) : t option -> Region.t -> t =
 fun parent at ->
  let loc = Location.create () in
  create loc (Object name) parent at

let create_function (name : string) : t option -> Region.t -> t =
 fun parent at ->
  let loc = Location.create () in
  create loc (Function name) parent at

let create_parameter (name : string) : t option -> Region.t -> t =
 fun parent at ->
  let loc = Location.create () in
  create loc (Parameter name) parent at

let create_call (name : string) : t option -> Region.t -> t =
 fun parent at ->
  let loc = Location.create () in
  create loc (Call name) parent at

let create_return (name : string) : t option -> Region.t -> t =
 fun parent at ->
  let loc = Location.create () in
  create loc (Return name) parent at

let create_module (name : string) : t =
  let loc = Location.create () in
  let kind = Module name in
  create loc kind None (Region.default ())

let create_taint_source () : t =
  let loc = Location.create () in
  create loc TaintSource None (Region.default ())

let create_taint_sink (sink : Tainted.sink) : t option -> Region.t -> t =
 fun parent at ->
  let loc = Location.create () in
  create loc (TaintSink sink) parent at

let is_literal (node : t) : bool =
  match node.kind with Literal _ -> true | _ -> false

let is_object (node : t) : bool =
  match node.kind with Object _ -> true | _ -> false

let is_function (node : t) : bool =
  match node.kind with Function _ -> true | _ -> false

let is_parameter (node : t) : bool =
  match node.kind with Parameter _ -> true | _ -> false

let is_call (node : t) : bool =
  match node.kind with Call _ -> true | _ -> false

let is_return (node : t) : bool =
  match node.kind with Return _ -> true | _ -> false

let is_module (node : t) : bool =
  match node.kind with Module _ -> true | _ -> false

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
  | TaintSink sink -> sink.name
  | _ -> Log.fail "unexpected node '%a' without name" pp node

let sink (node : t) : Tainted.sink =
  match node.kind with
  | TaintSink sink -> sink
  | _ -> Log.fail "unexpected node '%a' without tainted sink" pp node
