open Graphjs_ast

type kind =
  | Literal of Literal.t
  | Blank of string
  | Object of string
  | Function of string
  | Parameter of string
  | Call of string
  | Return of string
  | Builtin of string
  | Module of string
  | TaintSink of Taint.Sink.t
  | TaintSource

type t =
  { loc : Location.t
  ; kind : kind
  ; parent : t option
  ; at : Region.t
  }

let default =
  let loc = Location.invalid () in
  let at = Region.default () in
  let dflt = { loc; kind = Blank ""; parent = None; at } in
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
  | Literal lit -> Fmt.fmt ppf "%a[%a]" Literal.pp lit Location.pp node.loc
  | Blank name -> Fmt.fmt ppf "%s[%a]" name Location.pp node.loc
  | Object name -> Fmt.fmt ppf "%s[%a]" name Location.pp node.loc
  | Function name -> Fmt.fmt ppf "[[function]] %s[%a]" name Location.pp node.loc
  | Parameter name -> Fmt.fmt ppf "%s[%a]" name Location.pp node.loc
  | Call name -> Fmt.fmt ppf "%s(...)[%a]" name Location.pp node.loc
  | Return name -> Fmt.fmt ppf "%s[%a]" name Location.pp node.loc
  | Builtin name -> Fmt.fmt ppf "[[builtin]] %s[%a]" name Location.pp node.loc
  | Module name -> Fmt.fmt ppf "[[module]] %s[%a]" name Location.pp node.loc
  | TaintSink sink ->
    Fmt.fmt ppf "[[sink]] %s[%a]" (Taint.Sink.name sink) Location.pp node.loc
  | TaintSource -> Fmt.pp_str ppf "[[taint]]"

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

let create_default (f : 'a -> t option -> Region.t -> t) (a : 'a) : t =
  f a None (Region.default ())

let create_literal (literal : Literal.t) : t option -> Region.t -> t =
  create (Location.create ()) (Literal literal)

let create_blank (name : string) : t option -> Region.t -> t =
  create (Location.create ()) (Blank name)

let create_object (name : string) : t option -> Region.t -> t =
  create (Location.create ()) (Object name)

let create_function (name : string) : t option -> Region.t -> t =
  create (Location.create ()) (Function name)

let create_parameter (name : string) : t option -> Region.t -> t =
  create (Location.create ()) (Parameter name)

let create_call (name : string) : t option -> Region.t -> t =
  create (Location.create ()) (Call name)

let create_return (name : string) : t option -> Region.t -> t =
  create (Location.create ()) (Return name)

let create_builtin (name : string) : t option -> Region.t -> t =
  create (Location.create ()) (Builtin name)

let create_module (name : string) : t option -> Region.t -> t =
  create (Location.create ()) (Module name)

let create_taint_sink (sink : Taint.Sink.t) : t option -> Region.t -> t =
  create (Location.create ()) (TaintSink sink)

let create_taint_source () : t option -> Region.t -> t =
  create (Location.create ()) TaintSource

let create_literal' = create_default create_literal
let create_blank' = create_default create_blank
let create_object' = create_default create_object
let create_function' = create_default create_function
let create_parameter' = create_default create_parameter
let create_call' = create_default create_call
let create_return' = create_default create_return
let create_builtin' = create_default create_builtin
let create_module' = create_default create_module
let create_taint_sink' = create_default create_taint_sink
let create_taint_source' = create_default create_taint_source

let is_literal (node : t) : bool =
  match node.kind with Literal _ -> true | _ -> false

let is_blank (node : t) : bool =
  match node.kind with Object _ -> true | _ -> false

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

let is_builtin (node : t) : bool =
  match node.kind with Builtin _ -> true | _ -> false

let is_module (node : t) : bool =
  match node.kind with Module _ -> true | _ -> false

let is_taint_sink (node : t) : bool =
  match node.kind with TaintSink _ -> true | _ -> false

let is_taint_source (node : t) : bool =
  match node.kind with TaintSource -> true | _ -> false

let name (node : t) : string =
  match node.kind with
  | Blank name -> name
  | Object name -> name
  | Function name -> name
  | Parameter name -> name
  | Call name -> name
  | Return name -> name
  | Builtin name -> name
  | Module name -> name
  | TaintSink sink -> Taint.Sink.name sink
  | _ -> Log.fail "unexpected node '%a' without name" pp node

let sink (node : t) : Taint.Sink.t =
  match node.kind with
  | TaintSink sink -> sink
  | _ -> Log.fail "unexpected node '%a' without tainted sink" pp node
