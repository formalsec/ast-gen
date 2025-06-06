module Region = struct
  include Region
end

module Metadata = struct
  include Metadata
end

module Identifier = struct
  open Metadata

  type t' = Ast.Identifier.t'
  type 'm t = 'm Ast.Identifier.t

  open struct
    let gen = Generator.of_strings ~init:1 "$v"
  end

  let reset_generator () = gen.reset ()
  let create (name : string) : t' = { name; generated = false }
  let random () : t' = { name = gen.next (); generated = true }
  let of_lval (lval : 'm Ast.LeftValue.t) : 'm t = lval.el.id @> lval.md

  let of_expr (expr : 'm Ast.Expression.t) : 'm t =
    match expr.el with
    | `Identifier id -> id @> expr.md
    | `This () -> create "this" @> expr.md
    | _ -> Log.fail "unexpected non-identifier expression"

  let create_expr (name : string) : 'm Ast.Expression.t' =
    `Identifier (create name)

  let random_expr () : 'm Ast.Expression.t' = `Identifier (random ())
  let undefined_expr () : 'm Ast.Expression.t' = create_expr "undefined"
  let to_expr (id : 'm t) : 'm Ast.Expression.t' = `Identifier id.el
  let pp (ppf : Fmt.t) (id : 'm t) : unit = Printer.pp_identifier ppf id
  let str (id : 'm t) : string = Fmt.str "%a" pp id
  let name' (id : t') : string = id.name
  let name (id : 'm t) : string = id.el.name
  let generated' (id : t') : bool = id.generated
  let generated (id : 'm t) : bool = id.el.generated
end

module LeftValue = struct
  open Metadata

  type t' = Ast.LeftValue.t'
  type 'm t = 'm Ast.LeftValue.t

  let create ?(kind = Ast.LeftValue.Kind.None) (name : string) : t' =
    { id = Identifier.create name; kind }

  let random () : t' = { id = Identifier.random (); kind = Let }

  let of_identifier ?(kind = Ast.LeftValue.Kind.None) (id : 'm Ast.Identifier.t)
      : 'm t =
    Ast.LeftValue.{ id = id.el; kind } @> id.md

  let to_expr (lval : 'm t) : 'm Ast.Expression.t' = `Identifier lval.el.id
  let initialize (lval : 'm t) : 'm t = { lval.el with kind = None } @> lval.md
  let pp (ppf : Fmt.t) (lval : 'm t) : unit = Printer.pp_leftvalue ppf lval
  let str (lval : 'm t) : string = Fmt.str "%a" pp lval
  let name' (lval : t') : string = Identifier.name' lval.id
  let name (lval : 'm t) : string = Identifier.name' lval.el.id
  let generated' (lval : t') : bool = Identifier.generated' lval.id
  let generated (lval : 'm t) : bool = Identifier.generated' lval.el.id
  let kind' (lval : t') : Ast.LeftValue.Kind.t = lval.kind
  let kind (lval : 'm t) : Ast.LeftValue.Kind.t = lval.el.kind
end

module LeftValueKind = struct
  include Ast.LeftValue.Kind

  let pp (ppf : Fmt.t) (kind : t) : unit = Printer.pp_leftvalue_kind ppf kind
  let str (kind : t) : string = Fmt.str "%a" pp kind
end

module Prop = struct
  include Ast.Prop

  let pp (ppf : Fmt.t) (prop : 'm t) : unit = Printer.pp_prop ppf prop
  let str (prop : 'm t) : string = Fmt.str "%a" pp prop

  let name (prop : 'm t) : string =
    match prop.el with
    | IProp id -> Identifier.name' id
    | LProp { value = String name; _ } -> name
    | LProp { raw; _ } -> raw
end

module Regex = struct
  include Ast.Expression.LiteralValue.Regex

  let create (pattern : string) (flags : string) : t = { pattern; flags }
  let pp (ppf : Fmt.t) (regex : t) : unit = Printer.pp_regex ppf regex
  let str (regex : t) : string = Fmt.str "%a" pp regex
end

module LiteralValue = struct
  include Ast.Expression.LiteralValue

  let create (value : t') (raw : string) : t = { value; raw }
  let null () : t = create Null "null"
  let string (value : string) (raw : string) : t = create (String value) raw
  let number (value : float) (raw : string) : t = create (Number value) raw
  let boolean (value : bool) : t = create (Boolean value) (string_of_bool value)
  let regex (value : Regex.t) (raw : string) : t = create (Regex value) raw

  let bigint (value : int64 option) (raw : string) : t =
    create (BigInt value) raw

  let integer (value : int) : t =
    create (Number (float_of_int value)) (string_of_int value)

  let to_expr (literal : t) : 'm Ast.Expression.t' = `LiteralValue literal
  let pp (ppf : Fmt.t) (literal : t) : unit = Printer.pp_literal ppf literal
  let str (literal : t) : string = Fmt.str "%a" pp literal
end

module TemplateLiteral = struct
  type 'm t = 'm Ast.Expression.TemplateLiteral.t

  let create (quasis : 'm Ast.Expression.TemplateLiteral.Element.t list)
      (exprs : 'm Ast.Expression.t list) : 'm t =
    { quasis; exprs }

  let create_expr (quasis : 'm Ast.Expression.TemplateLiteral.Element.t list)
      (exprs : 'm Ast.Expression.t list) : 'm Ast.Expression.t' =
    `TemplateLiteral (create quasis exprs)

  let pp (ppf : Fmt.t) (tliteral : 'm t) : unit =
    Printer.pp_template_literal ppf tliteral

  let str (tliteral : 'm t) : string = Fmt.str "%a" pp tliteral
end

module TemplateElement = struct
  type t' = Ast.Expression.TemplateLiteral.Element.t'
  type 'm t = 'm Ast.Expression.TemplateLiteral.Element.t

  let create (value : Ast.Expression.TemplateLiteral.Element.Value.t)
      (tail : bool) : t' =
    { value; tail }

  let to_expr (telement : 'm t) : 'm Ast.Expression.t' =
    let value = telement.el.value.raw in
    let raw = Fmt.str "%S" value in
    let literal = LiteralValue.string value raw in
    LiteralValue.to_expr literal

  let pp (ppf : Fmt.t) (telement : 'm t) : unit =
    Printer.pp_template_element ppf telement

  let str (telement : 'm t) : string = Fmt.str "%a" pp telement
end

module TemplateValue = struct
  include Ast.Expression.TemplateLiteral.Element.Value

  let create (raw : string) (cooked : string) : t = { raw; cooked }

  let pp (ppf : Fmt.t) (tvalue : t) : unit =
    Printer.pp_template_value ppf tvalue

  let str (tvalue : t) : string = Fmt.str "%a" pp tvalue
end

module This = struct
  include Ast.Expression.This

  let create () : t = ()
  let create_expr () : 'm Ast.Expression.t' = `This (create ())
  let pp (ppf : Fmt.t) (this : t) : unit = Printer.pp_this ppf this
  let str (this : t) : string = Fmt.str "%a" pp this
end

module Expression = struct
  type 'm t' = 'm Ast.Expression.t'
  type 'm t = 'm Ast.Expression.t

  let pp (ppf : Fmt.t) (expr : 'm t) : unit = Printer.pp_expr ppf expr
  let str (expr : 'm t) : string = Fmt.str "%a" pp expr
end

module ExprStmt = struct
  type 'm t = 'm Ast.Expression.t'

  let create_stmt (expr : 'm Ast.Expression.t') : 'm Ast.Statement.t' =
    `ExprStmt expr

  let pp (ppf : Fmt.t) (expr : 'm t) : unit = Printer.pp_expr_stmt ppf expr
  let str (expr : 'm t) : string = Fmt.str "%a" pp expr
end

module VarDecl = struct
  type t' = Ast.LeftValue.t'

  let create_stmt (lval : Ast.LeftValue.t') : 'm Ast.Statement.t' =
    `VarDecl lval

  let pp (ppf : Fmt.t) (vdecl : t') : unit = Printer.pp_vdecl ppf vdecl
  let str (vdecl : t') : string = Fmt.str "%a" pp vdecl
end

module Assignment = struct
  type 'm t = 'm Ast.Statement.Assignment.t

  let create (left : 'm Ast.LeftValue.t) (right : 'm Ast.Expression.t) : 'm t =
    { left; right }

  let create_stmt (left : 'm Ast.LeftValue.t) (right : 'm Ast.Expression.t) :
      'm Ast.Statement.t' =
    `Assignment (create left right)

  let pp (ppf : Fmt.t) (assign : 'm t) : unit = Printer.pp_assignment ppf assign
  let str (assign : 'm t) : string = Fmt.str "%a" pp assign
end

module NewObject = struct
  type 'm t = 'm Ast.Statement.NewObject.t

  let create (left : 'm Ast.LeftValue.t) : 'm t = { left }

  let create_stmt (left : 'm Ast.LeftValue.t) : 'm Ast.Statement.t' =
    `NewObject (create left)

  let pp (ppf : Fmt.t) (obj : 'm t) : unit = Printer.pp_newobj ppf obj
  let str (obj : 'm t) : string = Fmt.str "%a" pp obj
end

module NewArray = struct
  type 'm t = 'm Ast.Statement.NewArray.t

  let create (left : 'm Ast.LeftValue.t) : 'm t = { left }

  let create_stmt (left : 'm Ast.LeftValue.t) : 'm Ast.Statement.t' =
    `NewArray (create left)

  let pp (ppf : Fmt.t) (arr : 'm t) : unit = Printer.pp_newarray ppf arr
  let str (arr : 'm t) : string = Fmt.str "%a" pp arr
end

module Unopt = struct
  type 'm t = 'm Ast.Statement.Unopt.t

  let create (op : Ast.Operator.unary) (left : 'm Ast.LeftValue.t)
      (arg : 'm Ast.Expression.t) : 'm t =
    { op; left; arg }

  let create_stmt (op : Ast.Operator.unary) (left : 'm Ast.LeftValue.t)
      (arg : 'm Ast.Expression.t) : 'm Ast.Statement.t' =
    `Unopt (create op left arg)

  let pp (ppf : Fmt.t) (unopt : 'm t) : unit = Printer.pp_unopt ppf unopt
  let str (unopt : 'm t) : string = Fmt.str "%a" pp unopt
end

module Binopt = struct
  type 'm t = 'm Ast.Statement.Binopt.t

  let create (op : Ast.Operator.binary) (left : 'm Ast.LeftValue.t)
      (arg1 : 'm Ast.Expression.t) (arg2 : 'm Ast.Expression.t) : 'm t =
    { op; left; arg1; arg2 }

  let create_stmt (op : Ast.Operator.binary) (left : 'm Ast.LeftValue.t)
      (arg1 : 'm Ast.Expression.t) (arg2 : 'm Ast.Expression.t) :
      'm Ast.Statement.t' =
    `Binopt (create op left arg1 arg2)

  let pp (ppf : Fmt.t) (binopt : 'm t) : unit = Printer.pp_binopt ppf binopt
  let str (binopt : 'm t) : string = Fmt.str "%a" pp binopt
end

module Yield = struct
  type 'm t = 'm Ast.Statement.Yield.t

  let create (left : 'm Ast.LeftValue.t) (arg : 'm Ast.Expression.t option)
      (delegate : bool) : 'm t =
    { left; arg; delegate }

  let create_stmt (left : 'm Ast.LeftValue.t) (arg : 'm Ast.Expression.t option)
      (delegate : bool) : 'm Ast.Statement.t' =
    `Yield (create left arg delegate)

  let pp (ppf : Fmt.t) (yield : 'm t) : unit = Printer.pp_yield ppf yield
  let str (yield : 'm t) : string = Fmt.str "%a" pp yield
end

module StaticLookup = struct
  type 'm t = 'm Ast.Statement.StaticLookup.t

  let create (left : 'm Ast.LeftValue.t) (obj : 'm Ast.Expression.t)
      (prop : 'm Prop.t) : 'm t =
    { left; obj; prop }

  let create_stmt (left : 'm Ast.LeftValue.t) (obj : 'm Ast.Expression.t)
      (prop : 'm Prop.t) : 'm Ast.Statement.t' =
    `StaticLookup (create left obj prop)

  let pp (ppf : Fmt.t) (lookup : 'm t) : unit = Printer.pp_slookup ppf lookup
  let str (lookup : 'm t) : string = Fmt.str "%a" pp lookup
end

module DynamicLookup = struct
  type 'm t = 'm Ast.Statement.DynamicLookup.t

  let create (left : 'm Ast.LeftValue.t) (obj : 'm Ast.Expression.t)
      (prop : 'm Ast.Expression.t) : 'm t =
    { left; obj; prop }

  let create_stmt (left : 'm Ast.LeftValue.t) (obj : 'm Ast.Expression.t)
      (prop : 'm Ast.Expression.t) : 'm Ast.Statement.t' =
    `DynamicLookup (create left obj prop)

  let pp (ppf : Fmt.t) (lookup : 'm t) : unit = Printer.pp_dlookup ppf lookup
  let str (lookup : 'm t) : string = Fmt.str "%a" pp lookup
end

module StaticUpdate = struct
  type 'm t = 'm Ast.Statement.StaticUpdate.t

  let create (obj : 'm Ast.Expression.t) (prop : 'm Prop.t)
      (right : 'm Ast.Expression.t) : 'm t =
    { obj; prop; right }

  let create_stmt (obj : 'm Ast.Expression.t) (prop : 'm Prop.t)
      (right : 'm Ast.Expression.t) : 'm Ast.Statement.t' =
    `StaticUpdate (create obj prop right)

  let pp (ppf : Fmt.t) (update : 'm t) : unit = Printer.pp_supdate ppf update
  let str (update : 'm t) : string = Fmt.str "%a" pp update
end

module DynamicUpdate = struct
  type 'm t = 'm Ast.Statement.DynamicUpdate.t

  let create (obj : 'm Ast.Expression.t) (prop : 'm Ast.Expression.t)
      (right : 'm Ast.Expression.t) : 'm t =
    { obj; prop; right }

  let create_stmt (obj : 'm Ast.Expression.t) (prop : 'm Ast.Expression.t)
      (right : 'm Ast.Expression.t) : 'm Ast.Statement.t' =
    `DynamicUpdate (create obj prop right)

  let pp (ppf : Fmt.t) (update : 'm t) : unit = Printer.pp_dupdate ppf update
  let str (update : 'm t) : string = Fmt.str "%a" pp update
end

module StaticDelete = struct
  type 'm t = 'm Ast.Statement.StaticDelete.t

  let create (left : 'm Ast.LeftValue.t) (obj : 'm Ast.Expression.t)
      (prop : 'm Prop.t) : 'm t =
    { left; obj; prop }

  let create_stmt (left : 'm Ast.LeftValue.t) (obj : 'm Ast.Expression.t)
      (prop : 'm Prop.t) : 'm Ast.Statement.t' =
    `StaticDelete (create left obj prop)

  let pp (ppf : Fmt.t) (delete : 'm t) : unit = Printer.pp_sdelete ppf delete
  let str (delete : 'm t) : string = Fmt.str "%a" pp delete
end

module DynamicDelete = struct
  type 'm t = 'm Ast.Statement.DynamicDelete.t

  let create (left : 'm Ast.LeftValue.t) (obj : 'm Ast.Expression.t)
      (prop : 'm Ast.Expression.t) : 'm t =
    { left; obj; prop }

  let create_stmt (left : 'm Ast.LeftValue.t) (obj : 'm Ast.Expression.t)
      (prop : 'm Ast.Expression.t) : 'm Ast.Statement.t' =
    `DynamicDelete (create left obj prop)

  let pp (ppf : Fmt.t) (delete : 'm t) : unit = Printer.pp_ddelete ppf delete
  let str (delete : 'm t) : string = Fmt.str "%a" pp delete
end

module NewCall = struct
  type 'm t = 'm Ast.Statement.NewCall.t

  let create (left : 'm Ast.LeftValue.t) (callee : 'm Ast.Identifier.t)
      (args : 'm Ast.Expression.t list) : 'm t =
    { left; callee; args }

  let create_stmt (left : 'm Ast.LeftValue.t) (callee : 'm Ast.Identifier.t)
      (args : 'm Ast.Expression.t list) : 'm Ast.Statement.t' =
    `NewCall (create left callee args)

  let pp (ppf : Fmt.t) (call : 'm t) : unit = Printer.pp_newcall ppf call
  let str (call : 'm t) : string = Fmt.str "%a" pp call
end

module FunctionCall = struct
  type 'm t = 'm Ast.Statement.FunctionCall.t

  let create (left : 'm Ast.LeftValue.t) (callee : 'm Ast.Identifier.t)
      (args : 'm Ast.Expression.t list) : 'm t =
    { left; callee; args }

  let create_stmt (left : 'm Ast.LeftValue.t) (callee : 'm Ast.Identifier.t)
      (args : 'm Ast.Expression.t list) : 'm Ast.Statement.t' =
    `FunctionCall (create left callee args)

  let pp (ppf : Fmt.t) (call : 'm t) : unit = Printer.pp_funcall ppf call
  let str (call : 'm t) : string = Fmt.str "%a" pp call
end

module StaticMethodCall = struct
  type 'm t = 'm Ast.Statement.StaticMethodCall.t

  let create (left : 'm Ast.LeftValue.t) (obj : 'm Ast.Expression.t)
      (prop : 'm Ast.Prop.t) (args : 'm Ast.Expression.t list) : 'm t =
    { left; obj; prop; args }

  let create_stmt (left : 'm Ast.LeftValue.t) (obj : 'm Ast.Expression.t)
      (prop : 'm Ast.Prop.t) (args : 'm Ast.Expression.t list) :
      'm Ast.Statement.t' =
    `StaticMethodCall (create left obj prop args)

  let pp (ppf : Fmt.t) (call : 'm t) : unit = Printer.pp_smetcall ppf call
  let str (call : 'm t) : string = Fmt.str "%a" pp call
end

module DynamicMethodCall = struct
  type 'm t = 'm Ast.Statement.DynamicMethodCall.t

  let create (left : 'm Ast.LeftValue.t) (obj : 'm Ast.Expression.t)
      (prop : 'm Ast.Expression.t) (args : 'm Ast.Expression.t list) : 'm t =
    { left; obj; prop; args }

  let create_stmt (left : 'm Ast.LeftValue.t) (obj : 'm Ast.Expression.t)
      (prop : 'm Ast.Expression.t) (args : 'm Ast.Expression.t list) :
      'm Ast.Statement.t' =
    `DynamicMethodCall (create left obj prop args)

  let pp (ppf : Fmt.t) (call : 'm t) : unit = Printer.pp_dmetcall ppf call
  let str (call : 'm t) : string = Fmt.str "%a" pp call
end

module FunctionHoisting = struct
  type t = Ast.Statement.FunctionDefinition.Hoisted.t

  let hoisted (hoisted : t) : bool =
    match hoisted with True -> true | False | Ignore -> false
end

module FunctionDefinition = struct
  type 'm t = 'm Ast.Statement.FunctionDefinition.t

  let create (left : 'm Ast.LeftValue.t) (params : 'm Identifier.t list)
      (body : 'm Ast.Statement.t list) (async : bool) (generator : bool)
      (hoisted : Ast.Statement.FunctionDefinition.Hoisted.t) : 'm t =
    { left; params; body; async; generator; hoisted }

  let create_stmt (left : 'm Ast.LeftValue.t) (params : 'm Identifier.t list)
      (body : 'm Ast.Statement.t list) (async : bool) (generator : bool)
      (hoisted : Ast.Statement.FunctionDefinition.Hoisted.t) :
      'm Ast.Statement.t' =
    `FunctionDefinition (create left params body async generator hoisted)

  let pp (ppf : Fmt.t) (func : 'm t) : unit = Printer.pp_fundef ppf func
  let str (func : 'm t) : string = Fmt.str "%a" pp func
  let is_hoisted (func : 'm t) : bool = FunctionHoisting.hoisted func.hoisted
end

module DynamicImport = struct
  type 'm t = 'm Ast.Statement.DynamicImport.t

  let create (left : 'm Ast.LeftValue.t) (arg : 'm Ast.Expression.t) : 'm t =
    { left; arg }

  let create_stmt (left : 'm Ast.LeftValue.t) (arg : 'm Ast.Expression.t) :
      'm Ast.Statement.t' =
    `DynamicImport (create left arg)

  let pp (ppf : Fmt.t) (import : 'm t) : unit = Printer.pp_dimport ppf import
  let str (import : 'm t) : string = Fmt.str "%a" pp import
end

module If = struct
  type 'm t = 'm Ast.Statement.If.t

  let create (test : 'm Ast.Expression.t) (consequent : 'm Ast.Statement.t list)
      (alternate : 'm Ast.Statement.t list option) : 'm t =
    { test; consequent; alternate }

  let create_stmt (test : 'm Ast.Expression.t)
      (consequent : 'm Ast.Statement.t list)
      (alternate : 'm Ast.Statement.t list option) : 'm Ast.Statement.t' =
    `If (create test consequent alternate)

  let pp (ppf : Fmt.t) (if' : 'm t) : unit = Printer.pp_if ppf if'
  let str (if' : 'm t) : string = Fmt.str "%a" pp if'
end

module Switch = struct
  type 'm t = 'm Ast.Statement.Switch.t

  let create (discriminant : 'm Ast.Expression.t)
      (cases : 'm Ast.Statement.Switch.Case.t list) : 'm t =
    { discriminant; cases }

  let create_stmt (discriminant : 'm Ast.Expression.t)
      (cases : 'm Ast.Statement.Switch.Case.t list) : 'm Ast.Statement.t' =
    `Switch (create discriminant cases)

  let pp (ppf : Fmt.t) (switch : 'm t) : unit = Printer.pp_switch ppf switch
  let str (switch : 'm t) : string = Fmt.str "%a" pp switch
end

module SwitchCase = struct
  type 'm t' = 'm Ast.Statement.Switch.Case.t'
  type 'm t = 'm Ast.Statement.Switch.Case.t

  let create (test : 'm Ast.Expression.t option) (body : 'm Ast.Statement.t list)
      : 'm t' =
    { test; body }

  let pp (ppf : Fmt.t) (case : 'm t) : unit = Printer.pp_switch_case ppf case
  let str (case : 'm t) : string = Fmt.str "%a" pp case
  let test (case : 'm t) : 'm Ast.Expression.t option = case.el.test
  let body (case : 'm t) : 'm Ast.Statement.t list = case.el.body
end

module While = struct
  type 'm t = 'm Ast.Statement.While.t

  let create (test : 'm Ast.Expression.t) (body : 'm Ast.Statement.t list) :
      'm t =
    { test; body }

  let create_stmt (test : 'm Ast.Expression.t) (body : 'm Ast.Statement.t list)
      : 'm Ast.Statement.t' =
    `While (create test body)

  let pp (ppf : Fmt.t) (while' : 'm t) : unit = Printer.pp_while ppf while'
  let str (while' : 'm t) : string = Fmt.str "%a" pp while'
end

module ForIn = struct
  type 'm t = 'm Ast.Statement.ForIn.t

  let create (left : 'm Ast.LeftValue.t) (right : 'm Ast.Expression.t)
      (body : 'm Ast.Statement.t list) : 'm t =
    { left; right; body }

  let create_stmt (left : 'm Ast.LeftValue.t) (right : 'm Ast.Expression.t)
      (body : 'm Ast.Statement.t list) : 'm Ast.Statement.t' =
    `ForIn (create left right body)

  let pp (ppf : Fmt.t) (forin : 'm t) : unit = Printer.pp_forin ppf forin
  let str (forin : 'm t) : string = Fmt.str "%a" pp forin
end

module ForOf = struct
  type 'm t = 'm Ast.Statement.ForOf.t

  let create (left : 'm Ast.LeftValue.t) (right : 'm Ast.Expression.t)
      (body : 'm Ast.Statement.t list) (await : bool) : 'm t =
    { left; right; body; await }

  let create_stmt (left : 'm Ast.LeftValue.t) (right : 'm Ast.Expression.t)
      (body : 'm Ast.Statement.t list) (await : bool) : 'm Ast.Statement.t' =
    `ForOf (create left right body await)

  let pp (ppf : Fmt.t) (forof : 'm t) : unit = Printer.pp_forof ppf forof
  let str (forof : 'm t) : string = Fmt.str "%a" pp forof
end

module Break = struct
  type 'm t = 'm Ast.Statement.Break.t

  let create (label : 'm Ast.Identifier.t option) : 'm t = { label }

  let create_stmt (label : 'm Ast.Identifier.t option) : 'm Ast.Statement.t' =
    `Break (create label)

  let pp (ppf : Fmt.t) (break : 'm t) : unit = Printer.pp_break ppf break
  let str (break : 'm t) : string = Fmt.str "%a" pp break
end

module Continue = struct
  type 'm t = 'm Ast.Statement.Continue.t

  let create (label : 'm Ast.Identifier.t option) : 'm t = { label }

  let create_stmt (label : 'm Ast.Identifier.t option) : 'm Ast.Statement.t' =
    `Continue (create label)

  let pp (ppf : Fmt.t) (continue : 'm t) : unit =
    Printer.pp_continue ppf continue

  let str (continue : 'm t) : string = Fmt.str "%a" pp continue
end

module Return = struct
  type 'm t = 'm Ast.Statement.Return.t

  let create (arg : 'm Ast.Expression.t option) : 'm t = { arg }

  let create_stmt (arg : 'm Ast.Expression.t option) : 'm Ast.Statement.t' =
    `Return (create arg)

  let pp (ppf : Fmt.t) (return : 'm t) : unit = Printer.pp_return ppf return
  let str (return : 'm t) : string = Fmt.str "%a" pp return
end

module Throw = struct
  type 'm t = 'm Ast.Statement.Throw.t

  let create (arg : 'm Ast.Expression.t) : 'm t = { arg }

  let create_stmt (arg : 'm Ast.Expression.t) : 'm Ast.Statement.t' =
    `Throw (create arg)

  let pp (ppf : Fmt.t) (throw : 'm t) : unit = Printer.pp_throw ppf throw
  let str (throw : 'm t) : string = Fmt.str "%a" pp throw
end

module Try = struct
  type 'm t = 'm Ast.Statement.Try.t

  let create (body : 'm Ast.Statement.t list)
      (handler : 'm Ast.Statement.Try.Catch.t option)
      (finalizer : 'm Ast.Statement.t list option) : 'm t =
    { body; handler; finalizer }

  let create_stmt (body : 'm Ast.Statement.t list)
      (handler : 'm Ast.Statement.Try.Catch.t option)
      (finalizer : 'm Ast.Statement.t list option) : 'm Ast.Statement.t' =
    `Try (create body handler finalizer)

  let pp (ppf : Fmt.t) (try' : 'm t) : unit = Printer.pp_try ppf try'
  let str (try' : 'm t) : string = Fmt.str "%a" pp try'
end

module Catch = struct
  type 'm t' = 'm Ast.Statement.Try.Catch.t'
  type 'm t = 'm Ast.Statement.Try.Catch.t

  let create (param : 'm Ast.Identifier.t option)
      (body : 'm Ast.Statement.t list) : 'm t' =
    { param; body }

  let pp (ppf : Fmt.t) (catch : 'm t) : unit = Printer.pp_catch ppf catch
  let str (catch : 'm t) : string = Fmt.str "%a" pp catch
  let param (catch : 'm t) : 'm Ast.Identifier.t option = catch.el.param
  let body (catch : 'm t) : 'm Ast.Statement.t list = catch.el.body
end

module With = struct
  type 'm t = 'm Ast.Statement.With.t

  let create (expr : 'm Ast.Expression.t) (body : 'm Ast.Statement.t list) :
      'm t =
    { expr; body }

  let create_stmt (expr : 'm Ast.Expression.t) (body : 'm Ast.Statement.t list)
      : 'm Ast.Statement.t' =
    `With (create expr body)

  let pp (ppf : Fmt.t) (with' : 'm t) : unit = Printer.pp_with ppf with'
  let str (with' : 'm t) : string = Fmt.str "%a" pp with'
end

module Labeled = struct
  type 'm t = 'm Ast.Statement.Labeled.t

  let create (label : 'm Ast.Identifier.t) (body : 'm Ast.Statement.t list) :
      'm t =
    { label; body }

  let create_stmt (label : 'm Ast.Identifier.t) (body : 'm Ast.Statement.t list)
      : 'm Ast.Statement.t' =
    `Labeled (create label body)

  let pp (ppf : Fmt.t) (labeled : 'm t) : unit = Printer.pp_labeled ppf labeled
  let str (labeled : 'm t) : string = Fmt.str "%a" pp labeled
end

module Debugger = struct
  include Ast.Statement.Debugger

  let create () : t = ()
  let create_stmt () : 'm Ast.Statement.t' = `Debugger (create ())
  let pp (ppf : Fmt.t) (debugger : t) : unit = Printer.pp_debugger ppf debugger
  let str (debugger : t) : string = Fmt.str "%a" pp debugger
end

module ImportDecl = struct
  type 'm specifier = 'm Ast.Statement.ImportDecl.Specifier.t
  type 'm t = 'm Ast.Statement.ImportDecl.t

  let create (specifier : 'm specifier) (source : string) : 'm t =
    { specifier; source }

  let create_stmt (specifier : 'm specifier) (source : string) :
      'm Ast.Statement.t' =
    `ImportDecl (create specifier source)

  let pp (ppf : Fmt.t) (import : 'm t) : unit = Printer.pp_import ppf import
  let str (import : 'm t) : string = Fmt.str "%a" pp import
end

module ExportDecl = struct
  type 'm specifier = 'm Ast.Statement.ExportDecl.Specifier.t
  type 'm t = 'm Ast.Statement.ExportDecl.t

  let create (specifier : 'm specifier) (source : string option) : 'm t =
    { specifier; source }

  let create_stmt (specifier : 'm specifier) (source : string option) :
      'm Ast.Statement.t' =
    `ExportDecl (create specifier source)

  let pp (ppf : Fmt.t) (export : 'm t) : unit = Printer.pp_export ppf export
  let str (export : 'm t) : string = Fmt.str "%a" pp export
end

module Statement = struct
  type 'm t' = 'm Ast.Statement.t'
  type 'm t = 'm Ast.Statement.t

  let pp (ppf : Fmt.t) (stmt : 'm t) : unit = Printer.pp_stmt ppf stmt
  let str (stmt : 'm t) : string = Fmt.str "%a" pp stmt
end

module Operator = struct
  include Ast.Operator

  let pp_unopt (ppf : Fmt.t) (op : unary) : unit = Printer.pp_unopt_op ppf op
  let pp_binopt (ppf : Fmt.t) (op : binary) : unit = Printer.pp_binopt_op ppf op
  let str_unopt (op : unary) : string = Fmt.str "%a" pp_unopt op
  let str_binopt (op : binary) : string = Fmt.str "%a" pp_binopt op
end

module File = struct
  type 'm t = 'm Ast.File.t

  let create (path : Fpath.t) (mrel : Fpath.t) (body : 'm Ast.Statement.t list)
      : 'm t =
    { path; mrel; body }

  let pp (ppf : Fmt.t) (file : 'm t) : unit = Printer.pp_file ppf file
  let str (file : 'm t) : string = Fmt.str "%a" pp file
end

module Prog = struct
  type 'm t = 'm Ast.Prog.t

  let create (main : Fpath.t) (files' : (Fpath.t * 'm File.t) list) : 'm t =
    let files = files' |> List.to_seq |> Hashtbl.of_seq in
    { main; files }

  let find (prog : 'm t) (path : Fpath.t) : 'm Ast.File.t =
    Hashtbl.find prog.files path

  let add (prog : 'm t) (path : Fpath.t) (file : 'm Ast.File.t) : unit =
    Hashtbl.add prog.files path file

  let pp ?(filename = false) (ppf : Fmt.t) (prog : 'm t) : unit =
    Printer.pp_prog ~filename ppf prog

  let str ?(filename = false) (prog : 'm t) : string =
    Fmt.str "%a" (pp ~filename) prog

  let main (prog : 'm t) : 'm Ast.File.t = find prog prog.main
  let is_multifile (prog : 'm t) : bool = Hashtbl.length prog.files > 1
end
