open Graphjs_base
open Ast

module Config = struct
  include Config

  let path_font : Font.t t =
    constant (Font.create ~fg:`DarkGray ~italic:true ())

  let test262_conform_hoisted : bool t = static false
end

let pp_indent (pp_v : Fmt.t -> 'a -> unit) (ppf : Fmt.t) (vs : 'a list) : unit =
  Fmt.fmt ppf "@\n@[<v 2>  %a@]" Fmt.(pp_lst !>"@\n" pp_v) vs

let pp_block (pp_v : Fmt.t -> 'a -> unit) (ppf : Fmt.t) (vs : 'a list) : unit =
  Fmt.fmt ppf "{%a@\n}" (pp_indent pp_v) vs

let rec pp_identifier (ppf : Fmt.t) (id : 'm Identifier.t) : unit =
  pp_identifier' ppf id.el

and pp_identifier' (ppf : Fmt.t) (id : Identifier.t') : unit =
  Fmt.pp_str ppf id.name

and pp_leftvalue (ppf : Fmt.t) (lval : 'm LeftValue.t) : unit =
  pp_leftvalue' ppf lval.el

and pp_leftvalue' (ppf : Fmt.t) (lval : LeftValue.t') : unit =
  match lval.kind with
  | None -> Fmt.fmt ppf "%a" pp_identifier' lval.id
  | _ -> Fmt.fmt ppf "%a %a" pp_leftvalue_kind lval.kind pp_identifier' lval.id

and pp_leftvalue_kind (ppf : Fmt.t) : LeftValue.Kind.t -> unit = function
  | Var -> Fmt.pp_str ppf "var"
  | Let -> Fmt.pp_str ppf "let"
  | Const -> Fmt.pp_str ppf "const"
  | None -> ()

and pp_prop (ppf : Fmt.t) (prop : 'm Prop.t) : unit =
  match prop.el with
  | IProp id -> pp_identifier' ppf id
  | LProp lit -> pp_literal ppf lit

and pp_prop_access (ppf : Fmt.t) (prop : 'm Prop.t) : unit =
  match prop.el with
  | IProp id -> Fmt.fmt ppf ".%a" pp_identifier' id
  | LProp lit -> Fmt.fmt ppf "[%a]" pp_literal lit

and pp_literal (ppf : Fmt.t) (literal : Expression.Literal.t) : unit =
  Fmt.pp_str ppf literal.raw

and pp_regex (ppf : Fmt.t) (regex : Expression.Literal.Regex.t) : unit =
  Fmt.fmt ppf "/%s/%s" regex.pattern regex.flags

and pp_template_literal (ppf : Fmt.t)
    (tliteral : 'm Expression.TemplateLiteral.t) : unit =
  let exprs = List.map Option.some tliteral.exprs @ [ None ] in
  let quasi_exprs = List.combine tliteral.quasis exprs in
  let pp_quasi ppf = pp_template_element ppf in
  let pp_expr ppf = Fmt.fmt ppf "${%a}" pp_expr in
  let pp_quasi_expr ppf (quasi, expr) =
    Fmt.fmt ppf "%a%a" pp_quasi quasi (Fmt.pp_opt pp_expr) expr in
  Fmt.fmt ppf "`%a`" Fmt.(pp_lst !>"" pp_quasi_expr) quasi_exprs

and pp_template_element (ppf : Fmt.t)
    (telement : 'm Expression.TemplateLiteral.Element.t) : unit =
  Fmt.fmt ppf "%a" pp_template_value telement.el.value

and pp_template_value (ppf : Fmt.t)
    (tvalue : Expression.TemplateLiteral.Element.Value.t) : unit =
  Fmt.pp_str ppf tvalue.raw

and pp_this (ppf : Fmt.t) () : unit = Fmt.pp_str ppf "this"

and pp_expr' (ppf : Fmt.t) : 'm Expression.t' -> unit = function
  | `Literal literal -> pp_literal ppf literal
  | `TemplateLiteral tliteral -> pp_template_literal ppf tliteral
  | `Identifier id -> pp_identifier' ppf id
  | `This () -> pp_this ppf ()

and pp_expr (ppf : Fmt.t) (expr : 'm Expression.t) : unit = pp_expr' ppf expr.el

and pp_expr_stmt (ppf : Fmt.t) (expr : 'm Expression.t') : unit =
  Fmt.fmt ppf "%a;" pp_expr' expr

and pp_vdecl (ppf : Fmt.t) (vdecl : LeftValue.t') : unit =
  Fmt.fmt ppf "%a;" pp_leftvalue' vdecl

and pp_assign (ppf : Fmt.t) (assign : 'm Statement.AssignSimple.t) : unit =
  Fmt.fmt ppf "%a = %a;" pp_leftvalue assign.left pp_expr assign.right

and pp_newobj (ppf : Fmt.t) (obj : 'm Statement.AssignNewObject.t) : unit =
  Fmt.fmt ppf "%a = {};" pp_leftvalue obj.left

and pp_newarray (ppf : Fmt.t) (arr : 'm Statement.AssignNewArray.t) : unit =
  Fmt.fmt ppf "%a = [];" pp_leftvalue arr.left

and pp_unopt (ppf : Fmt.t) (unopt : 'm Statement.AssignUnopt.t) : unit =
  let pp_space ppf () =
    match unopt.op with
    | Plus | Minus | BitwiseNot | LogicalNot -> ()
    | Typeof | Void | Await | Delete -> Fmt.pp_str ppf " " in
  Fmt.fmt ppf "%a = %a%a%a;" pp_leftvalue unopt.left pp_unopt_op unopt.op
    pp_space () pp_expr unopt.arg

and pp_binopt (ppf : Fmt.t) (binopt : 'm Statement.AssignBinopt.t) : unit =
  Fmt.fmt ppf "%a = %a %a %a;" pp_leftvalue binopt.left pp_expr binopt.arg1
    pp_binopt_op binopt.op pp_expr binopt.arg2

and pp_yield (ppf : Fmt.t) (yield : 'm Statement.AssignYield.t) : unit =
  let pp_delegate ppf delegate = if delegate then Fmt.pp_str ppf "*" else () in
  let pp_arg ppf = Fmt.fmt ppf " %a" pp_expr in
  Fmt.fmt ppf "%a = yield%a%a;" pp_leftvalue yield.left pp_delegate
    yield.delegate (Fmt.pp_opt pp_arg) yield.arg

and pp_slookup (ppf : Fmt.t) (lookup : 'm Statement.StaticLookup.t) : unit =
  Fmt.fmt ppf "%a = %a%a;" pp_leftvalue lookup.left pp_expr lookup.obj
    pp_prop_access lookup.prop

and pp_dlookup (ppf : Fmt.t) (lookup : 'm Statement.DynamicLookup.t) : unit =
  Fmt.fmt ppf "%a = %a[%a];" pp_leftvalue lookup.left pp_expr lookup.obj pp_expr
    lookup.prop

and pp_supdate (ppf : Fmt.t) (update : 'm Statement.StaticUpdate.t) : unit =
  Fmt.fmt ppf "%a%a = %a;" pp_expr update.obj pp_prop_access update.prop pp_expr
    update.right

and pp_dupdate (ppf : Fmt.t) (update : 'm Statement.DynamicUpdate.t) : unit =
  Fmt.fmt ppf "%a[%a] = %a;" pp_expr update.obj pp_expr update.prop pp_expr
    update.right

and pp_sdelete (ppf : Fmt.t) (delete : 'm Statement.StaticDelete.t) : unit =
  Fmt.fmt ppf "%a = delete %a%a;" pp_leftvalue delete.left pp_expr delete.obj
    pp_prop_access delete.prop

and pp_ddelete (ppf : Fmt.t) (delete : 'm Statement.DynamicDelete.t) : unit =
  Fmt.fmt ppf "%a = delete %a[%a];" pp_leftvalue delete.left pp_expr delete.obj
    pp_expr delete.prop

and pp_newcall (ppf : Fmt.t) (newcall : 'm Statement.AssignNewCall.t) : unit =
  let pp_args = Fmt.(pp_lst !>", " pp_expr) in
  Fmt.fmt ppf "%a = new %a(%a);" pp_leftvalue newcall.left pp_identifier
    newcall.callee pp_args newcall.args

and pp_funcall (ppf : Fmt.t) (funcall : 'm Statement.AssignFunctionCall.t) :
    unit =
  let pp_args = Fmt.(pp_lst !>", " pp_expr) in
  Fmt.fmt ppf "%a = %a(%a);" pp_leftvalue funcall.left pp_identifier
    funcall.callee pp_args funcall.args

and pp_smetcall (ppf : Fmt.t) (metcall : 'm Statement.AssignStaticMethodCall.t)
    : unit =
  let pp_args = Fmt.(pp_lst !>", " pp_expr) in
  Fmt.fmt ppf "%a = %a%a(%a);" pp_leftvalue metcall.left pp_expr metcall.obj
    pp_prop_access metcall.prop pp_args metcall.args

and pp_dmetcall (ppf : Fmt.t) (metcall : 'm Statement.AssignDynamicMethodCall.t)
    : unit =
  let pp_args = Fmt.(pp_lst !>", " pp_expr) in
  Fmt.fmt ppf "%a = %a[%a](%a);" pp_leftvalue metcall.left pp_expr metcall.obj
    pp_expr metcall.prop pp_args metcall.args

and pp_fundef (ppf : Fmt.t) (fundef : 'm Statement.AssignFunctionDefinition.t) :
    unit =
  let pp_params = Fmt.(pp_lst !>", " pp_identifier) in
  Fmt.fmt ppf "%a(%a) %a" pp_fundef_header fundef pp_params fundef.params
    pp_body fundef.body

and pp_fundef_header (ppf : Fmt.t)
    (fundef : 'm Statement.AssignFunctionDefinition.t) : unit =
  let pp_async ppf async = if async then Fmt.pp_str ppf "async " else () in
  let pp_generator ppf gen = if gen then Fmt.pp_str ppf "*" else () in
  if Config.(!test262_conform_hoisted) && fundef.hoisted then
    Fmt.fmt ppf "%afunction%a %a" pp_async fundef.async pp_generator
      fundef.generator pp_identifier' fundef.left.el.id
  else
    Fmt.fmt ppf "%a = %afunction%a " pp_leftvalue fundef.left pp_async
      fundef.async pp_generator fundef.generator

and pp_dimport (ppf : Fmt.t) (import : 'm Statement.AssignDynamicImport.t) :
    unit =
  Fmt.fmt ppf "%a = import(%a);" pp_leftvalue import.left pp_expr import.arg

and pp_if (ppf : Fmt.t) (if' : 'm Statement.If.t) : unit =
  let pp_else ppf = Fmt.fmt ppf " else %a" pp_body in
  Fmt.fmt ppf "if (%a) %a%a" pp_expr if'.test pp_body if'.consequent
    (Fmt.pp_opt pp_else) if'.alternate

and pp_switch (ppf : Fmt.t) (switch : 'm Statement.Switch.t) : unit =
  Fmt.fmt ppf "switch (%a) %a" pp_expr switch.discriminant
    (pp_block pp_switch_case) switch.cases

and pp_switch_case (ppf : Fmt.t) (case : 'm Statement.Switch.Case.t) : unit =
  let pp_test ppf = function
    | None -> Fmt.pp_str ppf "default"
    | Some test -> Fmt.fmt ppf "case %a" pp_expr test in
  Fmt.fmt ppf "%a:%a" pp_test case.el.test (pp_indent pp_stmt) case.el.body

and pp_while (ppf : Fmt.t) (while' : 'm Statement.While.t) : unit =
  Fmt.fmt ppf "while (%a) %a" pp_expr while'.test pp_body while'.body

and pp_forin (ppf : Fmt.t) (forin : 'm Statement.ForIn.t) : unit =
  Fmt.fmt ppf "for (%a in %a) %a" pp_leftvalue forin.left pp_expr forin.right
    pp_body forin.body

and pp_forof (ppf : Fmt.t) (forof : 'm Statement.ForOf.t) : unit =
  let pp_await ppf await = if await then Fmt.pp_str ppf "await " in
  Fmt.fmt ppf "for %a(%a of %a) %a" pp_await forof.await pp_leftvalue forof.left
    pp_expr forof.right pp_body forof.body

and pp_break (ppf : Fmt.t) (break : 'm Statement.Break.t) : unit =
  let pp_label ppf = Fmt.fmt ppf " %a" pp_identifier in
  Fmt.fmt ppf "break%a;" (Fmt.pp_opt pp_label) break.label

and pp_continue (ppf : Fmt.t) (continue : 'm Statement.Continue.t) : unit =
  let pp_label ppf = Fmt.fmt ppf " %a" pp_identifier in
  Fmt.fmt ppf "continue%a;" (Fmt.pp_opt pp_label) continue.label

and pp_return (ppf : Fmt.t) (return : 'm Statement.Return.t) : unit =
  let pp_arg ppf = Fmt.fmt ppf " %a" pp_expr in
  Fmt.fmt ppf "return%a;" (Fmt.pp_opt pp_arg) return.arg

and pp_throw (ppf : Fmt.t) (throw : 'm Statement.Throw.t) : unit =
  Fmt.fmt ppf "throw %a;" pp_expr throw.arg

and pp_try (ppf : Fmt.t) (try' : 'm Statement.Try.t) : unit =
  let pp_handler ppf = Fmt.fmt ppf " %a" pp_catch in
  let pp_finalizer ppf = Fmt.fmt ppf " finally %a" pp_body in
  Fmt.fmt ppf "try %a%a%a" pp_body try'.body (Fmt.pp_opt pp_handler)
    try'.handler (Fmt.pp_opt pp_finalizer) try'.finalizer

and pp_catch (ppf : Fmt.t) (catch : 'm Statement.Try.Catch.t) : unit =
  let pp_param ppf = Fmt.fmt ppf " (%a)" pp_identifier in
  Fmt.fmt ppf "catch%a %a" (Fmt.pp_opt pp_param) catch.el.param pp_body
    catch.el.body

and pp_with (ppf : Fmt.t) (with' : 'm Statement.With.t) : unit =
  Fmt.fmt ppf "with (%a) %a" pp_expr with'.expr pp_body with'.body

and pp_labeled (ppf : Fmt.t) (labeled : 'm Statement.Labeled.t) : unit =
  Fmt.fmt ppf "%a: %a" pp_identifier labeled.label
    Fmt.(pp_lst !>"@\n" pp_stmt)
    labeled.body

and pp_debugger (ppf : Fmt.t) (() : unit) : unit = Fmt.fmt ppf "debugger;"

and pp_import (ppf : Fmt.t) (import : 'm Statement.ImportDecl.t) : unit =
  Fmt.fmt ppf "import %a%S;" pp_import_spec import.specifier import.source

and pp_import_spec (ppf : Fmt.t) : 'm Statement.ImportDecl.Specifier.t -> unit =
  function
  | None -> ()
  | Default id -> Fmt.fmt ppf "%a from " pp_identifier id
  | Property prop -> Fmt.fmt ppf "{ %a } from " pp_identifier prop
  | Batch namespace -> Fmt.fmt ppf "* as %a from " pp_identifier namespace
  | Alias (prop, alias) ->
    Fmt.fmt ppf "{ %a as %a } from " pp_identifier prop pp_identifier alias

and pp_export (ppf : Fmt.t) (export : 'm Statement.ExportDecl.t) : unit =
  let pp_source ppf = Fmt.fmt ppf " from %S" in
  Fmt.fmt ppf "export %a%a;" pp_export_spec export.specifier
    (Fmt.pp_opt pp_source) export.source

and pp_export_spec (ppf : Fmt.t) : 'm Statement.ExportDecl.Specifier.t -> unit =
  function
  | Default decl -> Fmt.fmt ppf "default %a" pp_expr decl
  | Property prop -> Fmt.fmt ppf "{ %a }" pp_identifier prop
  | Batch namespace ->
    let pp_batch ppf namespace = Fmt.fmt ppf " as %a" pp_identifier namespace in
    Fmt.fmt ppf "*%a" (Fmt.pp_opt pp_batch) namespace
  | Alias (id, alias) ->
    Fmt.fmt ppf "{ %a as %a }" pp_identifier id pp_identifier alias

and pp_stmt (ppf : Fmt.t) (stmt : 'm Statement.t) : unit =
  match stmt.el with
  | `ExprStmt expr -> pp_expr_stmt ppf expr
  | `VarDecl vdecl -> pp_vdecl ppf vdecl
  | `AssignSimple assign -> pp_assign ppf assign
  | `AssignNewObject obj -> pp_newobj ppf obj
  | `AssignNewArray arr -> pp_newarray ppf arr
  | `AssignUnopt unopt -> pp_unopt ppf unopt
  | `AssignBinopt binopt -> pp_binopt ppf binopt
  | `AssignYield yield -> pp_yield ppf yield
  | `StaticLookup lookup -> pp_slookup ppf lookup
  | `DynamicLookup lookup -> pp_dlookup ppf lookup
  | `StaticUpdate update -> pp_supdate ppf update
  | `DynamicUpdate update -> pp_dupdate ppf update
  | `StaticDelete delete -> pp_sdelete ppf delete
  | `DynamicDelete delete -> pp_ddelete ppf delete
  | `AssignNewCall newcall -> pp_newcall ppf newcall
  | `AssignFunctionCall funcall -> pp_funcall ppf funcall
  | `AssignStaticMethodCall metcall -> pp_smetcall ppf metcall
  | `AssignDynamicMethodCall metcall -> pp_dmetcall ppf metcall
  | `AssignFunctionDefinition fundef -> pp_fundef ppf fundef
  | `AssignDynamicImport import -> pp_dimport ppf import
  | `If if' -> pp_if ppf if'
  | `Switch switch -> pp_switch ppf switch
  | `While while' -> pp_while ppf while'
  | `ForIn forin -> pp_forin ppf forin
  | `ForOf forof -> pp_forof ppf forof
  | `Break break -> pp_break ppf break
  | `Continue continue -> pp_continue ppf continue
  | `Return return -> pp_return ppf return
  | `Throw throw -> pp_throw ppf throw
  | `Try try' -> pp_try ppf try'
  | `With with' -> pp_with ppf with'
  | `Labeled labeled -> pp_labeled ppf labeled
  | `Debugger debugger -> pp_debugger ppf debugger
  | `ImportDecl import -> pp_import ppf import
  | `ExportDecl export -> pp_export ppf export

and pp_body (ppf : Fmt.t) (stmts : 'm Statement.t list) : unit =
  pp_block pp_stmt ppf stmts

and pp_unopt_op (ppf : Fmt.t) : Operator.Unary.t -> unit = function
  | Plus -> Fmt.pp_str ppf "+"
  | Minus -> Fmt.pp_str ppf "-"
  | BitwiseNot -> Fmt.pp_str ppf "~"
  | LogicalNot -> Fmt.pp_str ppf "!"
  | Typeof -> Fmt.pp_str ppf "typeof"
  | Void -> Fmt.pp_str ppf "void"
  | Await -> Fmt.pp_str ppf "await"
  | Delete -> Fmt.pp_str ppf "delete"

and pp_binopt_op (ppf : Fmt.t) : Operator.Binary.t -> unit = function
  | Plus -> Fmt.pp_str ppf "+"
  | Minus -> Fmt.pp_str ppf "-"
  | Mult -> Fmt.pp_str ppf "*"
  | Div -> Fmt.pp_str ppf "/"
  | Mod -> Fmt.pp_str ppf "%"
  | Exp -> Fmt.pp_str ppf "**"
  | BitwiseAnd -> Fmt.pp_str ppf "&"
  | BitwiseOr -> Fmt.pp_str ppf "|"
  | BitwiseXor -> Fmt.pp_str ppf "^"
  | ShiftLeft -> Fmt.pp_str ppf "<<"
  | ShiftRight -> Fmt.pp_str ppf ">>"
  | ShiftRightLogical -> Fmt.pp_str ppf ">>>"
  | LogicalAnd -> Fmt.pp_str ppf "&&"
  | LogicalOr -> Fmt.pp_str ppf "||"
  | NullishCoalesce -> Fmt.pp_str ppf "??"
  | Equal -> Fmt.pp_str ppf "=="
  | NotEqual -> Fmt.pp_str ppf "!="
  | StrictEqual -> Fmt.pp_str ppf "==="
  | StrictNotEqual -> Fmt.pp_str ppf "!=="
  | LessThan -> Fmt.pp_str ppf "<"
  | LessThanEqual -> Fmt.pp_str ppf "<="
  | GreaterThan -> Fmt.pp_str ppf ">"
  | GreaterThanEqual -> Fmt.pp_str ppf ">="
  | Instanceof -> Fmt.pp_str ppf "instanceof"
  | In -> Fmt.pp_str ppf "in"

let pp_file (ppf : Fmt.t) (file : 'm Ast.File.t) =
  Fmt.fmt ppf "%a" Fmt.(pp_lst !>"@\n" pp_stmt) file

let pp_prog_file ?(filename : bool = false) (ppf : Fmt.t)
    ((path, file) : Fpath.t * 'm Ast.File.t) =
  let pp_path ppf path =
    Font.fmt Config.(!path_font) ppf "File \"%a\"@\n" Fpath.pp path in
  let pp_path' = if filename then pp_path else Fmt.pp_none in
  Fmt.fmt ppf "%a%a" pp_path' path pp_file file

let pp_prog ?(filename : bool = false) (ppf : Fmt.t) (prog : 'm Ast.Prog.t) :
    unit =
  Fmt.(pp_htbl !>"@\n@\n" (pp_prog_file ~filename)) ppf prog
