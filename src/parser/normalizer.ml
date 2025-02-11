open Graphjs_base
open Graphjs_ast
open Graphjs_ast.Metadata
module Flow = Flow_ast

type id = Region.t Identifier.t
type lval = Region.t LeftValue.t
type expr = Region.t Expression.t
type stmt = Region.t Statement.t
type case = Region.t SwitchCase.t
type catch = Region.t Catch.t

type prop =
  | Static of Region.t Prop.t
  | Dynamic of Region.t Expression.t

type n_id = stmt list * id
type n_lval = stmt list * lval
type n_expr = stmt list * expr
type n_prop = stmt list * prop
type n_stmt = stmt list
type n_case = stmt list * case

module Ctx = struct
  type stmt_ctx =
    | General
    | AssignSimple
    | AssignDecl of LeftValueKind.t
    | AssignOperator of Flow.Expression.Assignment.operator
    | FuncDecl

  type t =
    { curr_lval : lval option
    ; curr_stmt : stmt_ctx
    ; curr_proto : lval option
    }

  let default : unit -> t =
    let dflt = { curr_lval = None; curr_stmt = General; curr_proto = None } in
    fun () -> dflt
end

module FlowUtils = struct
  type ('M, 'T) for_left =
    | LeftDeclaration of ('M * ('M, 'T) Flow.Statement.VariableDeclaration.t)
    | LeftPattern of ('M, 'T) Flow.Pattern.t

  let convert_forin_left :
      ('M, 'T) Flow.Statement.ForIn.left -> ('M, 'T) for_left = function
    | LeftDeclaration decl -> LeftDeclaration decl
    | LeftPattern pat -> LeftPattern pat

  let convert_forof_left :
      ('M, 'T) Flow.Statement.ForOf.left -> ('M, 'T) for_left = function
    | LeftDeclaration decl -> LeftDeclaration decl
    | LeftPattern pat -> LeftPattern pat
end

let get_leftvalue (ctx : Ctx.t) (n_loc : Region.t) : lval =
  (* TODO[flag]: disable this and always generate random *)
  match ctx.curr_lval with
  | None -> LeftValue.random () @> n_loc
  | Some n_lval -> n_lval

let get_leftvalue_redef ?(init : (lval -> n_stmt) option) (ctx : Ctx.t)
    (n_loc : Region.t) : n_lval =
  let n_lval = get_leftvalue ctx n_loc in
  match (n_lval.el.kind, init) with
  | (None, None) -> ([], n_lval)
  | (None, Some init') -> (init' n_lval, LeftValue.initialize n_lval)
  | ((Var | Let), None) ->
    ([ VarDecl.create_stmt n_lval.el @> n_loc ], LeftValue.initialize n_lval)
  | ((Var | Let), Some init') -> (init' n_lval, LeftValue.initialize n_lval)
  | (Const, None) ->
    let n_lval = LeftValue.random () @> n_loc in
    ([ VarDecl.create_stmt n_lval.el @> n_loc ], LeftValue.initialize n_lval)
  | (Const, Some init') ->
    let n_lval = LeftValue.random () @> n_loc in
    (init' n_lval, LeftValue.initialize n_lval)

let get_class_ctx (ctx : Ctx.t) : lval * lval =
  match (ctx.curr_lval, ctx.curr_proto) with
  | (Some n_class, Some n_proto) -> (n_class, n_proto)
  | _ -> Log.fail "expecting class information in current context"

let get_class_leftvalue (ctx : Ctx.t) (static : bool) : lval =
  let (n_class, n_proto) = get_class_ctx ctx in
  if static then n_class else n_proto

let lookup_property (n_left : lval) (n_obj : expr) (n_prop : prop) :
    Region.t Statement.t' =
  match n_prop with
  | Static prop -> StaticLookup.create_stmt n_left n_obj prop
  | Dynamic prop -> DynamicLookup.create_stmt n_left n_obj prop

let update_property (n_obj : expr) (n_prop : prop) (n_right : expr) :
    Region.t Statement.t' =
  match n_prop with
  | Static prop -> StaticUpdate.create_stmt n_obj prop n_right
  | Dynamic prop -> DynamicUpdate.create_stmt n_obj prop n_right

let delete_property (n_left : lval) (n_obj : expr) (n_prop : prop) :
    Region.t Statement.t' =
  match n_prop with
  | Static prop -> StaticDelete.create_stmt n_left n_obj prop
  | Dynamic prop -> DynamicDelete.create_stmt n_left n_obj prop

let call_property (n_left : lval) (n_obj : expr) (n_prop : prop)
    (n_args : Region.t Expression.t list) : Region.t Statement.t' =
  match n_prop with
  | Static prop -> StaticMethodCall.create_stmt n_left n_obj prop n_args
  | Dynamic prop -> DynamicMethodCall.create_stmt n_left n_obj prop n_args

let create_function (ctx : Ctx.t) (n_left : lval) (n_params : id list)
    (n_body : n_stmt) (async : bool) (gen : bool) : Region.t Statement.t' =
  match ctx.curr_stmt with
  | General | AssignSimple | AssignDecl _ ->
    FunctionDefinition.create_stmt n_left n_params n_body async gen false
  | FuncDecl ->
    FunctionDefinition.create_stmt n_left n_params n_body async gen true
  | _ -> Log.fail "invalid statement context for function creation"

let get_property_identifier_expr : prop -> Region.t Expression.t' = function
  | Static { el = Prop.IProp id; _ } ->
    Literal.(to_expr @@ string id.name (Fmt.str "%S" id.name))
  | Static { el = Prop.LProp lit; _ } -> Literal.to_expr lit
  | Dynamic prop -> prop.el

and get_stmts_leftvalues (n_stmts : n_stmt) : lval list =
  Fun.flip List.filter_map n_stmts (function
    | { el = `VarDecl vdecl; md } -> Some (vdecl @> md)
    | { el = `Assignment assign; _ } -> Some assign.left
    | { el = `NewObject obj; _ } -> Some obj.left
    | { el = `NewArray arr; _ } -> Some arr.left
    | { el = `Unopt unopt; _ } -> Some unopt.left
    | { el = `Binopt binopt; _ } -> Some binopt.left
    | { el = `Yield yield; _ } -> Some yield.left
    | { el = `StaticLookup lookup; _ } -> Some lookup.left
    | { el = `DynamicLookup lookup; _ } -> Some lookup.left
    | { el = `StaticDelete delete; _ } -> Some delete.left
    | { el = `DynamicDelete delete; _ } -> Some delete.left
    | { el = `NewCall newcall; _ } -> Some newcall.left
    | { el = `FunctionCall funcall; _ } -> Some funcall.left
    | { el = `StaticMethodCall metcall; _ } -> Some metcall.left
    | { el = `DynamicMethodCall metcall; _ } -> Some metcall.left
    | { el = `FunctionDefinition fundef; _ } -> Some fundef.left
    | { el = `DynamicImport import; _ } -> Some import.left
    | _ -> None )

and initialize_stmts_leftvalues (n_stmts : n_stmt) : n_stmt =
  let f = LeftValue.initialize in
  let ( @> ) el md = [ el @> md ] in
  Fun.(List.flatten << flip List.map n_stmts) (function
    | { el = `VarDecl _; _ } -> []
    | { el = `Assignment el; md } ->
      `Assignment { el with left = f el.left } @> md
    | { el = `NewObject el; md } -> NewObject.create_stmt (f el.left) @> md
    | { el = `NewArray el; md } -> NewArray.create_stmt (f el.left) @> md
    | { el = `Unopt el; md } -> `Unopt { el with left = f el.left } @> md
    | { el = `Binopt el; md } -> `Binopt { el with left = f el.left } @> md
    | { el = `Yield el; md } -> `Yield { el with left = f el.left } @> md
    | { el = `StaticLookup el; md } ->
      `StaticLookup { el with left = f el.left } @> md
    | { el = `DynamicLookup el; md } ->
      `DynamicLookup { el with left = f el.left } @> md
    | { el = `StaticUpdate _; _ } -> []
    | { el = `DynamicUpdate _; _ } -> []
    | { el = `StaticDelete el; md } ->
      `StaticDelete { el with left = f el.left } @> md
    | { el = `DynamicDelete el; md } ->
      `DynamicDelete { el with left = f el.left } @> md
    | { el = `NewCall el; md } -> `NewCall { el with left = f el.left } @> md
    | { el = `FunctionCall el; md } ->
      `FunctionCall { el with left = f el.left } @> md
    | { el = `StaticMethodCall el; md } ->
      `StaticMethodCall { el with left = f el.left } @> md
    | { el = `DynamicMethodCall el; md } ->
      `DynamicMethodCall { el with left = f el.left } @> md
    | { el = `FunctionDefinition el; md } ->
      `FunctionDefinition { el with left = f el.left } @> md
    | { el = `DynamicImport el; md } ->
      `DynamicImport { el with left = f el.left } @> md
    | n_stmt -> [ n_stmt ] )

let normalize_location (loc : Loc.t) : Region.t =
  let file = Option.fold ~none:"" ~some:File_key.to_string loc.source in
  let lpos = Region.create_pos loc.start.line loc.start.column in
  let rpos = Region.create_pos loc._end.line loc._end.column in
  Region.create file lpos rpos

let ( @!> ) (element : 'e) (loc : Loc.t) : (Region.t, 'e) Metadata.t =
  element @> normalize_location loc
[@@inline]

let rec leftvalue_ctx (ctx : Ctx.t) :
    (Loc.t, Loc.t) Flow.Pattern.t -> lval option = function
  | (_, Identifier id) -> Some (normalize_leftvalue ctx id.name)
  | _ -> None

and leftvalue_ctx_random (n_loc : Region.t) : lval option =
  Some (LeftValue.random () @> n_loc)

and declaration_ctx (ctx : Ctx.t) : LeftValueKind.t =
  match ctx.curr_stmt with AssignDecl kind -> kind | _ -> None

and assignment_ctx : Flow.Expression.Assignment.operator option -> Ctx.stmt_ctx
    = function
  | None -> AssignSimple
  | Some op -> AssignOperator op

and normalize_identifier (_ : Ctx.t)
    ((loc, id) : (Loc.t, Loc.t) Flow.Identifier.t) : id =
  Identifier.create id.name @!> loc

and normalize_identifier_opt (ctx : Ctx.t) (loc : Loc.t) :
    (Loc.t, Loc.t) Flow.Identifier.t option -> id = function
  | None -> Identifier.random () @!> loc
  | Some id -> normalize_identifier ctx id

and normalize_leftvalue (ctx : Ctx.t)
    ((loc, id) : (Loc.t, Loc.t) Flow.Identifier.t) : lval =
  LeftValue.create ~kind:(declaration_ctx ctx) id.name @!> loc

and normalize_null_literal (_ : Ctx.t) (loc : Loc.t) : n_expr =
  ([], Literal.(to_expr @@ null ()) @!> loc)

and normalize_string_literal (_ : Ctx.t) (loc : Loc.t)
    (literal : Loc.t Flow.StringLiteral.t) : n_expr =
  ([], Literal.(to_expr @@ string literal.value literal.raw) @!> loc)

and normalize_number_literal (_ : Ctx.t) (loc : Loc.t)
    (literal : Loc.t Flow.NumberLiteral.t) : n_expr =
  ([], Literal.(to_expr @@ number literal.value literal.raw) @!> loc)

and normalize_bigint_literal (_ : Ctx.t) (loc : Loc.t)
    (literal : Loc.t Flow.BigIntLiteral.t) : n_expr =
  ([], Literal.(to_expr @@ bigint literal.value literal.raw) @!> loc)

and normalize_boolean_literal (_ : Ctx.t) (loc : Loc.t)
    (literal : Loc.t Flow.BooleanLiteral.t) : n_expr =
  ([], Literal.(to_expr @@ boolean literal.value) @!> loc)

and normalize_regexpr_literal (_ : Ctx.t) (loc : Loc.t)
    (literal : Loc.t Flow.RegExpLiteral.t) : n_expr =
  let n_regex = Regex.create literal.pattern literal.flags in
  ([], Literal.(to_expr @@ regex n_regex literal.raw) @!> loc)

and normalize_template_expr (ctx : Ctx.t) (loc : Loc.t)
    (tliteral : (Loc.t, Loc.t) Flow.Expression.TemplateLiteral.t) : n_expr =
  let (n_quasis, n_exprs_s, n_exprs) = normalize_template_literal ctx tliteral in
  let n_tliteral = TemplateLiteral.create_expr n_quasis n_exprs @!> loc in
  (n_exprs_s, n_tliteral)

and normalize_template_literal (_ : Ctx.t)
    (tliteral : (Loc.t, Loc.t) Flow.Expression.TemplateLiteral.t) :
    Region.t TemplateElement.t list * n_stmt * expr list =
  let n_quasis = List.map normalize_template_element tliteral.quasis in
  let (n_exprs_s, n_exprs) =
    List.map normalize_expr tliteral.expressions |> List.split in
  (n_quasis, List.flatten n_exprs_s, n_exprs)

and normalize_template_element
    ((loc, telement) : Loc.t Flow.Expression.TemplateLiteral.Element.t) :
    Region.t TemplateElement.t =
  let n_tvalue = TemplateValue.create telement.value.raw telement.value.cooked in
  TemplateElement.create n_tvalue telement.tail @!> loc

and normalize_identifier_expr (_ : Ctx.t) (loc : Loc.t)
    ((_, id) : (Loc.t, Loc.t) Flow.Identifier.t) : n_expr =
  ([], Identifier.create_expr id.name @!> loc)

and normalize_this_expr (_ : Ctx.t) (loc : Loc.t) : n_expr =
  ([], This.create_expr () @!> loc)

and normalize_super_expr (_ : Ctx.t) (loc : Loc.t) : n_expr =
  (* TODO[flag]: optimize the super by storing the __super__ property in the object *)
  let n_loc = normalize_location loc in
  let n_this = This.create_expr () @> n_loc in
  let p_proto = Static (Prop.IProp (Identifier.create "__proto__") @> n_loc) in
  let n_proto = LeftValue.random () @> n_loc in
  let n_proto' = LeftValue.initialize n_proto in
  let n_proto'' = LeftValue.to_expr n_proto @> n_loc in
  let n_proto1_s = lookup_property n_proto n_this p_proto @> n_loc in
  let n_proto2_s = lookup_property n_proto' n_proto'' p_proto @> n_loc in
  ([ n_proto1_s; n_proto2_s ], n_proto'')

and normalize_sequence_expr (ctx : Ctx.t) (_ : Loc.t)
    (exprs : (Loc.t, Loc.t) Flow.Expression.Sequence.t) : n_expr =
  let (n_exprs_s, n_exprs) =
    List.map (normalize_expr ~ctx) exprs.expressions |> List.split in
  let n_expr_last = List.nth n_exprs (List.length n_exprs - 1) in
  (List.flatten n_exprs_s, n_expr_last)

and normalize_object_expr (ctx : Ctx.t) (loc : Loc.t)
    (obj : (Loc.t, Loc.t) Flow.Expression.Object.t) : n_expr =
  let n_loc = normalize_location loc in
  let n_left = get_leftvalue ctx n_loc in
  let n_left' = LeftValue.to_expr n_left @> n_loc in
  let n_obj_s = NewObject.create_stmt n_left @> n_loc in
  let normalize_prop_f = normalize_obj_property ctx n_left' in
  let n_prop_s = List.map normalize_prop_f obj.properties |> List.flatten in
  (n_obj_s :: n_prop_s, n_left')

and normalize_property_key (_ : Ctx.t) :
    (Loc.t, Loc.t) Flow.Expression.Object.Property.key -> n_prop = function
  | Identifier (loc, id) ->
    ([], Static (Prop.IProp (Identifier.create id.name) @!> loc))
  | StringLiteral (loc, lit) ->
    ([], Static (Prop.LProp (Literal.string lit.value lit.raw) @!> loc))
  | NumberLiteral (loc, lit) ->
    ([], Static (Prop.LProp (Literal.number lit.value lit.raw) @!> loc))
  | BigIntLiteral (loc, lit) ->
    ([], Static (Prop.LProp (Literal.bigint lit.value lit.raw) @!> loc))
  | PrivateName _ -> Log.fail "[not implemented]: private property"
  | Computed (_, { expression = expr; _ }) ->
    let (n_expr_s, n_expr) = normalize_expr expr in
    (n_expr_s, Dynamic n_expr)

and normalize_obj_property (ctx : Ctx.t) (n_obj : expr) :
    (Loc.t, Loc.t) Flow.Expression.Object.property -> n_stmt = function
  | Property (loc, Init { key; value; _ }) ->
    normalize_init_property ctx loc n_obj key value
  | Property (loc, Method { key; value }) ->
    normalize_method_property ctx loc n_obj key value
  | Property (loc, Get { key; value; _ }) ->
    normalize_getter_setter_property ctx loc "get" n_obj key value
  | Property (loc, Set { key; value; _ }) ->
    normalize_getter_setter_property ctx loc "set" n_obj key value
  (* TODO: Implement the normalization of the spread property *)
  (* | SpreadProperty (_, _) -> Log.fail "[not implemented]: spread property" *)
  | SpreadProperty (_, _) -> []

and normalize_init_property (ctx : Ctx.t) (loc : Loc.t) (n_obj : expr)
    (key : (Loc.t, Loc.t) Flow.Expression.Object.Property.key)
    (value : (Loc.t, Loc.t) Flow.Expression.t) : n_stmt =
  let (n_key_s, n_key) = normalize_property_key ctx key in
  let (n_value_s, n_value) = normalize_expr value in
  let init_prop_s = update_property n_obj n_key n_value @!> loc in
  n_key_s @ n_value_s @ [ init_prop_s ]

and normalize_method_property (ctx : Ctx.t) (loc : Loc.t) (n_obj : expr)
    (key : (Loc.t, Loc.t) Flow.Expression.Object.Property.key)
    ((func_loc, func) : Loc.t * (Loc.t, Loc.t) Flow.Function.t) : n_stmt =
  let (n_key_s, n_key) = normalize_property_key ctx key in
  let (n_func_s, n_func) = normalize_function_expression ctx func_loc func in
  let method_prop_s = update_property n_obj n_key n_func @!> loc in
  n_key_s @ n_func_s @ [ method_prop_s ]

and normalize_getter_setter_property (ctx : Ctx.t) (loc : Loc.t) (kind : string)
    (n_obj : expr) (key : (Loc.t, Loc.t) Flow.Expression.Object.Property.key)
    ((func_loc, func) : Loc.t * (Loc.t, Loc.t) Flow.Function.t) : n_stmt =
  let n_loc = normalize_location loc in
  let (n_key_s, n_key) = normalize_property_key ctx key in
  let (n_func_s, n_func) = normalize_function_expression ctx func_loc func in
  let (n_wrp_s, n_wrp) = normalize_getter_setter_wrapper ctx n_loc kind n_func in
  let n_defprop_s = normalize_define_property ctx n_loc n_obj n_key n_wrp in
  n_key_s @ n_func_s @ n_wrp_s @ n_defprop_s

and normalize_getter_setter_wrapper (_ : Ctx.t) (n_loc : Region.t)
    (kind : string) (n_func : expr) : n_expr =
  (* TODO[flag]: disable getters and setters *)
  let p_kind = Prop.IProp (Identifier.create kind) @> n_loc in
  let p_config = Prop.IProp (Identifier.create "configurable") @> n_loc in
  let tr = Literal.(to_expr @@ boolean true) @> n_loc in
  let n_wrp = LeftValue.random () @> n_loc in
  let n_wrp' = LeftValue.to_expr n_wrp @> n_loc in
  let n_wrp_new_s = NewObject.create_stmt n_wrp @> n_loc in
  let n_wrp_get_s = StaticUpdate.create_stmt n_wrp' p_kind n_func @> n_loc in
  let n_wrp_config_s = StaticUpdate.create_stmt n_wrp' p_config tr @> n_loc in
  ([ n_wrp_new_s; n_wrp_get_s; n_wrp_config_s ], n_wrp')

and normalize_define_property (_ : Ctx.t) (n_loc : Region.t) (n_obj : expr)
    (n_key : prop) (n_wrp : expr) : n_stmt =
  let n_key' = get_property_identifier_expr n_key @> n_loc in
  let n_left = LeftValue.random () @> n_loc in
  let n_class = Identifier.create_expr "Object" @> n_loc in
  let p_method = Prop.IProp (Identifier.create "defineProperty") @> n_loc in
  let n_args = [ n_obj; n_key'; n_wrp ] in
  [ StaticMethodCall.create_stmt n_left n_class p_method n_args @> n_loc ]

and normalize_array_expr (ctx : Ctx.t) (loc : Loc.t)
    (arr : (Loc.t, Loc.t) Flow.Expression.Array.t) : n_expr =
  let n_loc = normalize_location loc in
  let n_left = get_leftvalue ctx n_loc in
  let n_left' = LeftValue.to_expr n_left @> n_loc in
  let n_arr_s = NewArray.create_stmt n_left @> n_loc in
  let normalize_el_f = normalize_arr_element ctx n_left' in
  let n_els_s = List.mapi normalize_el_f arr.elements |> List.flatten in
  (n_arr_s :: n_els_s, n_left')

and normalize_arr_element (ctx : Ctx.t) (n_arr : expr) (idx : int) :
    (Loc.t, Loc.t) Flow.Expression.Array.element -> n_stmt = function
  | Hole _ -> []
  | Expression ((loc, _) as expr) ->
    normalize_expr_element ctx loc n_arr idx expr
  (* TODO: implement the normalization of the spread element *)
  (* | Spread _ -> Log.fail "[not implemented]: spread element" *)
  | Spread _ -> []

and normalize_expr_element (_ : Ctx.t) (loc : Loc.t) (n_arr : expr) (idx : int)
    (expr : (Loc.t, Loc.t) Flow.Expression.t) : n_stmt =
  let n_loc = normalize_location loc in
  let p_idx = Prop.LProp (Literal.integer idx) @> n_loc in
  let (n_expr_s, n_expr) = normalize_expr expr in
  let init_el_s = StaticUpdate.create_stmt n_arr p_idx n_expr @> n_loc in
  n_expr_s @ [ init_el_s ]

and normalize_null_or_undef_impl
    ((t_op, c_op) : Operator.binary * Operator.binary) (n_loc : Region.t)
    (n_arg : expr) (n_cnsq_s : n_stmt) (n_altr_s : n_stmt option) : n_stmt =
  let n_tnull = LeftValue.random () @> n_loc in
  let n_tundf = LeftValue.random () @> n_loc in
  let n_tnone = LeftValue.random () @> n_loc in
  let n_tnull' = LeftValue.to_expr n_tnull @> n_loc in
  let n_tundf' = LeftValue.to_expr n_tundf @> n_loc in
  let n_tnone' = LeftValue.to_expr n_tnone @> n_loc in
  let n_null = Literal.(to_expr @@ null ()) @> n_loc in
  let n_undf = Identifier.undefined_expr () @> n_loc in
  let n_tnull_s = Binopt.create_stmt n_tnull t_op n_arg n_null @> n_loc in
  let n_tundf_s = Binopt.create_stmt n_tundf t_op n_arg n_undf @> n_loc in
  let n_tnone_s = Binopt.create_stmt n_tnone c_op n_tnull' n_tundf' @> n_loc in
  let n_check_s = If.create_stmt n_tnone' n_cnsq_s n_altr_s @> n_loc in
  [ n_tnull_s; n_tundf_s; n_tnone_s; n_check_s ]

and normalize_null_or_undef (n_loc : Region.t) (n_arg : expr)
    (n_cnsq_s : n_stmt) (n_altr_s : n_stmt option) : n_stmt =
  let ops = Operator.(StrictEqual, LogicalOr) in
  normalize_null_or_undef_impl ops n_loc n_arg n_cnsq_s n_altr_s

and normalize_not_null_or_undef (n_loc : Region.t) (n_arg : expr)
    (n_cnsq_s : n_stmt) (n_altr_s : n_stmt option) : n_stmt =
  let ops = Operator.(StrictNotEqual, LogicalAnd) in
  normalize_null_or_undef_impl ops n_loc n_arg n_cnsq_s n_altr_s

and normalize_default_value (n_left : lval)
    ((loc, _) as dflt : (Loc.t, Loc.t) Flow.Expression.t) : n_stmt =
  (* TODO[flag]: disable this and ignore all defaults *)
  let op = Operator.StrictEqual in
  let n_loc = normalize_location loc in
  let n_left' = LeftValue.to_expr n_left @> n_loc in
  let n_undef = Identifier.undefined_expr () @> n_loc in
  let n_test = LeftValue.random () @> n_loc in
  let n_test' = LeftValue.to_expr n_test @> n_loc in
  let n_test_s = Binopt.create_stmt n_test op n_left' n_undef @> n_loc in
  let (n_dflt_s, n_dflt) = normalize_expr dflt in
  let n_adflt_s = [ Assignment.create_stmt n_left n_dflt @> n_loc ] in
  let n_check_s = If.create_stmt n_test' (n_dflt_s @ n_adflt_s) None @> n_loc in
  [ n_test_s; n_check_s ]

and normalize_assignment_expr (ctx : Ctx.t) (_ : Loc.t)
    (assign : (Loc.t, Loc.t) Flow.Expression.Assignment.t) : n_expr =
  let ctx' = { ctx with curr_stmt = assignment_ctx assign.operator } in
  normalize_assignment ctx' assign.left assign.right

and normalize_assignment (ctx : Ctx.t)
    (left : (Loc.t, Loc.t) Flow_ast.Pattern.t)
    (right : (Loc.t, Loc.t) Flow_ast.Expression.t) : n_expr =
  let ctx' = { ctx with curr_lval = leftvalue_ctx ctx left } in
  let (n_right_s, n_right) = normalize_expr ~ctx:ctx' right in
  let assign_s = normalize_assignment_pattern ctx' n_right left in
  (n_right_s @ assign_s, n_right)

and normalize_assignment_pattern (ctx : Ctx.t) (n_right : expr) :
    (Loc.t, Loc.t) Flow.Pattern.t -> n_stmt = function
  | (loc, Identifier { name; _ }) ->
    normalize_assignment_with_identifier ctx loc name n_right
  | (loc, Object { properties; _ }) ->
    normalize_assignment_with_object ctx loc properties n_right
  | (loc, Array { elements; _ }) ->
    normalize_assignment_with_array ctx loc elements n_right
  | (loc, Expression (_, Member { _object = obj; property = prop; _ })) ->
    normalize_assignment_with_member ctx loc obj prop n_right
  | (_, Expression _) -> Log.fail "invalid expression in assignment pattern"

and already_assigned (n_left : lval) (n_right : expr) : bool =
  match (LeftValue.name n_left, n_right.el) with
  | (n_left', `Identifier { name = n_right'; _ }) ->
    String.equal n_left' n_right'
  | _ -> false

and normalize_assignment_arg (ctx : Ctx.t) (n_loc : Region.t) (n_key : prop)
    (n_right : expr) (dflt : (Loc.t, Loc.t) Flow.Expression.t option) : n_lval =
  let init_left_f lv = [ lookup_property lv n_right n_key @> n_loc ] in
  match dflt with
  | None ->
    let n_left = get_leftvalue ctx n_loc in
    (init_left_f n_left, n_left)
  | Some dflt' ->
    let (n_left_s, n_left) = get_leftvalue_redef ~init:init_left_f ctx n_loc in
    let n_dflt_s = normalize_default_value n_left dflt' in
    (n_left_s @ n_dflt_s, n_left)

and normalize_assignment_with_identifier (ctx : Ctx.t) (loc : Loc.t)
    (left : (Loc.t, Loc.t) Flow.Identifier.t) (n_right : expr) : n_stmt =
  let n_loc = normalize_location loc in
  let n_left = normalize_leftvalue ctx left in
  let already_assigned = already_assigned n_left n_right in
  match (already_assigned, ctx.curr_stmt) with
  | (true, _) -> []
  | (false, AssignSimple) | (false, AssignDecl _) ->
    [ Assignment.create_stmt n_left n_right @> n_loc ]
  | (false, AssignOperator op) ->
    let op' = translate_asgnopt op in
    let n_left' = LeftValue.to_expr n_left @> n_loc in
    [ Binopt.create_stmt n_left op' n_left' n_right @> n_loc ]
  | _ -> Log.fail "invalid statement context for assignment pattern"

and normalize_assignment_with_object (ctx : Ctx.t) (_ : Loc.t)
    (props : (Loc.t, Loc.t) Flow.Pattern.Object.property list) (n_right : expr)
    : n_stmt =
  Fun.(List.flatten << flip List.map props) (function
    | Flow.Pattern.Object.Property (loc, { key; pattern; default = dflt; _ }) ->
      let ctx' = { ctx with curr_lval = leftvalue_ctx ctx pattern } in
      let n_loc = normalize_location loc in
      let key' = translate_property_key key in
      let (n_key_s, n_key) = normalize_property_key ctx key' in
      let normalize_assignment_arg_f = normalize_assignment_arg ctx' n_loc in
      let (n_arg_s, n_arg) = normalize_assignment_arg_f n_key n_right dflt in
      if not (LeftValue.generated n_arg) then n_key_s @ n_arg_s
      else
        let n_arg' = LeftValue.to_expr n_arg @> n_loc in
        let n_pattern_s = normalize_assignment_pattern ctx' n_arg' pattern in
        n_key_s @ n_arg_s @ n_pattern_s
    | Flow.Pattern.Object.RestElement (_loc, _) ->
      (* TODO: implement the normalization of the rest element *)
      (* Log.fail "[not implemented]: rest element" ) *)
      [] )

and normalize_assignment_with_array (ctx : Ctx.t) (_ : Loc.t)
    (elements : (Loc.t, Loc.t) Flow.Pattern.Array.element list) (n_right : expr)
    : n_stmt =
  Fun.(List.flatten << flip List.mapi elements) (fun idx -> function
    | Flow.Pattern.Array.Hole _ -> []
    | Flow.Pattern.Array.Element (loc, { argument; default = dflt; _ }) ->
      let ctx' = { ctx with curr_lval = leftvalue_ctx ctx argument } in
      let n_loc = normalize_location loc in
      let p_idx = Static (Prop.LProp (Literal.integer idx) @> n_loc) in
      let normalize_assignment_arg_f = normalize_assignment_arg ctx' n_loc in
      let (n_arg_s, n_arg) = normalize_assignment_arg_f p_idx n_right dflt in
      if not (LeftValue.generated n_arg) then n_arg_s
      else
        let n_arg' = LeftValue.to_expr n_arg @> n_loc in
        let n_pattern_s = normalize_assignment_pattern ctx' n_arg' argument in
        n_arg_s @ n_pattern_s
    | Flow.Pattern.Array.RestElement (_loc, _) ->
      (* TODO: implement the normalization of the rest element *)
      (* Log.fail "[not implemented]: rest element" ) *)
      [] )

and normalize_assignment_with_member (ctx : Ctx.t) (loc : Loc.t)
    (obj : (Loc.t, Loc.t) Flow.Expression.t)
    (prop : (Loc.t, Loc.t) Flow.Expression.Member.property) (n_right : expr) :
    n_stmt =
  let n_loc = normalize_location loc in
  let (n_obj_s, n_obj) = normalize_expr obj in
  let (n_prop_s, n_prop) = normalize_member_property ctx prop in
  let n_assign_s =
    match ctx.curr_stmt with
    | AssignSimple -> [ update_property n_obj n_prop n_right @> n_loc ]
    | AssignOperator op ->
      let op' = translate_asgnopt op in
      let n_left = LeftValue.random () @> n_loc in
      let n_left' = LeftValue.initialize n_left in
      let n_left'' = LeftValue.to_expr n_left' @> n_loc in
      [ lookup_property n_left n_obj n_prop @> n_loc
      ; Binopt.create_stmt n_left' op' n_left'' n_right @> n_loc
      ; update_property n_obj n_prop n_left'' @> n_loc ]
    | _ -> Log.fail "invalid statement context for member assignment pattern"
  in
  n_obj_s @ n_prop_s @ n_assign_s

and normalize_unary_expr (ctx : Ctx.t) (loc : Loc.t)
    (unary : (Loc.t, Loc.t) Flow.Expression.Unary.t) : n_expr =
  let unopt = translate_unary unary.operator in
  match unary.operator with
  | Delete -> normalize_unopt_delete_expr ctx loc unopt unary.argument
  | _ -> normalize_unopt_expr ctx loc unopt unary.argument

and normalize_unopt_expr (ctx : Ctx.t) (loc : Loc.t) (op : Operator.unary)
    (arg : (Loc.t, Loc.t) Flow.Expression.t) : n_expr =
  let n_loc = normalize_location loc in
  let (n_arg_s, n_arg) = normalize_expr arg in
  let n_left = get_leftvalue ctx n_loc in
  let n_left' = LeftValue.to_expr n_left @> n_loc in
  let n_assign_s = Unopt.create_stmt n_left op n_arg @> n_loc in
  (n_arg_s @ [ n_assign_s ], n_left')

and normalize_unopt_delete_expr (ctx : Ctx.t) (loc : Loc.t)
    (op : Operator.unary) (arg : (Loc.t, Loc.t) Flow.Expression.t) : n_expr =
  match arg with
  | (_, Member { _object = obj; property = prop; _ }) ->
    let n_loc = normalize_location loc in
    let (n_obj_s, n_obj) = normalize_expr obj in
    let (n_prop_s, n_prop) = normalize_member_property ctx prop in
    let n_left = get_leftvalue ctx n_loc in
    let n_left' = LeftValue.to_expr n_left @> n_loc in
    let n_delete_s = delete_property n_left n_obj n_prop @> n_loc in
    (n_obj_s @ n_prop_s @ [ n_delete_s ], n_left')
  | _ -> normalize_unopt_expr ctx loc op arg

and normalize_binary_expr (ctx : Ctx.t) (loc : Loc.t)
    (binary : (Loc.t, Loc.t) Flow.Expression.Binary.t) : n_expr =
  let n_loc = normalize_location loc in
  let binopt = translate_binary binary.operator in
  let (n_arg1_s, n_arg1) = normalize_expr binary.left in
  let (n_arg2_s, n_arg2) = normalize_expr binary.right in
  let n_left = get_leftvalue ctx n_loc in
  let n_left' = LeftValue.to_expr n_left @> n_loc in
  let n_assign_s = Binopt.create_stmt n_left binopt n_arg1 n_arg2 @> n_loc in
  (n_arg1_s @ n_arg2_s @ [ n_assign_s ], n_left')

and normalize_logical_expr (ctx : Ctx.t) (loc : Loc.t)
    (logical : (Loc.t, Loc.t) Flow.Expression.Logical.t) : n_expr =
  (* TODO[flag]: normalize short circuit as normal operators *)
  match logical.operator with
  | And -> normalize_and_logical_expr ctx loc logical
  | Or -> normalize_or_logical_expr ctx loc logical
  | NullishCoalesce -> normalize_nullish_coalesce_expr ctx loc logical

and normalize_and_logical_expr (ctx : Ctx.t) (loc : Loc.t)
    (logical : (Loc.t, Loc.t) Flow.Expression.Logical.t) : n_expr =
  let cmp_f lv = Binopt.create_stmt lv LogicalAnd in
  let n_loc = normalize_location loc in
  let true' = Literal.(to_expr @@ boolean true) @> n_loc in
  let (n_arg1_s, n_arg1) = normalize_expr logical.left in
  let n_asgn1_f lv = [ cmp_f lv n_arg1 true' @> n_loc ] in
  let (n_left_s, n_left) = get_leftvalue_redef ~init:n_asgn1_f ctx n_loc in
  let (n_arg2_s, n_arg2) = normalize_expr logical.right in
  let n_asgn2_f lv = [ cmp_f lv n_arg2 true' @> n_loc ] in
  let n_left' = LeftValue.to_expr n_left @> n_loc in
  let n_cnsq = n_arg2_s @ n_asgn2_f n_left in
  let n_test_s = If.create_stmt n_left' n_cnsq None @> n_loc in
  (n_arg1_s @ n_left_s @ [ n_test_s ], n_left')

and normalize_or_logical_expr (ctx : Ctx.t) (loc : Loc.t)
    (logical : (Loc.t, Loc.t) Flow.Expression.Logical.t) : n_expr =
  let cmp_f lv = Binopt.create_stmt lv LogicalAnd in
  let n_loc = normalize_location loc in
  let false' = Literal.(to_expr @@ boolean false) @> n_loc in
  let (n_arg1_s, n_arg1) = normalize_expr logical.left in
  let n_asgn1_f lv = [ cmp_f lv n_arg1 false' @> n_loc ] in
  let (n_left_s, n_left) = get_leftvalue_redef ~init:n_asgn1_f ctx n_loc in
  let (n_arg2_s, n_arg2) = normalize_expr logical.right in
  let n_asgn2_f lv = [ cmp_f lv n_arg2 false' @> n_loc ] in
  let n_left' = LeftValue.to_expr n_left @> n_loc in
  let n_altr = n_arg2_s @ n_asgn2_f n_left in
  let n_test_s = If.create_stmt n_left' [] (Some n_altr) @> n_loc in
  (n_arg1_s @ n_left_s @ [ n_test_s ], n_left')

and normalize_nullish_coalesce_expr (ctx : Ctx.t) (loc : Loc.t)
    (logical : (Loc.t, Loc.t) Flow.Expression.Logical.t) : n_expr =
  let n_loc = normalize_location loc in
  let (n_arg1_s, n_arg1) = normalize_expr logical.left in
  let n_asgn1_f lv = [ Assignment.create_stmt lv n_arg1 @> n_loc ] in
  let (n_left_s, n_left) = get_leftvalue_redef ~init:n_asgn1_f ctx n_loc in
  let (n_arg2_s, n_arg2) = normalize_expr logical.right in
  let n_asgn2_f lv = [ Assignment.create_stmt lv n_arg2 @> n_loc ] in
  let n_left' = LeftValue.to_expr n_left @> n_loc in
  let n_cnsq_s = n_arg2_s @ n_asgn2_f n_left in
  let n_test_s = normalize_null_or_undef n_loc n_arg1 n_cnsq_s None in
  (n_arg1_s @ n_left_s @ n_test_s, n_left')

and normalize_conditional_expr (ctx : Ctx.t) (loc : Loc.t)
    (cond : (Loc.t, Loc.t) Flow.Expression.Conditional.t) : n_expr =
  (* TODO[flag]: disable short circuit *)
  let n_loc = normalize_location loc in
  let (n_left_s, n_left) = get_leftvalue_redef ctx n_loc in
  let n_left' = LeftValue.to_expr n_left @> n_loc in
  let (n_test_s, n_test) = normalize_expr cond.test in
  let (n_cnsq_s, n_cnsq) = normalize_expr cond.consequent in
  let (n_altr_s, n_altr) = normalize_expr cond.alternate in
  let n_cnsq_assign_s = Assignment.create_stmt n_left n_cnsq @> n_loc in
  let n_altr_assign_s = Assignment.create_stmt n_left n_altr @> n_loc in
  let n_cnsq_s' = n_cnsq_s @ [ n_cnsq_assign_s ] in
  let n_altr_s' = n_altr_s @ [ n_altr_assign_s ] in
  let n_cond_s = If.create_stmt n_test n_cnsq_s' (Some n_altr_s') @> n_loc in
  (n_left_s @ n_test_s @ [ n_cond_s ], n_left')

and normalize_update_expr (ctx : Ctx.t) (loc : Loc.t)
    (update : (Loc.t, Loc.t) Flow.Expression.Update.t) : n_expr =
  (* TODO[flag]: avoid generating the temp variable when ignoring the result *)
  let n_loc = normalize_location loc in
  let binopt = translate_update update.operator in
  let n_one = Literal.(to_expr @@ integer 1) @> n_loc in
  let n_left = get_leftvalue ctx n_loc in
  let n_left' = LeftValue.to_expr n_left @> n_loc in
  let op_pos_f sto upd = if update.prefix then [ upd; sto ] else [ sto; upd ] in
  match update.argument with
  | (_, Member { _object = obj; property = prop; _ }) ->
    let (n_obj_s, n_obj) = normalize_expr obj in
    let (n_prop_s, n_prop) = normalize_member_property ctx prop in
    let n_val = LeftValue.random () @> n_loc in
    let n_val' = LeftValue.to_expr n_val @> n_loc in
    let n_lookup_s = lookup_property n_val n_obj n_prop @> n_loc in
    let n_inc_s = Binopt.create_stmt n_val binopt n_val' n_one @> n_loc in
    let n_sto_s = Assignment.create_stmt n_left n_val' @> n_loc in
    let n_upd_s = update_property n_obj n_prop n_val' @> n_loc in
    let n_update_s = [ n_lookup_s ] @ op_pos_f n_sto_s n_inc_s @ [ n_upd_s ] in
    (n_obj_s @ n_prop_s @ n_update_s, n_left')
  | arg ->
    let (n_arg_s, n_arg') = normalize_expr arg in
    let n_arg = Identifier.of_expr n_arg' |> LeftValue.of_identifier in
    let n_sto_s = Assignment.create_stmt n_left n_arg' @> n_loc in
    let n_upd_s = Binopt.create_stmt n_arg binopt n_arg' n_one @> n_loc in
    (n_arg_s @ op_pos_f n_sto_s n_upd_s, n_left')

and normalize_yield_expr (ctx : Ctx.t) (loc : Loc.t)
    (yield : (Loc.t, Loc.t) Flow.Expression.Yield.t) : n_expr =
  let n_loc = normalize_location loc in
  let (n_arg_s, n_arg) = normalize_expr_opt yield.argument in
  let n_left = get_leftvalue ctx n_loc in
  let n_left' = LeftValue.to_expr n_left @> n_loc in
  let n_yield_s = Yield.create_stmt n_left n_arg yield.delegate @> n_loc in
  (n_arg_s @ [ n_yield_s ], n_left')

and normalize_member_expr (ctx : Ctx.t) (loc : Loc.t)
    (member : (Loc.t, Loc.t) Flow.Expression.Member.t) : n_expr =
  let n_loc = normalize_location loc in
  let (n_obj_s, n_obj) = normalize_expr member._object in
  let (n_prop_s, n_prop) = normalize_member_property ctx member.property in
  let n_left = get_leftvalue ctx n_loc in
  let n_left' = LeftValue.to_expr n_left @> n_loc in
  let n_member_s = lookup_property n_left n_obj n_prop @> n_loc in
  (n_obj_s @ n_prop_s @ [ n_member_s ], n_left')

and normalize_opt_member_expr (ctx : Ctx.t) (loc : Loc.t)
    (member : (Loc.t, Loc.t) Flow.Expression.OptionalMember.t) : n_expr =
  let n_loc = normalize_location loc in
  let n_undef = Identifier.undefined_expr () @> n_loc in
  let undef_f lv = [ Assignment.create_stmt lv n_undef @> n_loc ] in
  if member.optional == false then normalize_member_expr ctx loc member.member
  else
    let member = member.member in
    let (n_obj_s, n_obj) = normalize_expr member._object in
    let (n_prop_s, n_prop) = normalize_member_property ctx member.property in
    let (n_left_s, n_left) = get_leftvalue_redef ~init:undef_f ctx n_loc in
    let n_left' = LeftValue.to_expr n_left @> n_loc in
    let n_cnsq_s = [ lookup_property n_left n_obj n_prop @> n_loc ] in
    let n_test_s = normalize_not_null_or_undef n_loc n_obj n_cnsq_s None in
    (n_obj_s @ n_prop_s @ n_left_s @ n_test_s, n_left')

and normalize_meta_property (ctx : Ctx.t) (loc : Loc.t)
    (meta : Loc.t Flow.Expression.MetaProperty.t) : n_expr =
  let n_obj = normalize_identifier ctx meta.meta in
  let n_obj' = Identifier.to_expr n_obj @> n_obj.md in
  let n_prop = normalize_identifier ctx meta.property in
  let p_prop = Static (Prop.IProp n_prop.el @> n_prop.md) in
  let n_loc = normalize_location loc in
  let n_left = get_leftvalue ctx n_loc in
  let n_left' = LeftValue.to_expr n_left @> n_loc in
  ([ lookup_property n_left n_obj' p_prop @> n_loc ], n_left')

and normalize_member_property (_ : Ctx.t) :
    (Loc.t, Loc.t) Flow.Expression.Member.property -> n_prop = function
  | PropertyIdentifier (loc, id) ->
    ([], Static (Prop.IProp (Identifier.create id.name) @!> loc))
  | PropertyExpression (loc, NullLiteral _) ->
    ([], Static (Prop.LProp (Literal.null ()) @!> loc))
  | PropertyExpression (loc, StringLiteral lit) ->
    ([], Static (Prop.LProp (Literal.string lit.value lit.raw) @!> loc))
  | PropertyExpression (loc, NumberLiteral lit) ->
    ([], Static (Prop.LProp (Literal.number lit.value lit.raw) @!> loc))
  | PropertyExpression (loc, BigIntLiteral lit) ->
    ([], Static (Prop.LProp (Literal.bigint lit.value lit.raw) @!> loc))
  | PropertyExpression (loc, BooleanLiteral lit) ->
    ([], Static (Prop.LProp (Literal.boolean lit.value) @!> loc))
  | PropertyExpression expr ->
    let (n_expr_s, n_expr) = normalize_expr expr in
    (n_expr_s, Dynamic n_expr)
  | PropertyPrivateName _ ->
    Log.fail "[not implemented]: private property member"

and normalize_new_expr (ctx : Ctx.t) (loc : Loc.t)
    (ncall : (Loc.t, Loc.t) Flow.Expression.New.t) : n_expr =
  let normalize_arg_list_f =
    Option.fold ~none:([], []) ~some:(normalize_argument_list ctx) in
  let n_loc = normalize_location loc in
  let (n_callee_s, n_callee) = normalize_expr ncall.callee in
  let (n_args_s, n_args) = normalize_arg_list_f ncall.arguments in
  let n_left = get_leftvalue ctx n_loc in
  let n_left' = LeftValue.to_expr n_left @> n_loc in
  let n_fid = Identifier.of_expr n_callee in
  let n_call_s = NewCall.create_stmt n_left n_fid n_args @> n_loc in
  (n_callee_s @ List.flatten n_args_s @ [ n_call_s ], n_left')

and normalize_call_expr (ctx : Ctx.t) (loc : Loc.t)
    (call : (Loc.t, Loc.t) Flow.Expression.Call.t) : n_expr =
  let n_loc = normalize_location loc in
  match call.callee with
  | (_, Super _) ->
    let (n_obj_s, n_obj) = normalize_expr call.callee in
    let p_cons = Prop.IProp (Identifier.create "constructor") @> n_loc in
    let (n_args_s, n_args) = normalize_argument_list ctx call.arguments in
    let n_left = get_leftvalue ctx n_loc in
    let n_left' = LeftValue.to_expr n_left @> n_loc in
    let n_call_s = call_property n_left n_obj (Static p_cons) n_args @> n_loc in
    (n_obj_s @ List.flatten n_args_s @ [ n_call_s ], n_left')
  | (_, Member { _object = obj; property = prop; _ }) ->
    let (n_obj_s, n_obj) = normalize_expr obj in
    let (n_prop_s, n_prop) = normalize_member_property ctx prop in
    let (n_args_s, n_args) = normalize_argument_list ctx call.arguments in
    let n_left = get_leftvalue ctx n_loc in
    let n_left' = LeftValue.to_expr n_left @> n_loc in
    let n_call_s = call_property n_left n_obj n_prop n_args @> n_loc in
    (n_obj_s @ n_prop_s @ List.flatten n_args_s @ [ n_call_s ], n_left')
  | _ ->
    let (n_callee_s, n_callee) = normalize_expr call.callee in
    let (n_args_s, n_args) = normalize_argument_list ctx call.arguments in
    let n_left = get_leftvalue ctx n_loc in
    let n_left' = LeftValue.to_expr n_left @> n_loc in
    let n_fid = Identifier.of_expr n_callee in
    let n_call_s = FunctionCall.create_stmt n_left n_fid n_args @> n_loc in
    (n_callee_s @ List.flatten n_args_s @ [ n_call_s ], n_left')

and normalize_opt_call_expr (ctx : Ctx.t) (loc : Loc.t)
    (call : (Loc.t, Loc.t) Flow.Expression.OptionalCall.t) : n_expr =
  let n_loc = normalize_location loc in
  let n_undef = Identifier.undefined_expr () @> n_loc in
  let undef_f lv = [ Assignment.create_stmt lv n_undef @> n_loc ] in
  if call.optional == false then normalize_call_expr ctx loc call.call
  else
    let call = call.call in
    let (n_callee_s, n_callee) = normalize_expr call.callee in
    let n_opt = LeftValue.random () @> n_loc in
    let n_fid = Identifier.of_lval n_opt in
    let (n_args_s, n_args) = normalize_argument_list ctx call.arguments in
    let (n_left_s, n_left) = get_leftvalue_redef ~init:undef_f ctx n_loc in
    let n_left' = LeftValue.to_expr n_left @> n_loc in
    let n_fid_s = Assignment.create_stmt n_opt n_callee @> n_loc in
    let n_call_s = FunctionCall.create_stmt n_left n_fid n_args @> n_loc in
    let n_cnsq_s = List.flatten n_args_s @ [ n_call_s ] in
    let n_test_s = normalize_not_null_or_undef n_loc n_callee n_cnsq_s None in
    (n_callee_s @ [ n_fid_s ] @ n_left_s @ n_test_s, n_left')

and normalize_argument_list (_ : Ctx.t)
    ((_, args) : (Loc.t, Loc.t) Flow.Expression.ArgList.t) :
    n_stmt list * expr list =
  (* TODO: Implement the normalization of the spread argument *)
  let args =
    Fun.flip List.filter args.arguments (function
      | Expression _ -> true
      | _ -> false ) in
  Fun.(List.split << flip List.map args) (function
    | Expression expr -> normalize_expr expr
    | Spread _ -> Log.fail "[not implemented]: spread argument" )

and normalize_tagged_template (ctx : Ctx.t) (loc : Loc.t)
    (ttagged : (Loc.t, Loc.t) Flow.Expression.TaggedTemplate.t) : n_expr =
  let (tlit_loc, tlit) = ttagged.quasi in
  let n_loc = normalize_location loc in
  let n_tlit_loc = normalize_location tlit_loc in
  let (n_tag_s, n_tag) = normalize_expr ttagged.tag in
  let (n_quasis, n_exprs_s, n_exprs) = normalize_template_literal ctx tlit in
  let telement_expr_f tel = TemplateElement.to_expr tel @> n_tlit_loc in
  let n_quasis' = List.map telement_expr_f n_quasis in
  let n_qarr = LeftValue.random () @> n_loc in
  let n_qarr' = LeftValue.to_expr n_qarr @> n_loc in
  let qprop_f i = Prop.LProp (Literal.integer i) @> n_loc in
  let qupd_f i e = StaticUpdate.create_stmt n_qarr' (qprop_f i) e @> n_loc in
  let n_qarr_s = NewArray.create_stmt n_qarr @> n_loc in
  let n_qupd_s = List.mapi qupd_f n_quasis' in
  let n_left = get_leftvalue ctx n_loc in
  let n_left' = LeftValue.to_expr n_left @> n_loc in
  let n_fid = Identifier.of_expr n_tag in
  let n_args = n_qarr' :: n_exprs in
  let n_tagged_s = FunctionCall.create_stmt n_left n_fid n_args @> n_loc in
  (n_tag_s @ n_exprs_s @ [ n_qarr_s ] @ n_qupd_s @ [ n_tagged_s ], n_left')

and normalize_function_expression (ctx : Ctx.t) (loc : Loc.t)
    (func : (Loc.t, Loc.t) Flow.Function.t) : n_expr =
  let n_loc = normalize_location loc in
  let n_left = get_leftvalue ctx n_loc in
  let n_left' = LeftValue.to_expr n_left @> n_loc in
  let n_func_f = normalize_function ctx n_loc func in
  let n_func_s = normalize_alias_wrapper ctx n_loc n_func_f n_left func.id in
  (n_func_s, n_left')

and normalize_class_expression (ctx : Ctx.t) (loc : Loc.t)
    (class' : (Loc.t, Loc.t) Flow.Class.t) : n_expr =
  let n_loc = normalize_location loc in
  let n_left = get_leftvalue ctx n_loc in
  let n_left' = LeftValue.to_expr n_left @> n_loc in
  let n_class_f = normalize_class ctx n_loc class' in
  let n_class_s = normalize_alias_wrapper ctx n_loc n_class_f n_left class'.id in
  (n_class_s, n_left')

and normalize_dynamic_import (ctx : Ctx.t) (loc : Loc.t)
    (import : (Loc.t, Loc.t) Flow.Expression.Import.t) : n_expr =
  let n_loc = normalize_location loc in
  let (n_arg_s, n_arg) = normalize_expr import.argument in
  let n_left = get_leftvalue ctx n_loc in
  let n_left' = LeftValue.to_expr n_left @> n_loc in
  let n_dimport = DynamicImport.create_stmt n_left n_arg @> n_loc in
  (n_arg_s @ [ n_dimport ], n_left')

and normalize_expr ?(ctx : Ctx.t = Ctx.default ())
    (expr : (Loc.t, Loc.t) Flow.Expression.t) : n_expr =
  match expr with
  | (loc, NullLiteral _) -> normalize_null_literal ctx loc
  | (loc, StringLiteral literal) -> normalize_string_literal ctx loc literal
  | (loc, NumberLiteral literal) -> normalize_number_literal ctx loc literal
  | (loc, BigIntLiteral literal) -> normalize_bigint_literal ctx loc literal
  | (loc, BooleanLiteral literal) -> normalize_boolean_literal ctx loc literal
  | (loc, RegExpLiteral literal) -> normalize_regexpr_literal ctx loc literal
  | (loc, TemplateLiteral literal) -> normalize_template_expr ctx loc literal
  | (loc, Identifier id) -> normalize_identifier_expr ctx loc id
  | (loc, This _) -> normalize_this_expr ctx loc
  | (loc, Super _) -> normalize_super_expr ctx loc
  | (loc, Sequence exprs) -> normalize_sequence_expr ctx loc exprs
  | (loc, Object obj) -> normalize_object_expr ctx loc obj
  | (loc, Array arr) -> normalize_array_expr ctx loc arr
  | (loc, Assignment assign) -> normalize_assignment_expr ctx loc assign
  | (loc, Unary unary) -> normalize_unary_expr ctx loc unary
  | (loc, Binary binary) -> normalize_binary_expr ctx loc binary
  | (loc, Logical logical) -> normalize_logical_expr ctx loc logical
  | (loc, Conditional cond) -> normalize_conditional_expr ctx loc cond
  | (loc, Update update) -> normalize_update_expr ctx loc update
  | (loc, Yield yield) -> normalize_yield_expr ctx loc yield
  | (loc, Member member) -> normalize_member_expr ctx loc member
  | (loc, OptionalMember member) -> normalize_opt_member_expr ctx loc member
  | (loc, MetaProperty meta) -> normalize_meta_property ctx loc meta
  | (loc, New ncall) -> normalize_new_expr ctx loc ncall
  | (loc, Call call) -> normalize_call_expr ctx loc call
  | (loc, OptionalCall call) -> normalize_opt_call_expr ctx loc call
  | (loc, TaggedTemplate ttagged) -> normalize_tagged_template ctx loc ttagged
  | (loc, Function func) -> normalize_function_expression ctx loc func
  | (loc, ArrowFunction func) -> normalize_function_expression ctx loc func
  | (loc, Class class') -> normalize_class_expression ctx loc class'
  | (loc, Import dimport) -> normalize_dynamic_import ctx loc dimport
  | (_, TypeCast _)
  | (_, TSSatisfies _)
  | (_, AsConstExpression _)
  | (_, AsExpression _) ->
    Log.fail "[not implemented]: TypeScript expressions"
  | (_, JSXElement _) | (_, JSXFragment _) ->
    Log.fail "[not implemented]: React expressions"
  | (_, ModuleRefLiteral _) ->
    Log.fail "[internal flow construct]: ModuleRefLiteral"

and normalize_expr_opt ?(ctx : Ctx.t = Ctx.default ())
    (expr : (Loc.t, Loc.t) Flow.Expression.t option) : stmt list * expr option =
  match Option.map (normalize_expr ~ctx) expr with
  | Some (n_arg_s, n_arg) -> (n_arg_s, Some n_arg)
  | None -> ([], None)

and normalize_block (ctx : Ctx.t)
    ((loc, block) : Loc.t * (Loc.t, Loc.t) Flow.Statement.Block.t) : n_stmt =
  normalize_block_stmt ctx loc block

and normalize_block_stmt (ctx : Ctx.t) (_ : Loc.t)
    (block : (Loc.t, Loc.t) Flow.Statement.Block.t) : n_stmt =
  List.map (normalize_stmt ~ctx) block.body |> List.flatten

and normalize_expr_stmt (ctx : Ctx.t) (loc : Loc.t)
    (expr : (Loc.t, Loc.t) Flow.Statement.Expression.t) : n_stmt =
  let (n_expr_stmt_s, n_expr_stmt) = normalize_expr ~ctx expr.expression in
  if not (requires_expr_stmt expr.expression) then n_expr_stmt_s
  else n_expr_stmt_s @ [ ExprStmt.create_stmt n_expr_stmt.el @!> loc ]

and normalize_vdecl_stmt (ctx : Ctx.t) (_ : Loc.t)
    (vdecl : (Loc.t, Loc.t) Flow.Statement.VariableDeclaration.t) : n_stmt =
  let kind = translate_kind vdecl.kind in
  let ctx' = { ctx with curr_stmt = AssignDecl kind } in
  List.map (normalize_vdecl ctx') vdecl.declarations |> List.flatten

and normalize_vdecl (ctx : Ctx.t)
    ((_, decl) : (Loc.t, Loc.t) Flow.Statement.VariableDeclaration.Declarator.t)
    : n_stmt =
  match (decl.id, decl.init) with
  | ((loc, Identifier { name; _ }), None) ->
    let n_lval = normalize_leftvalue ctx name in
    [ VarDecl.create_stmt n_lval.el @!> loc ]
  | (_, Some init') -> normalize_assignment ctx decl.id init' |> fst
  | (_, None) -> Log.fail "invalid uninitialized pattern"

and normalize_if_stmt (ctx : Ctx.t) (loc : Loc.t)
    (if' : (Loc.t, Loc.t) Flow.Statement.If.t) : n_stmt =
  let (n_test_s, n_test) = normalize_expr ~ctx if'.test in
  let n_cnsq_s = normalize_stmt ~ctx if'.consequent in
  let n_altr_s = Option.map (normalize_alternate_stmt ctx) if'.alternate in
  let n_if_s = If.create_stmt n_test n_cnsq_s n_altr_s @!> loc in
  n_test_s @ [ n_if_s ]

and normalize_alternate_stmt (ctx : Ctx.t)
    ((_, alternate) : (Loc.t, Loc.t) Flow.Statement.If.Alternate.t) : n_stmt =
  normalize_stmt ~ctx alternate.body

and normalize_switch_stmt (ctx : Ctx.t) (loc : Loc.t)
    (switch : (Loc.t, Loc.t) Flow.Statement.Switch.t) : n_stmt =
  let (n_dscrm_s, n_dscrm) = normalize_expr ~ctx switch.discriminant in
  let (n_cases_s, n_cases) =
    List.map (normalize_switch_case ctx) switch.cases |> List.split in
  let n_switch_s = Switch.create_stmt n_dscrm n_cases @!> loc in
  n_dscrm_s @ List.flatten n_cases_s @ [ n_switch_s ]

and normalize_switch_case (ctx : Ctx.t)
    ((loc, case) : (Loc.t, Loc.t) Flow.Statement.Switch.Case.t) : n_case =
  let (n_test_s, n_test) = normalize_expr_opt ~ctx case.test in
  let n_cnsq_s = List.flatten (List.map (normalize_stmt ~ctx) case.consequent) in
  let n_case_s = SwitchCase.create n_test n_cnsq_s @!> loc in
  (n_test_s, n_case_s)

and normalize_while_stmt (ctx : Ctx.t) (loc : Loc.t)
    (while' : (Loc.t, Loc.t) Flow.Statement.While.t) : n_stmt =
  let (n_test_s, n_test) = normalize_expr ~ctx while'.test in
  let n_body_s = normalize_stmt ~ctx while'.body in
  let n_body_s' = n_body_s @ initialize_stmts_leftvalues n_test_s in
  let n_while_s = While.create_stmt n_test n_body_s' @!> loc in
  n_test_s @ [ n_while_s ]

and normalize_dowhile_stmt (ctx : Ctx.t) (loc : Loc.t)
    (dowhile : (Loc.t, Loc.t) Flow.Statement.DoWhile.t) : n_stmt =
  let n_loc = normalize_location loc in
  let tr = Literal.(to_expr @@ boolean true) @> n_loc in
  let n_test_wrp = LeftValue.random () @> n_loc in
  let n_test_wrp' = LeftValue.initialize n_test_wrp in
  let n_test_wrp'' = LeftValue.to_expr n_test_wrp @> n_loc in
  let n_body_s = normalize_stmt ~ctx dowhile.body in
  let (n_test_s, n_test) = normalize_expr ~ctx dowhile.test in
  let n_init_s = Assignment.create_stmt n_test_wrp tr @> n_loc in
  let n_update_s = Assignment.create_stmt n_test_wrp' n_test @> n_loc in
  let n_body_s' = n_body_s @ n_test_s @ [ n_update_s ] in
  let n_while_s = While.create_stmt n_test_wrp'' n_body_s' @> n_loc in
  n_init_s :: [ n_while_s ]

and normalize_for_stmt (ctx : Ctx.t) (loc : Loc.t)
    (for' : (Loc.t, Loc.t) Flow.Statement.For.t) : n_stmt =
  let n_loc = normalize_location loc in
  let tr = Literal.(to_expr @@ boolean true) @> n_loc in
  let n_init_s = normalize_for_init ctx for'.init in
  let (n_test_s, n_test) = normalize_expr_opt ~ctx for'.test in
  let n_body_s = normalize_stmt ~ctx for'.body in
  let (n_updt_s, _) = normalize_expr_opt ~ctx for'.update in
  let n_test' = Option.value ~default:tr n_test in
  let n_body_s' = n_body_s @ n_updt_s @ initialize_stmts_leftvalues n_test_s in
  let n_loop_s = While.create_stmt n_test' n_body_s' @> n_loc in
  n_init_s @ n_test_s @ [ n_loop_s ]

and normalize_for_init (ctx : Ctx.t) :
    (Loc.t, Loc.t) Flow.Statement.For.init option -> n_stmt = function
  | None -> []
  | Some (InitDeclaration (loc, decl)) -> normalize_vdecl_stmt ctx loc decl
  | Some (InitExpression expr) -> fst (normalize_expr ~ctx expr)

and normalize_forin_stmt (ctx : Ctx.t) (loc : Loc.t)
    (forin : (Loc.t, Loc.t) Flow.Statement.ForIn.t) : n_stmt =
  let ctx' = { ctx with curr_stmt = AssignSimple } in
  let left' = FlowUtils.convert_forin_left forin.left in
  let (n_right_s, n_right) = normalize_expr ~ctx forin.right in
  let (n_left_s, n_left) = normalize_for_left ctx' left' in
  let n_body_s = normalize_stmt ~ctx forin.body in
  let n_body_s' = n_left_s @ n_body_s in
  let n_loop_s = ForIn.create_stmt n_left n_right n_body_s' @!> loc in
  n_right_s @ [ n_loop_s ]

and normalize_forof_stmt (ctx : Ctx.t) (loc : Loc.t)
    (forof : (Loc.t, Loc.t) Flow.Statement.ForOf.t) : n_stmt =
  let ctx' = { ctx with curr_stmt = AssignSimple } in
  let left' = FlowUtils.convert_forof_left forof.left in
  let (n_right_s, n_right) = normalize_expr ~ctx forof.right in
  let (n_left_s, n_left) = normalize_for_left ctx' left' in
  let n_body_s = normalize_stmt ~ctx forof.body in
  let n_body_s' = n_left_s @ n_body_s in
  let await = forof.await in
  let n_loop_s = ForOf.create_stmt n_left n_right n_body_s' await @!> loc in
  n_right_s @ [ n_loop_s ]

and normalize_for_left (ctx : Ctx.t) :
    (Loc.t, Loc.t) FlowUtils.for_left -> n_lval = function
  | LeftDeclaration (_, vdecl) ->
    let kind = translate_kind vdecl.kind in
    let ctx' = { ctx with curr_stmt = AssignDecl kind } in
    (* only one var decl is allowed in for-loop lhs *)
    let (_, vdecl') = List.hd vdecl.declarations in
    normalize_for_left ctx' (FlowUtils.LeftPattern vdecl'.id)
  | LeftPattern ((loc, _) as pattern) ->
    let ctx' = { ctx with curr_lval = leftvalue_ctx ctx pattern } in
    let n_loc = normalize_location loc in
    let n_left = get_leftvalue ctx' n_loc in
    let n_left' = LeftValue.to_expr n_left @> n_loc in
    if not (LeftValue.generated n_left) then ([], n_left)
    else
      let n_pattern_s = normalize_assignment_pattern ctx' n_left' pattern in
      (n_pattern_s, n_left)

and normalize_break_stmt (ctx : Ctx.t) (loc : Loc.t)
    (break : Loc.t Flow.Statement.Break.t) : n_stmt =
  let n_label = Option.map (normalize_identifier ctx) break.label in
  [ Break.create_stmt n_label @!> loc ]

and normalize_continue_stmt (ctx : Ctx.t) (loc : Loc.t)
    (break : Loc.t Flow.Statement.Continue.t) : n_stmt =
  let n_label = Option.map (normalize_identifier ctx) break.label in
  [ Continue.create_stmt n_label @!> loc ]

and normalize_return_stmt (ctx : Ctx.t) (loc : Loc.t)
    (return : (Loc.t, Loc.t) Flow.Statement.Return.t) : n_stmt =
  let (n_arg_s, n_arg) = normalize_expr_opt ~ctx return.argument in
  n_arg_s @ [ Return.create_stmt n_arg @!> loc ]

and normalize_throw_stmt (ctx : Ctx.t) (loc : Loc.t)
    (throw : (Loc.t, Loc.t) Flow.Statement.Throw.t) : n_stmt =
  let (n_arg_s, n_arg) = normalize_expr ~ctx throw.argument in
  n_arg_s @ [ Throw.create_stmt n_arg @!> loc ]

and normalize_try_stmt (ctx : Ctx.t) (loc : Loc.t)
    (try' : (Loc.t, Loc.t) Flow.Statement.Try.t) : n_stmt =
  let n_block_s = normalize_block ctx try'.block in
  let n_catch_s = Option.map (normalize_catch ctx) try'.handler in
  let n_finalizer_s = Option.map (normalize_block ctx) try'.finalizer in
  let n_try_s = Try.create_stmt n_block_s n_catch_s n_finalizer_s @!> loc in
  [ n_try_s ]

and normalize_catch (ctx : Ctx.t)
    ((loc, catch) : (Loc.t, Loc.t) Flow.Statement.Try.CatchClause.t) : catch =
  let (n_param_s, n_param) = normalize_catch_param ctx catch.param in
  let n_body_s = normalize_block ctx catch.body in
  Catch.create n_param (n_param_s @ n_body_s) @!> loc

and normalize_catch_param (ctx : Ctx.t) :
    (Loc.t, Loc.t) Flow.Pattern.t option -> stmt list * id option = function
  | None -> ([], None)
  | Some ((loc, _) as pattern) ->
    let ctx' = { ctx with curr_lval = leftvalue_ctx ctx pattern } in
    let n_loc = normalize_location loc in
    let n_param = get_leftvalue ctx' n_loc in
    let n_param' = LeftValue.to_expr n_param @> n_loc in
    let n_param_id = Identifier.of_lval n_param in
    if not (LeftValue.generated n_param) then ([], Some n_param_id)
    else
      let n_pattern_s = normalize_assignment_pattern ctx' n_param' pattern in
      (n_pattern_s, Some n_param_id)

and normalize_with_stmt (ctx : Ctx.t) (loc : Loc.t)
    (with' : (Loc.t, Loc.t) Flow.Statement.With.t) : n_stmt =
  let (n_expr_s, n_expr) = normalize_expr ~ctx with'._object in
  let n_body = normalize_stmt ~ctx with'.body in
  n_expr_s @ [ With.create_stmt n_expr n_body @!> loc ]

and normalize_labeled_stmt (ctx : Ctx.t) (loc : Loc.t)
    (labeled : (Loc.t, Loc.t) Flow.Statement.Labeled.t) : n_stmt =
  let n_label = normalize_identifier ctx labeled.label in
  let n_body = normalize_stmt ~ctx labeled.body in
  [ Labeled.create_stmt n_label n_body @!> loc ]

and normalize_debugger_stmt (_ : Ctx.t) (loc : Loc.t) : n_stmt =
  [ Debugger.create_stmt () @!> loc ]

and normalize_function_decl (ctx : Ctx.t) (loc : Loc.t)
    (func : (Loc.t, Loc.t) Flow.Function.t) : n_stmt =
  (* function declarations must have an identifier *)
  let n_func_id = normalize_identifier ctx (Option.get func.id) in
  normalize_function_decl_with_id ctx loc n_func_id func

and normalize_function_decl_with_id (ctx : Ctx.t) (loc : Loc.t) (n_func_id : id)
    (func : (Loc.t, Loc.t) Flow.Function.t) : n_stmt =
  let ctx' = { ctx with curr_stmt = FuncDecl } in
  let n_loc = normalize_location loc in
  let n_func = LeftValue.of_identifier ~kind:Var n_func_id in
  normalize_function ctx' n_loc func n_func

and normalize_class_decl (ctx : Ctx.t) (loc : Loc.t)
    (class' : (Loc.t, Loc.t) Flow.Class.t) : n_stmt =
  (* class declarations must have an identifier *)
  let n_class_id = normalize_identifier ctx (Option.get class'.id) in
  normalize_class_decl_with_id ctx loc n_class_id class'

and normalize_class_decl_with_id (ctx : Ctx.t) (loc : Loc.t) (n_class_id : id)
    (class' : (Loc.t, Loc.t) Flow.Class.t) : n_stmt =
  let n_loc = normalize_location loc in
  let n_class = LeftValue.of_identifier ~kind:Var n_class_id in
  normalize_class ctx n_loc class' n_class

and normalize_import (ctx : Ctx.t) (loc : Loc.t)
    (import : (Loc.t, Loc.t) Flow.Statement.ImportDeclaration.t) : n_stmt =
  let n_loc = normalize_location loc in
  let n_source = normalize_module_source ctx import.source in
  let n_import_f f = Option.fold ~none:[] ~some:(f ctx n_loc n_source) in
  let n_dflt_s = n_import_f normalize_import_dflt import.default in
  let n_spec_s = n_import_f normalize_import_spec import.specifiers in
  match n_dflt_s @ n_spec_s with
  | [] -> [ ImportDecl.create_stmt None n_source @> n_loc ]
  | n_import_s -> n_import_s

and normalize_import_dflt (ctx : Ctx.t) (n_loc : Region.t) (n_source : string)
    (import : (Loc.t, Loc.t) Flow.Statement.ImportDeclaration.default_identifier)
    : n_stmt =
  let n_id = normalize_identifier ctx import.identifier in
  [ ImportDecl.create_stmt (Default n_id) n_source @> n_loc ]

and normalize_import_spec (ctx : Ctx.t) (n_loc : Region.t) (n_source : string) :
    (Loc.t, Loc.t) Flow.Statement.ImportDeclaration.specifier -> n_stmt =
  function
  | ImportNamespaceSpecifier (_, namespace) ->
    let n_namespace = normalize_identifier ctx namespace in
    [ ImportDecl.create_stmt (Batch n_namespace) n_source @> n_loc ]
  | ImportNamedSpecifiers specifiers ->
    Fun.flip List.map specifiers (function
      | { local = None; remote; _ } ->
        let n_prop = normalize_identifier ctx remote in
        ImportDecl.create_stmt (Property n_prop) n_source @> n_loc
      | { local = Some local'; remote; _ } ->
        let n_prop = normalize_identifier ctx remote in
        let n_alias = normalize_identifier ctx local' in
        ImportDecl.create_stmt (Alias (n_prop, n_alias)) n_source @> n_loc )

and normalize_default_export (ctx : Ctx.t) (loc : Loc.t)
    (export : (Loc.t, Loc.t) Flow.Statement.ExportDefaultDeclaration.t) : n_stmt
    =
  let declaration = export.declaration in
  let (n_decl_s, n_decls) = normalize_export_decl ctx declaration in
  (* default exports must have a single declaration *)
  let n_decl = List.hd n_decls in
  n_decl_s @ [ ExportDecl.create_stmt (Default n_decl) None @!> loc ]

and normalize_named_export (ctx : Ctx.t) (loc : Loc.t)
    (export : (Loc.t, Loc.t) Flow.Statement.ExportNamedDeclaration.t) : n_stmt =
  let n_loc = normalize_location loc in
  let n_source = Option.map (normalize_module_source ctx) export.source in
  let n_export_f f = Option.fold ~none:[] ~some:(f ctx n_loc n_source) in
  let n_dflt_s = n_export_f normalize_named_export_decl export.declaration in
  let n_spec_s = n_export_f normalize_named_export_spec export.specifiers in
  n_dflt_s @ n_spec_s

and normalize_named_export_decl (ctx : Ctx.t) (n_loc : Region.t)
    (n_source : string option) (decl : (Loc.t, Loc.t) Flow.Statement.t) : n_stmt
    =
  let (n_decl_s, n_decls) = normalize_export_decl_stmt ctx decl in
  Fun.(List.append n_decl_s << flip List.filter_map n_decls) (fun n_decl ->
      if Identifier.generated n_decl then None
      else Some (ExportDecl.create_stmt (Property n_decl) n_source @> n_loc) )

and normalize_named_export_spec (ctx : Ctx.t) (n_loc : Region.t)
    (n_source : string option) :
    (Loc.t, Loc.t) Flow.Statement.ExportNamedDeclaration.specifier -> n_stmt =
  function
  | ExportBatchSpecifier (_, namespace) ->
    let n_namespace = Option.map (normalize_identifier ctx) namespace in
    [ ExportDecl.create_stmt (Batch n_namespace) n_source @> n_loc ]
  | ExportSpecifiers specifiers ->
    Fun.flip List.map specifiers (function
      | (_, { local; exported = None }) ->
        let n_prop = normalize_identifier ctx local in
        ExportDecl.create_stmt (Property n_prop) n_source @> n_loc
      | (_, { local; exported = Some exported' }) ->
        let n_prop = normalize_identifier ctx local in
        let n_alias = normalize_identifier ctx exported' in
        ExportDecl.create_stmt (Alias (n_prop, n_alias)) n_source @> n_loc )

and normalize_module_source (_ : Ctx.t)
    ((_, source) : Loc.t * Loc.t Flow.StringLiteral.t) : string =
  source.value

and normalize_export_decl (ctx : Ctx.t)
    (decl : (Loc.t, Loc.t) Flow.Statement.ExportDefaultDeclaration.declaration)
    : n_stmt * expr list =
  let id_to_expr_f lval = Identifier.to_expr lval @> lval.md in
  match decl with
  | Declaration stmt ->
    let (n_stmt_s, n_lvals) = normalize_export_decl_stmt ctx stmt in
    (n_stmt_s, List.map id_to_expr_f n_lvals)
  | Expression expr ->
    let (n_expr_s, n_expr) = normalize_expr expr in
    (n_expr_s, [ n_expr ])

and normalize_export_decl_stmt (ctx : Ctx.t) :
    (Loc.t, Loc.t) Flow.Statement.t -> n_stmt * id list = function
  | (loc, VariableDeclaration vdecl) ->
    let n_stmts = normalize_vdecl_stmt ctx loc vdecl in
    let n_lvals = get_stmts_leftvalues n_stmts in
    (n_stmts, List.map Identifier.of_lval n_lvals)
  | (loc, FunctionDeclaration ({ id; _ } as func)) ->
    let n_id = normalize_identifier_opt ctx loc id in
    (normalize_function_decl_with_id ctx loc n_id func, [ n_id ])
  | (loc, ClassDeclaration ({ id; _ } as class')) ->
    let n_id = normalize_identifier_opt ctx loc id in
    (normalize_class_decl_with_id ctx loc n_id class', [ n_id ])
  | _ -> Log.fail "invalid declaration statement in export"

and normalize_stmt ?(ctx : Ctx.t = Ctx.default ())
    (stmt : (Loc.t, Loc.t) Flow.Statement.t) : n_stmt =
  match stmt with
  | (_, Empty _) -> []
  | (loc, Block block) -> normalize_block_stmt ctx loc block
  | (loc, Expression expr) -> normalize_expr_stmt ctx loc expr
  | (loc, VariableDeclaration vdecl) -> normalize_vdecl_stmt ctx loc vdecl
  | (loc, If if') -> normalize_if_stmt ctx loc if'
  | (loc, Switch switch) -> normalize_switch_stmt ctx loc switch
  | (loc, While while') -> normalize_while_stmt ctx loc while'
  | (loc, DoWhile dowhile) -> normalize_dowhile_stmt ctx loc dowhile
  | (loc, For for') -> normalize_for_stmt ctx loc for'
  | (loc, ForIn forin) -> normalize_forin_stmt ctx loc forin
  | (loc, ForOf forof) -> normalize_forof_stmt ctx loc forof
  | (loc, Break break) -> normalize_break_stmt ctx loc break
  | (loc, Continue continue) -> normalize_continue_stmt ctx loc continue
  | (loc, Return return) -> normalize_return_stmt ctx loc return
  | (loc, Throw throw) -> normalize_throw_stmt ctx loc throw
  | (loc, Try try') -> normalize_try_stmt ctx loc try'
  | (loc, With with') -> normalize_with_stmt ctx loc with'
  | (loc, Labeled labeled) -> normalize_labeled_stmt ctx loc labeled
  | (loc, Debugger _) -> normalize_debugger_stmt ctx loc
  | (loc, FunctionDeclaration func) -> normalize_function_decl ctx loc func
  | (loc, ClassDeclaration class') -> normalize_class_decl ctx loc class'
  | (loc, ImportDeclaration import) -> normalize_import ctx loc import
  | (loc, ExportDefaultDeclaration export) ->
    normalize_default_export ctx loc export
  | (loc, ExportNamedDeclaration export) ->
    normalize_named_export ctx loc export
  | (_, TypeAlias _)
  | (_, OpaqueType _)
  | (_, EnumDeclaration _)
  | (_, InterfaceDeclaration _) ->
    Log.fail "[not implemented]: TS statements"
  | (_, ComponentDeclaration _) ->
    Log.fail "[not implemented]: React statements"
  | (_, DeclareComponent _)
  | (_, DeclareVariable _)
  | (_, DeclareFunction _)
  | (_, DeclareModule _)
  | (_, DeclareModuleExports _)
  | (_, DeclareExportDeclaration _)
  | (_, DeclareClass _)
  | (_, DeclareTypeAlias _)
  | (_, DeclareOpaqueType _)
  | (_, DeclareEnum _)
  | (_, DeclareInterface _)
  | (_, DeclareNamespace _) ->
    Log.fail "[not implemented]: TypeScript declaration statements"

and normalize_alias_wrapper (ctx : Ctx.t) (n_loc : Region.t)
    (wrapped_f : lval -> n_stmt) (n_left : lval)
    (alias : (Loc.t, Loc.t) Flow.Identifier.t option) : n_stmt =
  (* TODO[flag]: disable function/class aliases  *)
  match alias with
  | None -> wrapped_f n_left
  | Some alias ->
    let n_alias_id = normalize_identifier ctx alias in
    let n_alias = LeftValue.of_identifier ~kind:Let n_alias_id in
    let n_alias' = LeftValue.to_expr n_alias @> n_loc in
    let n_wrapped_s = wrapped_f n_alias in
    let n_return_s = Return.create_stmt (Some n_alias') @> n_loc in
    let n_wrapper = LeftValue.random () @> n_loc in
    let n_wrapper_id = Identifier.of_lval n_wrapper in
    let n_body_s = n_wrapped_s @ [ n_return_s ] in
    [ create_function ctx n_wrapper [] n_body_s false false @> n_loc
    ; FunctionCall.create_stmt n_left n_wrapper_id [] @> n_loc ]

and normalize_function (ctx : Ctx.t) (n_loc : Region.t)
    (func : (Loc.t, Loc.t) Flow.Function.t) (n_left : lval) : n_stmt =
  let (n_params_s, n_params) = normalize_function_param_list ctx func.params in
  let n_body_s = normalize_function_body ctx func.body in
  let n_body_s' = List.flatten n_params_s @ n_body_s in
  let (async, generator) = (func.async, func.generator) in
  [ create_function ctx n_left n_params n_body_s' async generator @> n_loc ]

and normalize_function_param_list (ctx : Ctx.t)
    ((_, params) : (Loc.t, Loc.t) Flow.Function.Params.t) :
    n_stmt list * id list =
  let n_params = List.map (normalize_function_param ctx) params.params in
  (* TODO: implement normalization of the rest parameter *)
  (* let n_rest = Option.map (normalize_function_rest_param ctx) params.rest in *)
  let n_rest = None in
  List.split (n_params @ Option.to_list n_rest)

and normalize_function_param (ctx : Ctx.t)
    ((loc, param) : (Loc.t, Loc.t) Flow.Function.Param.t) : n_id =
  let n_loc = normalize_location loc in
  let ctx' = { ctx with curr_lval = leftvalue_ctx ctx param.argument } in
  let n_param = get_leftvalue ctx' n_loc in
  let n_param' = LeftValue.to_expr n_param @> n_loc in
  let n_param_id = Identifier.of_lval n_param in
  let normalize_dflt_f = normalize_default_value n_param in
  let n_dflt_s = Option.fold ~none:[] ~some:normalize_dflt_f param.default in
  if n_param.el.id.generated == false then (n_dflt_s, n_param_id)
  else
    let n_pattern_s = normalize_assignment_pattern ctx n_param' param.argument in
    (n_dflt_s @ n_pattern_s, n_param_id)

and normalize_function_rest_param (_ : Ctx.t)
    (_ : ('M, 'T) Flow_ast.Function.RestParam.t) : n_id =
  Log.fail "[not implemented]: rest param"

and normalize_function_body (_ : Ctx.t)
    (body : (Loc.t, Loc.t) Flow.Function.body) : n_stmt =
  match body with
  | Flow.Function.BodyBlock (loc, block) -> normalize_stmt (loc, Block block)
  | Flow.Function.BodyExpression ((loc, _) as body_expr) ->
    let (n_body_s, n_body) = normalize_expr body_expr in
    let n_return_s = Return.create_stmt (Some n_body) @!> loc in
    n_body_s @ [ n_return_s ]

and normalize_class (ctx : Ctx.t) (n_loc : Region.t)
    (class' : (Loc.t, Loc.t) Flow.Class.t) (n_left : lval) : n_stmt =
  let ctx' = { ctx with curr_lval = Some n_left } in
  let ext = Option.is_some class'.extends in
  let (n_cons_s, n_proto) =
    process_class_constructor ctx' n_loc ext class'.body in
  let ctx'' = { ctx' with curr_proto = Some n_proto } in
  let n_extends_f = normalize_class_extends ctx'' in
  let n_extends_s = Option.fold ~none:[] ~some:n_extends_f class'.extends in
  let n_body_s = normalize_class_body ctx'' class'.body in
  n_cons_s @ n_extends_s @ n_body_s

and normalize_class_extends (ctx : Ctx.t)
    ((loc, extends) : (Loc.t, Loc.t) Flow.Class.Extends.t) : n_stmt =
  let n_loc = normalize_location loc in
  let (n_class, n_proto) = get_class_ctx ctx in
  let n_class' = LeftValue.to_expr n_class @> n_loc in
  let n_proto' = LeftValue.to_expr n_proto @> n_loc in
  let (n_extends_s, n_extends) = normalize_expr extends.expr in
  let n_parent = LeftValue.random () @> n_loc in
  let n_parent' = LeftValue.to_expr n_parent @> n_loc in
  let p_proto = Static (Prop.IProp (Identifier.create "__proto__") @> n_loc) in
  let p_prttyp = Static (Prop.IProp (Identifier.create "prototype") @> n_loc) in
  let n_class_s = update_property n_class' p_proto n_extends @> n_loc in
  let n_parent_s = lookup_property n_parent n_extends p_prttyp @> n_loc in
  let n_proto_s = update_property n_proto' p_proto n_parent' @> n_loc in
  n_extends_s @ [ n_parent_s; n_class_s; n_proto_s ]

and normalize_class_body (ctx : Ctx.t)
    ((_, body) : (Loc.t, Loc.t) Flow.Class.Body.t) : n_stmt =
  Fun.(List.flatten << flip List.map body.body) (function
    | Method (_, { kind = Constructor; _ }) -> [] (* handled seperatly *)
    | Method (loc, { kind = Method; static; key; value = func; _ }) ->
      normalize_class_method ctx loc static key func
    | Method (loc, { kind = Get; static; key; value; _ }) ->
      normalize_class_getter_setter ctx loc "get" static key value
    | Method (loc, { kind = Set; static; key; value; _ }) ->
      normalize_class_getter_setter ctx loc "set" static key value
    | Property (loc, { static; key; value; _ }) ->
      normalize_class_property ctx loc static key value
    | PrivateField _ -> Log.fail "[not implemented]: private class element" )

and process_class_constructor (ctx : Ctx.t) (n_loc : Region.t) (ext : bool)
    ((_, body) : (Loc.t, Loc.t) Flow.Class.Body.t) : n_lval =
  match List.find_opt is_class_constuctor body.body with
  | Some (Method (_, { kind = Constructor; value = (loc, func); _ })) ->
    normalize_class_constructor ctx loc func
  | _ -> normalize_class_dflt_constructor ctx n_loc ext

and is_class_constuctor : (Loc.t, Loc.t) Flow.Class.Body.element -> bool =
  function
  | Method (_, { kind = Constructor; _ }) -> true
  | _ -> false

and normalize_class_prototype (_ : Ctx.t) (n_loc : Region.t) (n_class : lval) :
    n_lval =
  let n_proto = LeftValue.random () @> n_loc in
  let n_class' = LeftValue.to_expr n_class @> n_loc in
  let p_prtt = Prop.IProp (Identifier.create "prototype") @> n_loc in
  let n_proto_s = lookup_property n_proto n_class' (Static p_prtt) @> n_loc in
  ([ n_proto_s ], n_proto)

and normalize_class_dflt_constructor (ctx : Ctx.t) (n_loc : Region.t)
    (ext : bool) : n_lval =
  let n_class = get_leftvalue ctx n_loc in
  let n_class' = LeftValue.to_expr n_class @> n_loc in
  let n_body = if ext then normalize_class_ext_body ctx n_loc else [] in
  let p_cons = Prop.IProp (Identifier.create "constructor") @> n_loc in
  let n_func_s = create_function ctx n_class [] n_body false false @> n_loc in
  let (n_proto_s, n_proto) = normalize_class_prototype ctx n_loc n_class in
  let n_proto' = LeftValue.to_expr n_proto @> n_loc in
  let n_cons_s = update_property n_proto' (Static p_cons) n_class' @> n_loc in
  ((n_func_s :: n_proto_s) @ [ n_cons_s ], n_proto)

and normalize_class_ext_body (ctx : Ctx.t) (n_loc : Region.t) : n_stmt =
  let (n_obj_s, n_obj) = normalize_super_expr ctx Loc.none in
  let p_cons = Prop.IProp (Identifier.create "constructor") @> n_loc in
  let n_left = LeftValue.random () @> n_loc in
  let n_call_s = call_property n_left n_obj (Static p_cons) [] @> n_loc in
  n_obj_s @ [ n_call_s ]

and normalize_class_constructor (ctx : Ctx.t) (loc : Loc.t)
    (func : (Loc.t, Loc.t) Flow.Function.t) : n_lval =
  let n_loc = normalize_location loc in
  let n_class = get_leftvalue ctx n_loc in
  let n_class' = LeftValue.to_expr n_class @> n_loc in
  let p_cons = Prop.IProp (Identifier.create "constructor") @> n_loc in
  let n_func_s = normalize_function ctx n_loc func n_class in
  let (n_proto_s, n_proto) = normalize_class_prototype ctx n_loc n_class in
  let n_proto' = LeftValue.to_expr n_proto @> n_loc in
  let n_cons_s = update_property n_proto' (Static p_cons) n_class' @> n_loc in
  (n_func_s @ n_proto_s @ [ n_cons_s ], n_proto)

and normalize_class_method (ctx : Ctx.t) (loc : Loc.t) (static : bool)
    (key : (Loc.t, Loc.t) Flow.Expression.Object.Property.key)
    ((func_loc, func) : Loc.t * (Loc.t, Loc.t) Flow.Function.t) : n_stmt =
  let n_loc = normalize_location loc in
  let ctx' = { ctx with curr_lval = leftvalue_ctx_random n_loc } in
  let n_left = get_class_leftvalue ctx static in
  let n_left' = LeftValue.to_expr n_left @> n_loc in
  let (n_key_s, n_key) = normalize_property_key ctx key in
  let (n_func_s, n_func) = normalize_function_expression ctx' func_loc func in
  let n_method_s = update_property n_left' n_key n_func @> n_loc in
  n_key_s @ n_func_s @ [ n_method_s ]

and normalize_class_getter_setter (ctx : Ctx.t) (loc : Loc.t) (kind : string)
    (static : bool) (key : (Loc.t, Loc.t) Flow.Expression.Object.Property.key)
    ((func_loc, func) : Loc.t * (Loc.t, Loc.t) Flow.Function.t) : n_stmt =
  let n_loc = normalize_location loc in
  let ctx' = { ctx with curr_lval = leftvalue_ctx_random n_loc } in
  let n_left = get_class_leftvalue ctx static in
  let n_left' = LeftValue.to_expr n_left @> n_loc in
  let (n_key_s, n_key) = normalize_property_key ctx key in
  let (n_func_s, n_func) = normalize_function_expression ctx' func_loc func in
  let (n_wrp_s, n_wrp) = normalize_getter_setter_wrapper ctx n_loc kind n_func in
  let n_defprop_s = normalize_define_property ctx n_loc n_left' n_key n_wrp in
  n_key_s @ n_func_s @ n_wrp_s @ n_defprop_s

and normalize_class_property (ctx : Ctx.t) (loc : Loc.t) (static : bool)
    (key : (Loc.t, Loc.t) Flow.Expression.Object.Property.key)
    (value : (Loc.t, Loc.t) Flow.Class.Property.value) : n_stmt =
  let n_loc = normalize_location loc in
  let n_left = get_class_leftvalue ctx static in
  let n_left' = LeftValue.to_expr n_left @> n_loc in
  let (n_key_s, n_key) = normalize_property_key ctx key in
  let (n_func_s, n_func) = normalize_class_property_value ctx n_loc value in
  let n_prop_s = update_property n_left' n_key n_func @> n_loc in
  n_key_s @ n_func_s @ [ n_prop_s ]

and normalize_class_property_value (_ : Ctx.t) (n_loc : Region.t) :
    (Loc.t, Loc.t) Flow.Class.Property.value -> n_expr = function
  | Declared | Uninitialized -> ([], Identifier.undefined_expr () @> n_loc)
  | Initialized expr -> normalize_expr expr

and normalize_file (file : (Loc.t, Loc.t) Flow_ast.Program.t) : n_stmt =
  let (_, { Flow.Program.statements; _ }) = file in
  List.map normalize_stmt statements |> List.flatten

and translate_unary (op : Flow.Expression.Unary.operator) : Operator.unary =
  match op with
  | Plus -> Plus
  | Minus -> Minus
  | BitNot -> BitwiseNot
  | Not -> LogicalNot
  | Typeof -> Typeof
  | Void -> Void
  | Await -> Await
  | Delete -> Delete

and translate_binary (op : Flow.Expression.Binary.operator) : Operator.binary =
  match op with
  | Plus -> Plus
  | Minus -> Minus
  | Mult -> Mult
  | Div -> Div
  | Mod -> Mod
  | Exp -> Exp
  | BitAnd -> BitwiseAnd
  | BitOr -> BitwiseOr
  | Xor -> BitwiseXor
  | LShift -> ShiftLeft
  | RShift -> ShiftRight
  | RShift3 -> ShiftRightLogical
  | Equal -> Equal
  | NotEqual -> NotEqual
  | StrictEqual -> StrictEqual
  | StrictNotEqual -> StrictNotEqual
  | LessThan -> LessThan
  | LessThanEqual -> LessThanEqual
  | GreaterThan -> GreaterThan
  | GreaterThanEqual -> GreaterThanEqual
  | Instanceof -> Instanceof
  | In -> In

and translate_update (op : Flow.Expression.Update.operator) : Operator.binary =
  match op with Increment -> Plus | Decrement -> Minus

and translate_asgnopt (op : Flow.Expression.Assignment.operator) :
    Operator.binary =
  match op with
  | PlusAssign -> Plus
  | MinusAssign -> Minus
  | MultAssign -> Mult
  | DivAssign -> Div
  | ModAssign -> Mod
  | ExpAssign -> Exp
  | BitAndAssign -> BitwiseAnd
  | BitOrAssign -> BitwiseOr
  | BitXorAssign -> BitwiseXor
  | LShiftAssign -> ShiftLeft
  | RShiftAssign -> ShiftRight
  | RShift3Assign -> ShiftRightLogical
  | AndAssign -> LogicalAnd
  | OrAssign -> LogicalOr
  | NullishAssign -> NullishCoalesce

and translate_kind (kind : Flow.Variable.kind) : LeftValueKind.t =
  match kind with Var -> Var | Let -> Let | Const -> Const

and translate_property_key
    (key : (Loc.t, Loc.t) Flow.Pattern.Object.Property.key) :
    (Loc.t, Loc.t) Flow.Expression.Object.Property.key =
  match key with
  | Identifier id -> Identifier id
  | StringLiteral literal -> StringLiteral literal
  | NumberLiteral literal -> NumberLiteral literal
  | BigIntLiteral literal -> BigIntLiteral literal
  | Computed computed -> Computed computed

and requires_expr_stmt (expr : (Loc.t, Loc.t) Flow.Expression.t) : bool =
  match expr with
  | (_, NullLiteral _)
  | (_, StringLiteral _)
  | (_, NumberLiteral _)
  | (_, BigIntLiteral _)
  | (_, BooleanLiteral _)
  | (_, RegExpLiteral _)
  | (_, TemplateLiteral _)
  | (_, ModuleRefLiteral _)
  | (_, Identifier _)
  | (_, This _)
  | (_, Super _)
  | (_, Sequence _)
  | (_, Object _)
  | (_, Array _)
  | (_, Unary _)
  | (_, Binary _)
  | (_, Logical _)
  | (_, Update _)
  | (_, Conditional _)
  | (_, Member _)
  | (_, OptionalMember _)
  | (_, MetaProperty _)
  | (_, TypeCast _)
  | (_, TSSatisfies _)
  | (_, AsConstExpression _)
  | (_, AsExpression _) ->
    true
  | (_, Assignment _)
  | (_, Yield _)
  | (_, New _)
  | (_, Call _)
  | (_, OptionalCall _)
  | (_, TaggedTemplate _)
  | (_, Function _)
  | (_, ArrowFunction _)
  | (_, Class _)
  | (_, Import _)
  | (_, JSXElement _)
  | (_, JSXFragment _) ->
    false
