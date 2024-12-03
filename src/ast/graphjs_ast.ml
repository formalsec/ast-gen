open Graphjs_base

module Config = struct
  include Config

  let test262_conform_hoisted : bool t = Printer.Config.test262_conform_hoisted
end

module Metadata = struct
  include Metadata
end

module Region = struct
  include Region
end

module Identifier = struct
  type t' = Ast.Identifier.t'
  type 'm t = 'm Ast.Identifier.t

  open struct
    let gen : string Generator.t = Generator.of_strings ~init:1 "$v"
  end

  let reset_generator () = gen.reset () [@@inline]
  let create (name : string) : t' = { name; generated = false } [@@inline]
  let random () : t' = { name = gen.next (); generated = true } [@@inline]

  let create_expr (name : string) : 'm Ast.Expression.t' =
    `Identifier (create name)
  [@@inline]

  let random_expr () : 'm Ast.Expression.t' = `Identifier (random ()) [@@inline]

  let undefined_expr () : 'm Ast.Expression.t' = create_expr "undefined"
  [@@inline]

  let of_lval (lval : 'm Ast.LeftValue.t) : 'm t =
    Metadata.(lval.el.id @> lval.md)
  [@@inline]

  and of_expr (expr : 'm Ast.Expression.t) : 'm t =
    match expr.el with
    | `Identifier id -> Metadata.(id @> expr.md)
    | _ -> Log.fail "invalid non-identifier expression"

  let to_expr (id : 'm t) : 'm Ast.Expression.t' = `Identifier id.el

  let pp (ppf : Fmt.t) (id : 'm t) : unit = Printer.pp_identifier ppf id
  [@@inline]

  let str (id : 'm t) : string = Fmt.str "%a" pp id [@@inline]
  let name' (id : t') : string = id.name [@@inline]
  let name (id : 'm t) : string = id.el.name [@@inline]
  let generated' (id : t') : bool = id.generated [@@inline]
  let generated (id : 'm t) : bool = id.el.generated [@@inline]
end

module LeftValueKind = struct
  type t = Ast.LeftValue.Kind.t

  let pp (ppf : Fmt.t) (kind : t) : unit = Printer.pp_leftvalue_kind ppf kind
  [@@inline]

  let str (kind : t) : string = Fmt.str "%a" pp kind [@@inline]
end

module LeftValue = struct
  type t' = Ast.LeftValue.t'
  type 'm t = 'm Ast.LeftValue.t

  let create ?(kind : Ast.LeftValue.Kind.t = None) (name : string) : t' =
    { id = Identifier.create name; kind }
  [@@inline]

  let random () : t' = { id = Identifier.random (); kind = Let } [@@inline]

  let initialized (lval : 'm t) : 'm t =
    Metadata.({ lval.el with kind = None } @> lval.md)
  [@@inline]

  let of_identifier ?(kind : Ast.LeftValue.Kind.t = None)
      (id : 'm Ast.Identifier.t) : 'm t =
    Metadata.(Ast.LeftValue.{ id = id.el; kind } @> id.md)
  [@@inline]

  let to_expr (lval : 'm t) : 'm Ast.Expression.t' = `Identifier lval.el.id
  [@@inline]

  let pp (ppf : Fmt.t) (lval : 'm t) : unit = Printer.pp_leftvalue ppf lval
  [@@inline]

  let str (lval : 'm t) : string = Fmt.str "%a" pp lval [@@inline]
  let name' (lval : t') : string = Identifier.name' lval.id [@@inline]
  let name (lval : 'm t) : string = Identifier.name' lval.el.id [@@inline]
  let kind' (lval : t') : LeftValueKind.t = lval.kind [@@inline]
  let kind (lval : 'm t) : LeftValueKind.t = lval.el.kind [@@inline]
  let generated' (lval : t') : bool = Identifier.generated' lval.id [@@inline]

  let generated (lval : 'm t) : bool = Identifier.generated' lval.el.id
  [@@inline]
end

module Prop = struct
  include Ast.Prop

  let pp (ppf : Fmt.t) (prop : 'm t) : unit = Printer.pp_prop ppf prop
  [@@inline]

  let str (prop : 'm t) : string = Fmt.str "%a" pp prop [@@inline]

  let name (prop : 'm t) : string =
    match prop.el with
    | IProp id -> Identifier.name' id
    | LProp { value = String name; _ } -> name
    | LProp { raw; _ } -> raw
end

module Regex = struct
  type t = Ast.Expression.Literal.Regex.t

  let create (pattern : string) (flags : string) : t = { pattern; flags }
  [@@inline]

  let pp (ppf : Fmt.t) (regex : t) : unit = Printer.pp_regex ppf regex
  [@@inline]

  let str (regex : t) : string = Fmt.str "%a" pp regex [@@inline]
end

module Literal = struct
  type t' = Ast.Expression.Literal.t'
  type t = Ast.Expression.Literal.t

  let create (value : t') (raw : string) : t = { value; raw } [@@inline]
  let null () : t = create Null "null" [@@inline]

  let string (value : string) (raw : string) : t = create (String value) raw
  [@@inline]

  let integer (value : int) : t =
    create (Number (float_of_int value)) (string_of_int value)
  [@@inline]

  let number (value : float) (raw : string) : t = create (Number value) raw
  [@@inline]

  let bigint (value : int64 option) (raw : string) : t =
    create (BigInt value) raw
  [@@inline]

  let boolean (value : bool) : t = create (Boolean value) (string_of_bool value)
  [@@inline]

  let regex (value : Regex.t) (raw : string) : t = create (Regex value) raw
  [@@inline]

  let to_expr (lit : t) : 'm Ast.Expression.t' = `Literal lit [@@inline]

  let pp (ppf : Fmt.t) (literal : t) : unit = Printer.pp_literal ppf literal
  [@@inlinex]

  let str (literal : t) : string = Fmt.str "%a" pp literal [@@inline]
end

module TemplateValue = struct
  type t = Ast.Expression.TemplateLiteral.Element.Value.t

  let create (raw : string) (cooked : string) : t = { raw; cooked } [@@inline]

  let pp (ppf : Fmt.t) (tvalue : t) : unit =
    Printer.pp_template_value ppf tvalue
  [@@inline]

  let str (tvalue : t) : string = Fmt.str "%a" pp tvalue [@@inline]
end

module TemplateElement = struct
  type t' = Ast.Expression.TemplateLiteral.Element.t'
  type 'm t = 'm Ast.Expression.TemplateLiteral.Element.t

  let create (value : Ast.Expression.TemplateLiteral.Element.Value.t)
      (tail : bool) : t' =
    { value; tail }
  [@@inline]

  let to_expr (telement : 'm t) : 'm Ast.Expression.t' =
    let value = telement.el.value.raw in
    let raw = Fmt.str "%S" value in
    Literal.(string value raw |> to_expr)

  let pp (ppf : Fmt.t) (telement : 'm t) : unit =
    Printer.pp_template_element ppf telement
  [@@inline]

  let str (telement : 'm t) : string = Fmt.str "%a" pp telement [@@inline]
end

module TemplateLiteral = struct
  type 'm t = 'm Ast.Expression.TemplateLiteral.t

  let create (quasis : 'm Ast.Expression.TemplateLiteral.Element.t list)
      (exprs : 'm Ast.Expression.t list) : 'm t =
    { quasis; exprs }
  [@@inline]

  let create_expr (quasis : 'm Ast.Expression.TemplateLiteral.Element.t list)
      (exprs : 'm Ast.Expression.t list) : 'm Ast.Expression.t' =
    `TemplateLiteral (create quasis exprs)
  [@@inline]

  let pp (ppf : Fmt.t) (tliteral : 'm t) : unit =
    Printer.pp_template_literal ppf tliteral
  [@@inline]

  let str (tliteral : 'm t) : string = Fmt.str "%a" pp tliteral [@@inline]
end

module This = struct
  type t = Ast.Expression.This.t

  let create () : t = () [@@inline]
  let create_expr () : 'm Ast.Expression.t' = `This (create ()) [@@inline]
  let pp (ppf : Fmt.t) (this : t) : unit = Printer.pp_this ppf this [@@inline]
  let str (this : t) : string = Fmt.str "%a" pp this [@@inline]
end

module Expression = struct
  type 'm t' = 'm Ast.Expression.t'
  type 'm t = 'm Ast.Expression.t

  let pp (ppf : Fmt.t) (expr : 'm t) : unit = Printer.pp_expr ppf expr
  [@@inline]

  let str (expr : 'm t) : string = Fmt.str "%a" pp expr [@@inline]
end

module VarDecl = struct
  type t = Ast.LeftValue.t'

  let create_stmt (lval : Ast.LeftValue.t') : 'm Ast.Statement.t' =
    `VarDecl lval
  [@@inline]

  let pp (ppf : Fmt.t) (vdecl : t) : unit = Printer.pp_vdecl_stmt ppf vdecl
  [@@inline]

  let str (vdecl : t) : string = Fmt.str "%a" pp vdecl
end

module ExprStmt = struct
  type 'm t = 'm Ast.Expression.t'

  let create_stmt (expr : 'm Ast.Expression.t') : 'm Ast.Statement.t' =
    `ExprStmt expr
  [@@inline]

  let pp (ppf : Fmt.t) (expr : 'm t) : unit = Printer.pp_expr_stmt ppf expr
  [@@inline]

  let str (expr : 'm t) : string = Fmt.str "%a" pp expr
end

module AssignSimple = struct
  type 'm t = 'm Ast.Statement.AssignSimple.t

  let create (left : 'm Ast.LeftValue.t) (right : 'm Ast.Expression.t) : 'm t =
    { left; right }
  [@@inline]

  let create_stmt (left : 'm Ast.LeftValue.t) (right : 'm Ast.Expression.t) :
      'm Ast.Statement.t' =
    `AssignSimple (create left right)
  [@@inline]

  let pp (ppf : Fmt.t) (assign : 'm t) : unit =
    Printer.pp_assign_simple ppf assign
  [@@inline]

  let str (assign : 'm t) : string = Fmt.str "%a" pp assign [@@inline]
end

module AssignNewObject = struct
  type 'm t = 'm Ast.Statement.AssignNewObject.t

  let create (left : 'm Ast.LeftValue.t) : 'm t = { left } [@@inline]

  let create_stmt (left : 'm Ast.LeftValue.t) : 'm Ast.Statement.t' =
    `AssignNewObject (create left)
  [@@inline]

  let pp (ppf : Fmt.t) (newobj : 'm t) : unit =
    Printer.pp_assign_newobj ppf newobj
  [@@inline]

  let str (newobj : 'm t) : string = Fmt.str "%a" pp newobj [@@inline]
end

module AssignNewArray = struct
  type 'm t = 'm Ast.Statement.AssignNewArray.t

  let create (left : 'm Ast.LeftValue.t) : 'm t = { left } [@@inline]

  let create_stmt (left : 'm Ast.LeftValue.t) : 'm Ast.Statement.t' =
    `AssignNewArray (create left)
  [@@inline]

  let pp (ppf : Fmt.t) (newarray : 'm t) : unit =
    Printer.pp_assign_newarray ppf newarray
  [@@inline]

  let str (newarray : 'm t) : string = Fmt.str "%a" pp newarray [@@inline]
end

module AssignUnopt = struct
  type 'm t = 'm Ast.Statement.AssignUnopt.t

  let create (left : 'm Ast.LeftValue.t) (operator : Ast.Operator.Unary.t)
      (arg : 'm Ast.Expression.t) : 'm t =
    { left; operator; arg }
  [@@inline]

  let create_stmt (left : 'm Ast.LeftValue.t) (operator : Ast.Operator.Unary.t)
      (arg : 'm Ast.Expression.t) : 'm Ast.Statement.t' =
    `AssignUnopt (create left operator arg)
  [@@inline]

  let pp (ppf : Fmt.t) (unopt : 'm t) : unit = Printer.pp_assign_unopt ppf unopt
  [@@inline]

  let str (unopt : 'm t) : string = Fmt.str "%a" pp unopt [@@inline]
end

module AssignBinopt = struct
  type 'm t = 'm Ast.Statement.AssignBinopt.t

  let create (left : 'm Ast.LeftValue.t) (operator : Ast.Operator.Binary.t)
      (arg1 : 'm Ast.Expression.t) (arg2 : 'm Ast.Expression.t) : 'm t =
    { left; operator; arg1; arg2 }
  [@@inline]

  let create_stmt (left : 'm Ast.LeftValue.t) (operator : Ast.Operator.Binary.t)
      (arg1 : 'm Ast.Expression.t) (arg2 : 'm Ast.Expression.t) :
      'm Ast.Statement.t' =
    `AssignBinopt (create left operator arg1 arg2)
  [@@inline]

  let pp (ppf : Fmt.t) (binopt : 'm t) : unit =
    Printer.pp_assign_binopt ppf binopt
  [@@inline]

  let str (binopt : 'm t) : string = Fmt.str "%a" pp binopt [@@inline]
end

module AssignYield = struct
  type 'm t = 'm Ast.Statement.AssignYield.t

  let create (left : 'm Ast.LeftValue.t) (arg : 'm Ast.Expression.t option)
      (delegate : bool) : 'm t =
    { left; arg; delegate }
  [@@inline]

  let create_stmt (left : 'm Ast.LeftValue.t) (arg : 'm Ast.Expression.t option)
      (delegate : bool) : 'm Ast.Statement.t' =
    `AssignYield (create left arg delegate)
  [@@inline]

  let pp (ppf : Fmt.t) (yield : 'm t) : unit = Printer.pp_assign_yield ppf yield
  [@@inline]

  let str (yield : 'm t) : string = Fmt.str "%a" pp yield [@@inline]
end

module StaticLookup = struct
  type 'm t = 'm Ast.Statement.StaticLookup.t

  let create (left : 'm Ast.LeftValue.t) (obj : 'm Ast.Expression.t)
      (prop : 'm Prop.t) : 'm t =
    { left; obj; prop }
  [@@inline]

  let create_stmt (left : 'm Ast.LeftValue.t) (obj : 'm Ast.Expression.t)
      (prop : 'm Prop.t) : 'm Ast.Statement.t' =
    `StaticLookup (create left obj prop)
  [@@inline]

  let pp (ppf : Fmt.t) (lookup : 'm t) : unit =
    Printer.pp_static_lookup ppf lookup
  [@@inline]

  let str (lookup : 'm t) : string = Fmt.str "%a" pp lookup [@@inline]
end

module DynamicLookup = struct
  type 'm t = 'm Ast.Statement.DynamicLookup.t

  let create (left : 'm Ast.LeftValue.t) (obj : 'm Ast.Expression.t)
      (prop : 'm Ast.Expression.t) : 'm t =
    { left; obj; prop }
  [@@inline]

  let create_stmt (left : 'm Ast.LeftValue.t) (obj : 'm Ast.Expression.t)
      (prop : 'm Ast.Expression.t) : 'm Ast.Statement.t' =
    `DynamicLookup (create left obj prop)
  [@@inline]

  let pp (ppf : Fmt.t) (lookup : 'm t) : unit =
    Printer.pp_dynamic_lookup ppf lookup
  [@@inline]

  let str (lookup : 'm t) : string = Fmt.str "%a" pp lookup [@@inline]
end

module StaticUpdate = struct
  type 'm t = 'm Ast.Statement.StaticUpdate.t

  let create (obj : 'm Ast.Expression.t) (prop : 'm Prop.t)
      (right : 'm Ast.Expression.t) : 'm t =
    { obj; prop; right }
  [@@inline]

  let create_stmt (obj : 'm Ast.Expression.t) (prop : 'm Prop.t)
      (right : 'm Ast.Expression.t) : 'm Ast.Statement.t' =
    `StaticUpdate (create obj prop right)
  [@@inline]

  let pp (ppf : Fmt.t) (update : 'm t) : unit =
    Printer.pp_static_update ppf update
  [@@inline]

  let str (update : 'm t) : string = Fmt.str "%a" pp update [@@inline]
end

module DynamicUpdate = struct
  type 'm t = 'm Ast.Statement.DynamicUpdate.t

  let create (obj : 'm Ast.Expression.t) (prop : 'm Ast.Expression.t)
      (right : 'm Ast.Expression.t) : 'm t =
    { obj; prop; right }
  [@@inline]

  let create_stmt (obj : 'm Ast.Expression.t) (prop : 'm Ast.Expression.t)
      (right : 'm Ast.Expression.t) : 'm Ast.Statement.t' =
    `DynamicUpdate (create obj prop right)
  [@@inline]

  let pp (ppf : Fmt.t) (update : 'm t) : unit =
    Printer.pp_dynamic_update ppf update
  [@@inline]

  let str (update : 'm t) : string = Fmt.str "%a" pp update [@@inline]
end

module StaticDelete = struct
  type 'm t = 'm Ast.Statement.StaticDelete.t

  let create (left : 'm Ast.LeftValue.t) (obj : 'm Ast.Expression.t)
      (prop : 'm Prop.t) : 'm t =
    { left; obj; prop }
  [@@inline]

  let create_stmt (left : 'm Ast.LeftValue.t) (obj : 'm Ast.Expression.t)
      (prop : 'm Prop.t) : 'm Ast.Statement.t' =
    `StaticDelete (create left obj prop)
  [@@inline]

  let pp (ppf : Fmt.t) (delete : 'm t) : unit =
    Printer.pp_static_delete ppf delete
  [@@inline]

  let str (delete : 'm t) : string = Fmt.str "%a" pp delete [@@inline]
end

module DynamicDelete = struct
  type 'm t = 'm Ast.Statement.DynamicDelete.t

  let create (left : 'm Ast.LeftValue.t) (obj : 'm Ast.Expression.t)
      (prop : 'm Ast.Expression.t) : 'm t =
    { left; obj; prop }
  [@@inline]

  let create_stmt (left : 'm Ast.LeftValue.t) (obj : 'm Ast.Expression.t)
      (prop : 'm Ast.Expression.t) : 'm Ast.Statement.t' =
    `DynamicDelete (create left obj prop)
  [@@inline]

  let pp (ppf : Fmt.t) (delete : 'm t) : unit =
    Printer.pp_dynamic_delete ppf delete
  [@@inline]

  let str (delete : 'm t) : string = Fmt.str "%a" pp delete [@@inline]
end

module AssignNewCall = struct
  type 'm t = 'm Ast.Statement.AssignNewCall.t

  let create (left : 'm Ast.LeftValue.t) (callee : 'm Ast.Identifier.t)
      (args : 'm Ast.Expression.t list) : 'm t =
    { left; callee; args }
  [@@inline]

  let create_stmt (left : 'm Ast.LeftValue.t) (callee : 'm Ast.Identifier.t)
      (args : 'm Ast.Expression.t list) : 'm Ast.Statement.t' =
    `AssignNewCall (create left callee args)
  [@@inline]

  let pp (ppf : Fmt.t) (newcall : 'm t) : unit =
    Printer.pp_assign_newcall ppf newcall
  [@@inline]

  let str (newcall : 'm t) : string = Fmt.str "%a" pp newcall [@@inline]
end

module AssignFunctionCall = struct
  type 'm t = 'm Ast.Statement.AssignFunctionCall.t

  let create (left : 'm Ast.LeftValue.t) (callee : 'm Ast.Identifier.t)
      (args : 'm Ast.Expression.t list) : 'm t =
    { left; callee; args }
  [@@inline]

  let create_stmt (left : 'm Ast.LeftValue.t) (callee : 'm Ast.Identifier.t)
      (args : 'm Ast.Expression.t list) : 'm Ast.Statement.t' =
    `AssignFunctionCall (create left callee args)
  [@@inline]

  let pp (ppf : Fmt.t) (funcall : 'm t) : unit =
    Printer.pp_assign_funcall ppf funcall
  [@@inline]

  let str (funcall : 'm t) : string = Fmt.str "%a" pp funcall [@@inline]
end

module AssignStaticMethodCall = struct
  type 'm t = 'm Ast.Statement.AssignStaticMethodCall.t

  let create (left : 'm Ast.LeftValue.t) (obj : 'm Ast.Expression.t)
      (prop : 'm Ast.Prop.t) (args : 'm Ast.Expression.t list) : 'm t =
    { left; obj; prop; args }
  [@@inline]

  let create_stmt (left : 'm Ast.LeftValue.t) (obj : 'm Ast.Expression.t)
      (prop : 'm Ast.Prop.t) (args : 'm Ast.Expression.t list) :
      'm Ast.Statement.t' =
    `AssignStaticMethodCall (create left obj prop args)
  [@@inline]

  let pp (ppf : Fmt.t) (methcall : 'm t) : unit =
    Printer.pp_assign_static_metcall ppf methcall
  [@@inline]

  let str (methcall : 'm t) : string = Fmt.str "%a" pp methcall [@@inline]
end

module AssignDynamicMethodCall = struct
  type 'm t = 'm Ast.Statement.AssignDynamicMethodCall.t

  let create (left : 'm Ast.LeftValue.t) (obj : 'm Ast.Expression.t)
      (prop : 'm Ast.Expression.t) (args : 'm Ast.Expression.t list) : 'm t =
    { left; obj; prop; args }
  [@@inline]

  let create_stmt (left : 'm Ast.LeftValue.t) (obj : 'm Ast.Expression.t)
      (prop : 'm Ast.Expression.t) (args : 'm Ast.Expression.t list) :
      'm Ast.Statement.t' =
    `AssignDynamicMethodCall (create left obj prop args)
  [@@inline]

  let pp (ppf : Fmt.t) (metcall : 'm t) : unit =
    Printer.pp_assign_dynamic_metcall ppf metcall
  [@@inline]

  let str (metcall : 'm t) : string = Fmt.str "%a" pp metcall [@@inline]
end

module AssignFunctionDefinition = struct
  type 'm t = 'm Ast.Statement.AssignFunctionDefinition.t

  let create (left : 'm Ast.LeftValue.t) (params : 'm Identifier.t list)
      (body : 'm Ast.Statement.t list) (async : bool) (generator : bool)
      (hoisted : bool) : 'm t =
    { left; params; body; async; generator; hoisted }
  [@@inline]

  let create_stmt (left : 'm Ast.LeftValue.t) (params : 'm Identifier.t list)
      (body : 'm Ast.Statement.t list) (async : bool) (generator : bool)
      (hoisted : bool) : 'm Ast.Statement.t' =
    `AssignFunctionDefinition (create left params body async generator hoisted)
  [@@inline]

  let pp (ppf : Fmt.t) (fundef : 'm t) : unit =
    Printer.pp_assign_fundef ppf fundef
  [@@inline]

  let str (fundef : 'm t) : string = Fmt.str "%a" pp fundef [@@inline]
end

module AssignDynamicImport = struct
  type 'm t = 'm Ast.Statement.AssignDynamicImport.t

  let create (left : 'm Ast.LeftValue.t) (arg : 'm Expression.t) : 'm t =
    { left; arg }
  [@@inline]

  let create_stmt (left : 'm Ast.LeftValue.t) (arg : 'm Expression.t) :
      'm Ast.Statement.t' =
    `AssignDynamicImport (create left arg)
  [@@inline]

  let pp (ppf : Fmt.t) (dimport : 'm t) : unit =
    Printer.pp_assign_dynamic_import ppf dimport
  [@@inline]

  let str (dimport : 'm t) : string = Fmt.str "%a" pp dimport [@@inline]
end

module If = struct
  type 'm t = 'm Ast.Statement.If.t

  let create (test : 'm Ast.Expression.t) (consequent : 'm Ast.Statement.t list)
      (alternate : 'm Ast.Statement.t list option) : 'm t =
    { test; consequent; alternate }
  [@@inline]

  let create_stmt (test : 'm Ast.Expression.t)
      (consequent : 'm Ast.Statement.t list)
      (alternate : 'm Ast.Statement.t list option) : 'm Ast.Statement.t' =
    `If (create test consequent alternate)
  [@@inline]

  let pp (ppf : Fmt.t) (if' : 'm t) : unit = Printer.pp_if ppf if' [@@inline]
  let str (if' : 'm t) : string = Fmt.str "%a" pp if' [@@inline]
end

module SwitchCase = struct
  type 'm t' = 'm Ast.Statement.Switch.Case.t'
  type 'm t = 'm Ast.Statement.Switch.Case.t

  let create (test : 'm Ast.Expression.t option) (body : 'm Ast.Statement.t list)
      : 'm t' =
    { test; body }
  [@@inline]

  let pp (ppf : Fmt.t) (case : 'm t) : unit = Printer.pp_switch_case ppf case
  [@@inline]

  let str (case : 'm t) : string = Fmt.str "%a" pp case [@@inline]
  let test (case : 'm t) : 'm Ast.Expression.t option = case.el.test [@@inline]
  let body (case : 'm t) : 'm Ast.Statement.t list = case.el.body [@@inline]
end

module Switch = struct
  type 'm t = 'm Ast.Statement.Switch.t

  let create (discriminant : 'm Ast.Expression.t)
      (cases : 'm Ast.Statement.Switch.Case.t list) : 'm t =
    { discriminant; cases }
  [@@inline]

  let create_stmt (discriminant : 'm Ast.Expression.t)
      (cases : 'm Ast.Statement.Switch.Case.t list) : 'm Ast.Statement.t' =
    `Switch (create discriminant cases)
  [@@inline]

  let pp (ppf : Fmt.t) (switch : 'm t) : unit = Printer.pp_switch ppf switch
  [@@inline]

  let str (switch : 'm t) : string = Fmt.str "%a" pp switch [@@inline]
end

module While = struct
  type 'm t = 'm Ast.Statement.While.t

  let create (test : 'm Ast.Expression.t) (body : 'm Ast.Statement.t list) :
      'm t =
    { test; body }
  [@@inline]

  let create_stmt (test : 'm Ast.Expression.t) (body : 'm Ast.Statement.t list)
      : 'm Ast.Statement.t' =
    `While (create test body)
  [@@inline]

  let pp (ppf : Fmt.t) (while' : 'm t) : unit = Printer.pp_while ppf while'
  [@@inline]

  let str (while' : 'm t) : string = Fmt.str "%a" pp while' [@@inline]
end

module ForIn = struct
  type 'm t = 'm Ast.Statement.ForIn.t

  let create (left : 'm Ast.LeftValue.t) (right : 'm Ast.Expression.t)
      (body : 'm Ast.Statement.t list) : 'm t =
    { left; right; body }
  [@@inline]

  let create_stmt (left : 'm Ast.LeftValue.t) (right : 'm Ast.Expression.t)
      (body : 'm Ast.Statement.t list) : 'm Ast.Statement.t' =
    `ForIn (create left right body)
  [@@inline]

  let pp (ppf : Fmt.t) (forin : 'm t) : unit = Printer.pp_forin ppf forin
  [@@inline]

  let str (forin : 'm t) : string = Fmt.str "%a" pp forin [@@inline]
end

module ForOf = struct
  type 'm t = 'm Ast.Statement.ForOf.t

  let create (left : 'm Ast.LeftValue.t) (right : 'm Ast.Expression.t)
      (body : 'm Ast.Statement.t list) (await : bool) : 'm t =
    { left; right; body; await }
  [@@inline]

  let create_stmt (left : 'm Ast.LeftValue.t) (right : 'm Ast.Expression.t)
      (body : 'm Ast.Statement.t list) (await : bool) : 'm Ast.Statement.t' =
    `ForOf (create left right body await)
  [@@inline]

  let pp (ppf : Fmt.t) (forof : 'm t) : unit = Printer.pp_forof ppf forof
  [@@inline]

  let str (forof : 'm t) : string = Fmt.str "%a" pp forof [@@inline]
end

module Break = struct
  type 'm t = 'm Ast.Statement.Break.t

  let create (label : 'm Ast.Identifier.t option) : 'm t = { label } [@@inline]

  let create_stmt (label : 'm Ast.Identifier.t option) : 'm Ast.Statement.t' =
    `Break (create label)
  [@@inline]

  let pp (ppf : Fmt.t) (break : 'm t) : unit = Printer.pp_break ppf break
  [@@inline]

  let str (break : 'm t) : string = Fmt.str "%a" pp break [@@inline]
end

module Continue = struct
  type 'm t = 'm Ast.Statement.Continue.t

  let create (label : 'm Ast.Identifier.t option) : 'm t = { label } [@@inline]

  let create_stmt (label : 'm Ast.Identifier.t option) : 'm Ast.Statement.t' =
    `Continue (create label)
  [@@inline]

  let pp (ppf : Fmt.t) (continue : 'm t) : unit =
    Printer.pp_continue ppf continue
  [@@inline]

  let str (continue : 'm t) : string = Fmt.str "%a" pp continue [@@inline]
end

module Return = struct
  type 'm t = 'm Ast.Statement.Return.t

  let create (arg : 'm Ast.Expression.t option) : 'm t = { arg } [@@inline]

  let create_stmt (arg : 'm Ast.Expression.t option) : 'm Ast.Statement.t' =
    `Return (create arg)
  [@@inline]

  let pp (ppf : Fmt.t) (return : 'm t) : unit = Printer.pp_return ppf return
  [@@inline]

  let str (return : 'm t) : string = Fmt.str "%a" pp return [@@inline]
end

module Throw = struct
  type 'm t = 'm Ast.Statement.Throw.t

  let create (arg : 'm Ast.Expression.t) : 'm t = { arg } [@@inline]

  let create_stmt (arg : 'm Ast.Expression.t) : 'm Ast.Statement.t' =
    `Throw (create arg)
  [@@inline]

  let pp (ppf : Fmt.t) (throw : 'm t) : unit = Printer.pp_throw ppf throw
  [@@inline]

  let str (throw : 'm t) : string = Fmt.str "%a" pp throw [@@inline]
end

module Catch = struct
  type 'm t' = 'm Ast.Statement.Try.Catch.t'
  type 'm t = 'm Ast.Statement.Try.Catch.t

  let create (param : 'm Ast.Identifier.t option)
      (body : 'm Ast.Statement.t list) : 'm t' =
    { param; body }
  [@@inline]

  let pp (ppf : Fmt.t) (catch : 'm t) : unit = Printer.pp_catch ppf catch
  [@@inline]

  let str (catch : 'm t) : string = Fmt.str "%a" pp catch [@@inline]

  let param (catch : 'm t) : 'm Ast.Identifier.t option = catch.el.param
  [@@inline]

  let body (catch : 'm t) : 'm Ast.Statement.t list = catch.el.body [@@inline]
end

module Try = struct
  type 'm t = 'm Ast.Statement.Try.t

  let create (body : 'm Ast.Statement.t list) (handler : 'm Catch.t option)
      (finalizer : 'm Ast.Statement.t list option) : 'm t =
    { body; handler; finalizer }
  [@@inline]

  let create_stmt (body : 'm Ast.Statement.t list) (handler : 'm Catch.t option)
      (finalizer : 'm Ast.Statement.t list option) : 'm Ast.Statement.t' =
    `Try (create body handler finalizer)
  [@@inline]

  let pp (ppf : Fmt.t) (try' : 'm t) : unit = Printer.pp_try ppf try' [@@inline]
  let str (try' : 'm t) : string = Fmt.str "%a" pp try' [@@inline]
end

module With = struct
  type 'm t = 'm Ast.Statement.With.t

  let create (expr : 'm Ast.Expression.t) (body : 'm Ast.Statement.t list) :
      'm t =
    { expr; body }
  [@@inline]

  let create_stmt (expr : 'm Ast.Expression.t) (body : 'm Ast.Statement.t list)
      : 'm Ast.Statement.t' =
    `With (create expr body)
  [@@inline]

  let pp (ppf : Fmt.t) (with' : 'm t) : unit = Printer.pp_with ppf with'
  [@@inline]

  let str (with' : 'm t) : string = Fmt.str "%a" pp with' [@@inline]
end

module Labeled = struct
  type 'm t = 'm Ast.Statement.Labeled.t

  let create (label : 'm Ast.Identifier.t) (body : 'm Ast.Statement.t list) :
      'm t =
    { label; body }
  [@@inline]

  let create_stmt (label : 'm Ast.Identifier.t) (body : 'm Ast.Statement.t list)
      : 'm Ast.Statement.t' =
    `Labeled (create label body)
  [@@inline]

  let pp (ppf : Fmt.t) (labeled : 'm t) : unit = Printer.pp_labeled ppf labeled
  [@@inline]

  let str (labeled : 'm t) : string = Fmt.str "%a" pp labeled [@@inline]
end

module Debugger = struct
  type t = Ast.Statement.Debugger.t

  let create () : t = () [@@inline]
  let create_stmt () : 'm Ast.Statement.t' = `Debugger (create ()) [@@inline]

  let pp (ppf : Fmt.t) (debugger : t) : unit = Printer.pp_debugger ppf debugger
  [@@inline]

  let str (debugger : t) : string = Fmt.str "%a" pp debugger [@@inline]
end

module ImportDecl = struct
  type 'm t = 'm Ast.Statement.ImportDecl.t

  let create (specifier : 'm Ast.Statement.ImportDecl.Specifier.t)
      (source : string) : 'm t =
    { specifier; source }
  [@@inline]

  let create_stmt (specifier : 'm Ast.Statement.ImportDecl.Specifier.t)
      (source : string) : 'm Ast.Statement.t' =
    `ImportDecl (create specifier source)
  [@@inline]

  let pp (ppf : Fmt.t) (import : 'm t) : unit = Printer.pp_import ppf import
  [@@inline]

  let str (import : 'm t) : string = Fmt.str "%a" pp import [@@inline]
end

module ExportDecl = struct
  type 'm t = 'm Ast.Statement.ExportDecl.t

  let create (specifier : 'm Ast.Statement.ExportDecl.Specifier.t)
      (source : string option) : 'm t =
    { specifier; source }
  [@@inline]

  let create_stmt (specifier : 'm Ast.Statement.ExportDecl.Specifier.t)
      (source : string option) : 'm Ast.Statement.t' =
    `ExportDecl (create specifier source)
  [@@inline]

  let pp (ppf : Fmt.t) (export : 'm t) : unit = Printer.pp_export ppf export
  [@@inline]

  let str (export : 'm t) : string = Fmt.str "%a" pp export [@@inline]
end

module Statement = struct
  type 'm t' = 'm Ast.Statement.t'
  type 'm t = 'm Ast.Statement.t

  let pp (ppf : Fmt.t) (stmt : 'm t) : unit = Printer.pp_stmt ppf stmt
  [@@inline]

  let str (stmt : 'm t) : string = Fmt.str "%a" pp stmt [@@inline]
end

module Unopt = struct
  include Ast.Operator.Unary

  let pp (ppf : Fmt.t) (unopt : t) : unit = Printer.pp_unopt ppf unopt
  [@@inline]

  let str (unopt : t) : string = Fmt.str "%a" pp unopt [@@inline]
end

module Binopt = struct
  include Ast.Operator.Binary

  let pp (ppf : Fmt.t) (binopt : t) : unit = Printer.pp_binopt ppf binopt
  [@@inline]

  let str (binopt : t) : string = Fmt.str "%a" pp binopt [@@inline]
end

module File = struct
  type 'm t = 'm Ast.File.t

  let pp (ppf : Fmt.t) (file : 'm t) : unit = Printer.pp_file ppf file
  [@@inline]

  let str (file : 'm t) : string = Fmt.str "%a" pp file [@@inline]
end

module Prog = struct
  type 'm t = 'm Ast.Prog.t

  let create (files : (string * 'm File.t) list) : 'm t =
    files |> List.to_seq |> Hashtbl.of_seq
  [@@inline]

  let find (prog : 'm t) (path : string) : 'm Ast.File.t =
    Hashtbl.find prog path
  [@@inline]

  let add (prog : 'm t) (path : string) (file : 'm Ast.File.t) : unit =
    Hashtbl.add prog path file
  [@@inline]

  let pp ?(filename : bool = false) (ppf : Fmt.t) (prog : 'm t) : unit =
    Printer.pp_prog ~filename ppf prog
  [@@inline]

  let str ?(filename : bool = false) (prog : 'm t) : string =
    Fmt.str "%a" (pp ~filename) prog
  [@@inline]
end
