open Grammar

module Const = struct
  let indent_sz = 2
end

let inc_indent (indent : int) : int = indent + Const.indent_sz [@@inline]

let pp_indent (ppf : Format.formatter) (indent : int) : unit =
  Format.pp_print_string ppf (String.make indent ' ')
[@@inline]

let rec pp_expr (ppf : Format.formatter) (expr : m Expression.t) : unit =
  match expr with
  | (_, Literal { raw; _ }) -> Format.pp_print_string ppf raw
  | (_, Identifier { name; _ }) -> Format.pp_print_string ppf name
  | (_, This _) -> Format.pp_print_string ppf "this"
  | (_, TemplateLiteral { quasis; exprs }) ->
    pp_template_literal ppf quasis exprs
(*| _, TaggedTemplate {tag; quasi} ->
  let tag' = print_expr tag in
  let quasi' = print_expr (Location.empty, Expression.TemplateLiteral quasi) in
  tag' ^ quasi'*)
(*| _, MetaProperty {meta; property} ->
  let meta' = print_identifier meta) in
  let property' = print_identifier property) in
  meta' ^ "." ^ property'*)

and pp_template_literal (ppf : Format.formatter)
    (quasis : m Expression.TemplateLiteral.Element.t list)
    (exprs : m Expression.t list) : unit =
  let open Expression.TemplateLiteral.Element in
  let pp_sep _ () = () in
  let expr_pp e = Format.dprintf "${%a}" pp_expr e in
  let quasi_pp (_, { value = { raw; _ }; _ }) = Format.dprintf "%s" raw in
  let quasis_mappers = List.map quasi_pp quasis in
  let expr_mappers = List.map expr_pp exprs @ [ (fun _ -> ()) ] in
  let template_mappers = List.combine quasis_mappers expr_mappers in
  let template_pp ppf (q_mapper, e_mapper) =
    Format.fprintf ppf "%t%t" q_mapper e_mapper in
  Format.fprintf ppf "`%a`"
    (Format.pp_print_list ~pp_sep template_pp)
    template_mappers

let pp_identifier (ppf : Format.formatter) (id : m Identifier.t) : unit =
  Format.fprintf ppf "%a" pp_expr (Identifier.to_expr id)
[@@inline]

let pp_kind (ppf : Format.formatter) : Statement.VarDecl.kind -> unit = function
  | Var -> Format.pp_print_string ppf "var"
  | Let -> Format.pp_print_string ppf "let"
  | Const -> Format.pp_print_string ppf "const"

let pp_decl (ppf : Format.formatter) ({ kind; id } : m Statement.VarDecl.t) =
  Format.fprintf ppf "%a %a" pp_kind kind pp_identifier id

let rec pp_stmt ~(indent : int) (ppf : Format.formatter) (stmt : m Statement.t)
    : unit =
  match stmt with
  | (_, If { test; consequent; alternate }) ->
    pp_if ~indent ppf test consequent alternate
  | (_, Switch { discriminant; cases }) ->
    pp_switch ~indent ppf discriminant cases
  | (_, While { test; body }) -> pp_while ~indent ppf test body
  | (_, ForIn { left; right; body; _ }) -> pp_forin ~indent ppf left right body
  | (_, ForOf { left; right; body; await }) ->
    pp_forof ~indent ppf left right body await
  | (_, Try { body; finalizer; handler }) ->
    pp_try ~indent ppf body finalizer handler
  | (_, With { obj; body }) -> pp_with ~indent ppf obj body
  | (_, Labeled { label; body }) -> pp_labeled ~indent ppf label body
  | (_, VarDecl { kind; id }) -> pp_vardecl ~indent ppf kind id
  | (_, Return { argument; _ }) -> pp_return ~indent ppf argument
  | (_, Throw { argument; _ }) -> pp_throw ~indent ppf argument
  | (_, Break { label }) -> pp_break ~indent ppf label
  | (_, Continue { label }) -> pp_continue ~indent ppf label
  | (_, Debugger _) -> pp_debugger ~indent ppf ()
  | (_, Yield { left; argument; _ }) -> pp_yield ~indent ppf left argument
  | (_, ExportDefaultDecl { declaration }) ->
    pp_export_default_decl ~indent ppf declaration
  | (_, ExportNamedDecl { local; exported; all; source }) ->
    pp_export_named_decl ~indent ppf local exported all source
  | (_, ImportDecl (Default { source; identifier })) ->
    pp_import_decl_default ~indent ppf source identifier
  | (_, ImportDecl (Specifier { source; local; remote; namespace })) ->
    pp_import_decl_specifier ~indent ppf source local remote namespace
  | (_, AssignSimple { left; right }) -> pp_assign_simple ~indent ppf left right
  | (_, AssignBinary { left; operator; opLeft; opRight; _ }) ->
    pp_assign_binary ~indent ppf left operator opLeft opRight
  | (_, AssignUnary { left; operator; argument; _ }) ->
    pp_assign_unary ~indent ppf left operator argument
  | (_, AssignArray { left; _ }) -> pp_assign_array ~indent ppf left
  | (_, AssignObject { left; _ }) -> pp_assign_object ~indent ppf left
  | (_, StaticUpdate { obj; property; right; is_literal; _ }) ->
    pp_static_update ~indent ppf obj property right is_literal
  | (_, DynmicUpdate { obj; property; right; _ }) ->
    pp_dynamic_update ~indent ppf obj property right
  | (_, StaticLookup { left; obj; property; is_literal; _ }) ->
    pp_static_lookup ~indent ppf left obj property is_literal
  | (_, DynmicLookup { left; obj; property; _ }) ->
    pp_dynamic_lookup ~indent ppf left obj property
  | (_, StaticDelete { left; obj; property; is_literal; _ }) ->
    pp_static_delete ~indent ppf left obj property is_literal
  | (_, DynamicDelete { left; obj; property; _ }) ->
    pp_dynamic_delete ~indent ppf left obj property
  | (_, AssignNewCall { left; callee; arguments; _ }) ->
    pp_assign_new_call ~indent ppf left callee arguments
  | (_, AssignFunCall { left; callee; arguments; _ }) ->
    pp_assign_fun_call ~indent ppf left callee arguments
  | (_, AssignMetCallStatic { left; obj; property; arguments; is_literal; _ })
    ->
    pp_assign_met_call_static ~indent ppf left obj property arguments is_literal
  | (_, AssignMetCallDynmic { left; obj; property; arguments; _ }) ->
    pp_assign_met_call_dynamic ~indent ppf left obj property arguments
  | (_, AssignFunction { left; params; body; _ }) ->
    pp_assign_function ~indent ppf left params body
  | (_, UseStrict _) -> pp_usestrict ~indent ppf ()

and pp_stmts ~(indent : int) (ppf : Format.formatter)
    (stmts : m Statement.t list) : unit =
  let pp_sep _ () = () in
  Format.fprintf ppf "%a" (Format.pp_print_list ~pp_sep (pp_stmt ~indent)) stmts
[@@inline]

and pp_if ~(indent : int) (ppf : Format.formatter) (test : m Expression.t)
    (consequent : m Statement.t list) (alternate : m Statement.t list option) :
    unit =
  let pp_body = pp_stmts ~indent:(inc_indent indent) in
  let pp_alternate ppf = function
    | None -> Format.pp_print_newline ppf ()
    | Some alternate' ->
      Format.fprintf ppf " else {\n%a%a}\n" pp_body alternate' pp_indent indent
  in
  Format.fprintf ppf "%aif (%a) {\n%a%a}%a" pp_indent indent pp_expr test
    pp_body consequent pp_indent indent pp_alternate alternate

and pp_switch ~(indent : int) (ppf : Format.formatter)
    (discriminant : m Expression.t) (cases : m Statement.Switch.Case.t list) :
    unit =
  let pp_sep _ () = () in
  let pp_test ppf = function
    | None -> Format.fprintf ppf "default: \n"
    | Some test' -> Format.fprintf ppf "case %a: \n" pp_expr test' in
  let pp_body = pp_stmts ~indent:(inc_indent indent) in
  let pp_case ~indent' ppf (_, { Statement.Switch.Case.test; consequent }) =
    Format.fprintf ppf "%a%a%a\n" pp_indent indent' pp_test test pp_body
      consequent in
  Format.fprintf ppf "switch (%a) {\n%a%a}\n" pp_expr discriminant
    (Format.pp_print_list ~pp_sep (pp_case ~indent':(inc_indent indent)))
    cases pp_indent indent

and pp_while ~(indent : int) (ppf : Format.formatter) (test : m Expression.t)
    (body : m Statement.t list) : unit =
  let pp_body = pp_stmts ~indent:(inc_indent indent) in
  Format.fprintf ppf "%awhile (%a) {\n%a%a}\n" pp_indent indent pp_expr test
    pp_body body pp_indent indent

and pp_forin ~(indent : int) (ppf : Format.formatter)
    (left : m Statement.VarDecl.t) (right : m Expression.t)
    (body : m Statement.t list) : unit =
  let pp_body = pp_stmts ~indent:(inc_indent indent) in
  Format.fprintf ppf "%afor (%a in %a) {\n%a%a}\n" pp_indent indent pp_decl left
    pp_expr right pp_body body pp_indent indent

and pp_forof ~(indent : int) (ppf : Format.formatter)
    (left : m Statement.VarDecl.t) (right : m Expression.t)
    (body : m Statement.t list) (await : bool) : unit =
  let pp_await ppf await = if await then Format.pp_print_string ppf "await " in
  let pp_body = pp_stmts ~indent:(inc_indent indent) in
  Format.fprintf ppf "%afor %a(%a of %a) {\n%a%a}\n" pp_indent indent pp_await
    await pp_decl left pp_expr right pp_body body pp_indent indent

and pp_try ~(indent : int) (ppf : Format.formatter) (body : m Statement.t list)
    (finalizer : m Statement.t list option)
    (handler : m Statement.Try.Catch.t option) : unit =
  let open Statement.Try.Catch in
  let pp_body = pp_stmts ~indent:(inc_indent indent) in
  let pp_param ppf param = Format.fprintf ppf "(%a)" pp_identifier param in
  let pp_handler ppf (_, { param; body }) =
    Format.fprintf ppf "%acatch %a{\n%a%a}" pp_indent indent
      (Format.pp_print_option pp_param)
      param pp_body body pp_indent indent in
  let pp_finalizer ppf = function
    | None -> Format.pp_print_newline ppf ()
    | Some finalizer' ->
      Format.fprintf ppf "%afinally {\n%a%a}\n" pp_indent indent pp_body
        finalizer' pp_indent indent in
  Format.fprintf ppf "%atry {\n%a%a} %a%a" pp_indent indent pp_body body
    pp_indent indent
    (Format.pp_print_option pp_handler)
    handler pp_finalizer finalizer

and pp_with ~(indent : int) (ppf : Format.formatter) (obj : m Expression.t)
    (body : m Statement.t list) : unit =
  let pp_body = pp_stmts ~indent:(inc_indent indent) in
  Format.fprintf ppf "%awith (%a) {\n%a%a}\n" pp_indent indent pp_expr obj
    pp_body body pp_indent indent

and pp_labeled ~(indent : int) (ppf : Format.formatter) (label : m Identifier.t)
    (body : m Statement.t list) : unit =
  let pp_body = pp_stmts ~indent:(inc_indent indent) in
  Format.fprintf ppf "%a%a: {\n%a%a}\n" pp_indent indent pp_identifier label
    pp_body body pp_indent indent

and pp_vardecl ~(indent : int) (ppf : Format.formatter)
    (kind : Statement.VarDecl.kind) (id : m Identifier.t) : unit =
  Format.fprintf ppf "%a%a %a;\n" pp_indent indent pp_kind kind pp_identifier id

and pp_return ~(indent : int) (ppf : Format.formatter)
    (argument : m Expression.t option) : unit =
  let pp_argument ppf argument' = Format.fprintf ppf " %a" pp_expr argument' in
  Format.fprintf ppf "%areturn%a;\n" pp_indent indent
    (Format.pp_print_option pp_argument)
    argument

and pp_throw ~(indent : int) (ppf : Format.formatter)
    (argument : m Expression.t option) : unit =
  let pp_argument ppf argument' = Format.fprintf ppf " %a" pp_expr argument' in
  Format.fprintf ppf "%athrow%a;\n" pp_indent indent
    (Format.pp_print_option pp_argument)
    argument

and pp_break ~(indent : int) (ppf : Format.formatter)
    (label : m Identifier.t option) : unit =
  let pp_label ppf label' = Format.fprintf ppf " %a" pp_identifier label' in
  Format.fprintf ppf "%abreak%a;\n" pp_indent indent
    (Format.pp_print_option pp_label)
    label

and pp_continue ~(indent : int) (ppf : Format.formatter)
    (label : m Identifier.t option) : unit =
  let pp_label ppf label' = Format.fprintf ppf " %a" pp_identifier label' in
  Format.fprintf ppf "%acontinue%a;\n" pp_indent indent
    (Format.pp_print_option pp_label)
    label

and pp_debugger ~(indent : int) (ppf : Format.formatter) () : unit =
  Format.fprintf ppf "%adebugger;\n" pp_indent indent

and pp_yield ~(indent : int) (ppf : Format.formatter) (left : m Identifier.t)
    (argument : m Expression.t option) : unit =
  let pp_argument ppf argument' = Format.fprintf ppf " %a" pp_expr argument' in
  Format.fprintf ppf "%a%a = yield%a;\n" pp_indent indent pp_identifier left
    (Format.pp_print_option pp_argument)
    argument

and pp_export_default_decl ~(indent : int) (ppf : Format.formatter)
    (declaration : m Expression.t) : unit =
  Format.fprintf ppf "%aexport default %a;\n" pp_indent indent pp_expr
    declaration

and pp_export_named_decl ~(indent : int) (ppf : Format.formatter)
    (local : m Identifier.t option) (exported : m Identifier.t option)
    (all : bool) (source : string option) : unit =
  let pp_local ppf local =
    if all then Format.pp_print_string ppf "*"
    else pp_identifier ppf (Option.get local) in
  let pp_exported ppf exported =
    Format.fprintf ppf " as %a" pp_identifier exported in
  let pp_source ppf source = Format.fprintf ppf " from \"%s\"" source in
  Format.fprintf ppf "%aexport %a%a%a;\n" pp_indent indent pp_local local
    (Format.pp_print_option pp_exported)
    exported
    (Format.pp_print_option pp_source)
    source

and pp_import_decl_default ~(indent : int) (ppf : Format.formatter)
    (source : string) (identifier : m Identifier.t) : unit =
  Format.fprintf ppf "%aimport %a from \"%s\";\n" pp_indent indent pp_identifier
    identifier source

and pp_import_decl_specifier ~(indent : int) (ppf : Format.formatter)
    (source : string) (local : m Identifier.t option)
    (remote : m Identifier.t option) (namespace : bool) : unit =
  let pp_local ppf local = Format.fprintf ppf " as %a" pp_identifier local in
  let pp_namespace ppf (remote, local) =
    if namespace then
      Format.fprintf ppf "{ %a%a }" pp_identifier (Option.get remote)
        (Format.pp_print_option pp_local)
        local
    else Format.fprintf ppf "*%a" (Format.pp_print_option pp_local) local in
  Format.fprintf ppf "%aimport %a from \"%s\";\n" pp_indent indent pp_namespace
    (remote, local) source

and pp_assign_simple ~(indent : int) (ppf : Format.formatter)
    (left : m Identifier.t) (right : m Expression.t) : unit =
  Format.fprintf ppf "%a%a = %a;\n" pp_indent indent pp_identifier left pp_expr
    right

and pp_assign_binary ~(indent : int) (ppf : Format.formatter)
    (left : m Identifier.t) (operator : Operator.Binary.t)
    (opLeft : m Expression.t) (opRight : m Expression.t) : unit =
  let open Operator.Binary in
  let pp_op ppf = function
    | Equal -> Format.pp_print_string ppf " == "
    | NotEqual -> Format.pp_print_string ppf " != "
    | StrictEqual -> Format.pp_print_string ppf " === "
    | StrictNotEqual -> Format.pp_print_string ppf " !== "
    | LessThan -> Format.pp_print_string ppf " < "
    | LessThanEqual -> Format.pp_print_string ppf " <= "
    | GreaterThan -> Format.pp_print_string ppf " > "
    | GreaterThanEqual -> Format.pp_print_string ppf " >= "
    | LShift -> Format.pp_print_string ppf " << "
    | RShift -> Format.pp_print_string ppf " >> "
    | RShift3 -> Format.pp_print_string ppf " >>> "
    | Plus -> Format.pp_print_string ppf " + "
    | Minus -> Format.pp_print_string ppf " - "
    | Mult -> Format.pp_print_string ppf " * "
    | Exp -> Format.pp_print_string ppf " ** "
    | Div -> Format.pp_print_string ppf " / "
    | Mod -> Format.pp_print_string ppf " % "
    | BitOr -> Format.pp_print_string ppf " | "
    | Xor -> Format.pp_print_string ppf " ^ "
    | BitAnd -> Format.pp_print_string ppf " & "
    | In -> Format.pp_print_string ppf " in "
    | Instanceof -> Format.pp_print_string ppf " instanceof "
    | Or -> Format.pp_print_string ppf " || "
    | And -> Format.pp_print_string ppf " && "
    | NullishCoalesce -> Format.pp_print_string ppf " ?? " in
  Format.fprintf ppf "%a%a = %a%a%a;\n" pp_indent indent pp_identifier left
    pp_expr opLeft pp_op operator pp_expr opRight

and pp_assign_unary ~(indent : int) (ppf : Format.formatter)
    (left : m Identifier.t) (operator : Operator.Unary.t)
    (argument : m Expression.t) : unit =
  let open Operator.Unary in
  let pp_op ppf = function
    | Minus -> Format.pp_print_string ppf "-"
    | Plus -> Format.pp_print_string ppf "+"
    | Not -> Format.pp_print_string ppf "!"
    | BitNot -> Format.pp_print_string ppf "~"
    | Typeof -> Format.pp_print_string ppf "typeof "
    | Void -> Format.pp_print_string ppf "void "
    | Delete -> Format.pp_print_string ppf "delete "
    | Await -> Format.pp_print_string ppf "await " in
  Format.fprintf ppf "%a%a = %a%a;\n" pp_indent indent pp_identifier left pp_op
    operator pp_expr argument

and pp_assign_array ~(indent : int) (ppf : Format.formatter)
    (left : m Identifier.t) : unit =
  Format.fprintf ppf "%a%a = [];\n" pp_indent indent pp_identifier left

and pp_assign_object ~(indent : int) (ppf : Format.formatter)
    (left : m Identifier.t) : unit =
  Format.fprintf ppf "%a%a = {};\n" pp_indent indent pp_identifier left

and pp_static_update ~(indent : int) (ppf : Format.formatter)
    (obj : m Expression.t) (property : string) (right : m Expression.t)
    (is_literal : bool) : unit =
  let pp_property ppf property =
    if is_literal then Format.fprintf ppf "[\"%s\"]" property
    else Format.fprintf ppf ".%s" property in
  Format.fprintf ppf "%a%a%a = %a;\n" pp_indent indent pp_expr obj pp_property
    property pp_expr right

and pp_dynamic_update ~(indent : int) (ppf : Format.formatter)
    (obj : m Expression.t) (property : m Expression.t) (right : m Expression.t)
    : unit =
  Format.fprintf ppf "%a%a[%a] = %a;\n" pp_indent indent pp_expr obj pp_expr
    property pp_expr right

and pp_static_lookup ~(indent : int) (ppf : Format.formatter)
    (left : m Identifier.t) (obj : m Expression.t) (property : string)
    (is_literal : bool) : unit =
  let pp_property ppf property =
    if is_literal then Format.fprintf ppf "[\"%s\"]" property
    else Format.fprintf ppf ".%s" property in
  Format.fprintf ppf "%a%a = %a%a;\n" pp_indent indent pp_identifier left
    pp_expr obj pp_property property

and pp_dynamic_lookup ~(indent : int) (ppf : Format.formatter)
    (left : m Identifier.t) (obj : m Expression.t) (property : m Expression.t) :
    unit =
  Format.fprintf ppf "%a%a = %a[%a];\n" pp_indent indent pp_identifier left
    pp_expr obj pp_expr property

and pp_static_delete ~(indent : int) (ppf : Format.formatter)
    (left : m Identifier.t) (obj : m Expression.t) (property : string)
    (is_literal : bool) : unit =
  let pp_property ppf property =
    if is_literal then Format.fprintf ppf "[\"%s\"]" property
    else Format.fprintf ppf ".%s" property in
  Format.fprintf ppf "%a%a = delete %a%a;\n" pp_indent indent pp_identifier left
    pp_expr obj pp_property property

and pp_dynamic_delete ~(indent : int) (ppf : Format.formatter)
    (left : m Identifier.t) (obj : m Expression.t) (property : m Expression.t) :
    unit =
  Format.fprintf ppf "%a%a = delete %a[%a];\n" pp_indent indent pp_identifier
    left pp_expr obj pp_expr property

and pp_assign_new_call ~(indent : int) (ppf : Format.formatter)
    (left : m Identifier.t) (callee : m Identifier.t)
    (arguments : m Expression.t list) : unit =
  let pp_sep ppf () = Format.fprintf ppf ", " in
  Format.fprintf ppf "%a%a = new %a(%a);\n" pp_indent indent pp_identifier left
    pp_identifier callee
    (Format.pp_print_list ~pp_sep pp_expr)
    arguments

and pp_assign_fun_call ~(indent : int) (ppf : Format.formatter)
    (left : m Identifier.t) (callee : m Identifier.t)
    (arguments : m Expression.t list) : unit =
  let pp_sep ppf () = Format.fprintf ppf ", " in
  Format.fprintf ppf "%a%a = %a(%a);\n" pp_indent indent pp_identifier left
    pp_identifier callee
    (Format.pp_print_list ~pp_sep pp_expr)
    arguments

and pp_assign_met_call_static ~(indent : int) (ppf : Format.formatter)
    (left : m Identifier.t) (obj : m Expression.t) (property : string)
    (arguments : m Expression.t list) (is_literal : bool) : unit =
  let pp_sep ppf () = Format.fprintf ppf ", " in
  let pp_property ppf property =
    if is_literal then Format.fprintf ppf "[\"%s\"]" property
    else Format.fprintf ppf ".%s" property in
  Format.fprintf ppf "%a%a = %a%a(%a);\n" pp_indent indent pp_identifier left
    pp_expr obj pp_property property
    (Format.pp_print_list ~pp_sep pp_expr)
    arguments

and pp_assign_met_call_dynamic ~(indent : int) (ppf : Format.formatter)
    (left : m Identifier.t) (obj : m Expression.t) (property : m Expression.t)
    (arguments : m Expression.t list) : unit =
  let pp_sep ppf () = Format.fprintf ppf ", " in
  Format.fprintf ppf "%a%a = %a[%a](%a);\n" pp_indent indent pp_identifier left
    pp_expr obj pp_expr property
    (Format.pp_print_list ~pp_sep pp_expr)
    arguments

and pp_assign_function ~(indent : int) (ppf : Format.formatter)
    (left : m Identifier.t) (params : m Statement.AssignFunction.Param.t list)
    (body : m Statement.t list) : unit =
  let open Statement.AssignFunction.Param in
  let pp_sep ppf () = Format.fprintf ppf ", " in
  let pp_body = pp_stmts ~indent:(inc_indent indent) in
  let pp_default ppf default = Format.fprintf ppf " = %a" pp_expr default in
  let pp_param ppf (_, { argument; default }) =
    Format.fprintf ppf "%a%a" pp_identifier argument
      (Format.pp_print_option pp_default)
      default in
  Format.fprintf ppf "%a%a = function (%a) {\n%a%a}\n" pp_indent indent
    pp_identifier left
    (Format.pp_print_list ~pp_sep pp_param)
    params pp_body body pp_indent indent

and pp_usestrict ~(indent : int) (ppf : Format.formatter) () : unit =
  Format.fprintf ppf "%a\"use strict\";\n" pp_indent indent

let pp_program ~(indent : int) (ppf : Format.formatter) (_, { Program.body; _ })
    : unit =
  pp_stmts ~indent ppf body
[@@inline]

let str (program : m Program.t) : string =
  Format.asprintf "%a" (pp_program ~indent:0) program
[@@inline]
