module Ast = Flow_ast
open GraphJS
open Aux

(* --------- A L I A S E S --------- *)
type m = Location.t;;
type norm_stmt_t = m Statement.t list;;
type norm_expr_t = m Statement.t list * m Expression.t option;;

let loc_f = Location.convert_flow_loc;;
let _const = Statement.VarDecl.Const;;
let _let = Statement.VarDecl.Let;;
let _var = Statement.VarDecl.Var;;
let _init = Statement.AssignObject.Property.Init;;
let _method = Statement.AssignObject.Property.Method;;
let _get = Statement.AssignObject.Property.Get;;
let _set = Statement.AssignObject.Property.Set;;

type name_or_id =
  | Name of string option
  | Id   of m Identifier.t


(* --------- C O N T E X T --------- *)
type context = { 
  identifier : m Identifier.t option;
  is_assignment : bool
}
let empty_context : context = { identifier = None; is_assignment = false } 

let rec normalize (loc , { Ast.Program.statements; _ }) : m Program.t = 
  let statements' = List.flatten (List.map (normalize_statement empty_context) statements) in
  let program' = Program.build (loc_f loc) statements' in 
  program'

and normalize_statement (context : context) (stmt : ('M, 'T) Ast.Statement.t) : norm_stmt_t =
  let ns  = normalize_statement empty_context in
  let ne  = normalize_expression empty_context in
  let nec  = normalize_expression in

  match stmt with
    (* --------- B L O C K --------- *)
    | _, Ast.Statement.Block {body; _} -> 
      let body_stmts = List.map ns body in
      List.flatten body_stmts;
    
    (* --------- I F --------- *)
    | loc, Ast.Statement.If {test; consequent; alternate; _} ->
      let test_stmts, test_expr = ne test in
      let cons_stmts = ns consequent in
      let altn_stmts = Option.map normalize_alternate alternate in
      let if_stmt = Statement.If.build (loc_f loc) (Option.get test_expr) cons_stmts altn_stmts in
      
      test_stmts @ [if_stmt]
    
    (* --------- W H I L E --------- *)
    | loc, Ast.Statement.While { test; body; _ } -> 
      let test_stmts, test_expr = ne test in
      let body_stmts = ns body in
      let while_stmt= Statement.While.build (loc_f loc) (Option.get test_expr) body_stmts in

      (* TODO : normWhileStatement performs some computations over the norm_test.statements *)
      (test_stmts @ [while_stmt])
    
    | loc, Ast.Statement.DoWhile {body; test; _} ->
      let loc = loc_f loc in 
      let test_stmts, test_expr = ne test in 
      let body_stmts = ns body in
      
      let true_val = Expression.Literal.build loc (Expression.Literal.Boolean true) "true" in 
      let setup, update, test_expr = if test_stmts = [] 
        then
          (* simple test expression: false, 1, x, ...*)
          let id, decl = createVariableDeclaration (Some true_val) loc ~kind:_let in
          let update = Statement.AssignSimple.build loc None id (Option.get test_expr) in 
          decl, [update], Identifier.to_expression id 
        else
          (* complex test expression that was reduced to an identifier *)
          let test_expr = Option.get test_expr in
          let decls, assings = List.partition is_declaration test_stmts in
          let setup = Statement.AssignSimple.build loc None (Identifier.from_expression test_expr) true_val in 
          List.map (change_kind _let) decls @ [setup], assings, test_expr 
      in

      let while_stmt = Statement.While.build loc test_expr (body_stmts @ update) in 
      setup @ [while_stmt]
    
    (* | loc, Ast.Statement.For {init; test; update; body} -> 
      let loc = loc_f loc in 
      let true_val = Expression.Literal.build loc (Expression.Literal.Boolean true) "true" in 


      let test_stmts, test_expr = map_default ne ([], Some true_val) test in 
      let updt_stmts, updt_expr = map_default ne ([], None) update in 
      let body_stmts = ns body in 

      [] *)
    
        
    (* --------- S W I T C H --------- *)
    | loc, Ast.Statement.Switch  { discriminant; cases; _ } -> 
      let dicr_stmts, dicr_expr = ne discriminant in 
      (* normalize cases *)
      let cases', tests_stmts = List.split (List.map normalize_case cases) in
      let switch_stmt = Statement.Switch.build (loc_f loc) (Option.get dicr_expr) cases' in

      (* statements generated from the normalization of the 
         discriminant and the test expression of each case*)
      let previous_stmts = dicr_stmts @ List.flatten tests_stmts in
      previous_stmts @ [switch_stmt]
    
    (* --------- T R Y - C A T C H --------- *)
    | loc, Ast.Statement.Try {block; handler; finalizer; _} -> 
      let block_stmts = ns (block_to_statement block) in
      let fnlzr_stmts = Option.map (ns << block_to_statement) finalizer in

      (* process catch clause *)
      let handler_stmts, handler' = map_default normalize_catch ([], None) handler in
    
      (* build try statement*)
      let try_stmt = Statement.Try.build (loc_f loc) block_stmts handler' fnlzr_stmts in

      handler_stmts @ [try_stmt]

    (* --------- V A R I A B L E   D E C L A R A T I O N --------- *)
    | _, Ast.Statement.VariableDeclaration {kind; declarations; _} ->
      let kind' : Statement.VarDecl.kind = match kind with 
        | Var -> _var  | Let -> _let  | Const -> _const 
      in

      let unpattern_decls = List.flatten (List.map unpattern declarations) in
      let decl_stmts = List.map (fun (loc, id, init) -> 
        let decl_context = {identifier = Some id; is_assignment = true} in 
        let init_stmt, init_expr = map_default (nec decl_context) ([], None) init in 
        (* if it is an special assignment dont do the assignment twice *)
        let init_expr = if (is_special_assignment (Option.get init)) then None else init_expr in 

        let _, decl = createVariableDeclaration init_expr loc ~objId:(Id id) ~kind:kind' in     
        decl @ init_stmt

      ) unpattern_decls in 

      List.flatten decl_stmts
    
    (* --------- R E T U R N --------- *)
    | loc, Ast.Statement.Return {argument; _} -> 
      let arg_stmts, arg_expr = map_default ne ([], None) argument in
      let return_stmt = Statement.Return.build (loc_f loc) arg_expr in 

      arg_stmts @ [return_stmt]

      (* --------- T H R O W --------- *)
      | loc, Ast.Statement.Throw {argument; _} -> 
        let arg_stmts, arg_expr = ne argument in
        let throw_stmt = Statement.Throw.build (loc_f loc) arg_expr in 
  
        arg_stmts @ [throw_stmt]
    
    (* --------- A S S I G N   F U N C T I O N ---------*)
    | loc, Ast.Statement.FunctionDeclaration {id; params; body; _} -> fst (normalize_function context loc id params body)
    
    | _, Ast.Statement.Expression {expression; _} -> 
      (* TODO : graph.js appends expression result if any to the return *)
      let stmts, expr = ne expression in 
      stmts @ Option.to_list (Option.map Expression.to_statement expr)
            
    | loc, _ -> 
      let loc_info = Loc.debug_to_string loc in
      failwith ("Unknown statement type to normalize (object on " ^ loc_info ^ ")")
    
and normalize_expression (context : context) (expr : ('M, 'T) Ast.Expression.t) : norm_expr_t =
  let nec = normalize_expression in 
  let ne = normalize_expression empty_context in 
  match expr with
  (* --------- L I T E R A L --------- *)
  | loc, Ast.Expression.StringLiteral {value; raw; _} -> 
    let value' = Expression.Literal.String value in 
    let literal = Expression.Literal.build (loc_f loc) value' raw in 
    ([], Some literal);

  | loc, Ast.Expression.NumberLiteral {value; raw; _} -> 
    let value' = Expression.Literal.Number value in 
    let literal = Expression.Literal.build (loc_f loc) value' raw in 
    ([], Some literal);

  | loc, Ast.Expression.BigIntLiteral {value; raw; _} -> 
    let value = Expression.Literal.BigInt value in 
    let literal = Expression.Literal.build (loc_f loc) value raw in 
    ([], Some literal);

  | loc, Ast.Expression.BooleanLiteral {value; _} -> 
    let value' = Expression.Literal.Boolean value in 
    let raw = if value then "true" else "false" in 
    let literal = Expression.Literal.build (loc_f loc) value' raw in 
    ([], Some literal);

  | loc, Ast.Expression.NullLiteral _ -> 
    let value = Expression.Literal.Null () in
    let literal = Expression.Literal.build (loc_f loc) value "null" in
    ([], Some literal);
  
  (* --------- T E M P L A T E    L I T E R A L --------- *)
  | loc, Ast.Expression.TemplateLiteral {quasis; expressions; _} -> 
    let quasis' = List.map build_template_element quasis in 
    let stmts, exprs = List.split (List.map ne expressions) in
    let exprs = List.map Option.get exprs in 

    (* TODO : some applications based on the parent *)
    let literal = Expression.TemplateLiteral.build (loc_f loc) quasis' exprs in
    (List.flatten stmts, Some literal)

  (* --------- I D E N T I F I E R --------- *)
  | _, Ast.Expression.Identifier (loc, { name; _ }) -> 
    let location = loc_f loc in
    let identifier = Identifier.to_expression (Identifier.build location name) in 
    ([], Some identifier)

  (* --------- L O G I C A L --------- *)
  | loc, Ast.Expression.Logical {operator; left; right; _} -> 
    let operator' = Operator.Logical.translate operator in
    let left_stmt, left_expr = ne left in  
    let right_stmt, right_expr = ne right in  

    let location = loc_f loc in
    let logical = Expression.Logical.build location operator' (Option.get left_expr) (Option.get right_expr) in 
    
    if not context.is_assignment then
      let id, decl = createVariableDeclaration (Some logical) location in 
      (left_stmt @ right_stmt @ decl, Some (Identifier.to_expression id))
    else 
      (left_stmt @ right_stmt, Some logical)
  
  (* --------- B I N A R Y --------- *)
  | loc, Ast.Expression.Binary {operator; left; right; _} -> 
    let operator' = Operator.Binary.translate operator in
    let left_stmt, left_expr = ne left in  
    let right_stmt, right_expr = ne right in  

    let location = loc_f loc in
    let binary = Expression.Binary.build location operator' (Option.get left_expr) (Option.get right_expr) in 
    
    if not context.is_assignment then
      let id, decl = createVariableDeclaration (Some binary) location in 
      (left_stmt @ right_stmt @ decl, Some (Identifier.to_expression id))
    else 
      (left_stmt @ right_stmt, Some binary)
  
  (* --------- U N A R Y --------- *)
  | loc, Ast.Expression.Unary {operator; argument; _} -> 
    let operator' = Operator.Unary.translate operator in 
    let arg_stmts, arg_expr = ne argument in

    let location = loc_f loc in
    let unary_expr = Expression.Unary.build location operator' (Option.get arg_expr) in 
    
    if not context.is_assignment then
      let id, decl = createVariableDeclaration (Some unary_expr) location in 
      (arg_stmts @ decl, Some (Identifier.to_expression id))
    else 
      (arg_stmts, Some unary_expr)
  
  (* --------- U P D A T E --------- *)
  | loc, Ast.Expression.Update {operator; argument; prefix; _} -> 
    let operator' = Operator.Update.translate operator in
    let arg_stmts, arg_expr = ne argument in 

    let location = loc_f loc in
    let update_expr = Expression.Update.build location operator' (Option.get arg_expr) prefix in 
    
    if not context.is_assignment then
      let id, decl = createVariableDeclaration (Some update_expr) location in 
      (arg_stmts @ decl, Some (Identifier.to_expression id))
    else 
      (arg_stmts, Some update_expr)

  (* --------- T H I S --------- *)
  | loc, Ast.Expression.This _ -> 
    let this = Expression.This.build (loc_f loc) in
    ([], Some this)

  (* --------- S U P E R --------- *)
  | loc, Ast.Expression.Super _ -> 
    let super = Expression.Super.build (loc_f loc) in
    ([], Some super)
  
  (* --------- A S S I G N   S I M P L E --------- *)
  | loc, Ast.Expression.Assignment {operator; left; right; _} ->
    let left' = normalize_pattern left in 
    let assign_context = {identifier = Some left'; is_assignment = true} in 

    let operator' = Option.map Operator.Assignment.translate operator in
    let right_stmts, right_expr = nec assign_context right in

    let assign_expr = if not (is_special_assignment right) 
          then Some (Statement.AssignSimple.build (loc_f loc) operator' left' (Option.get right_expr)) 
          else None in
          
    (* TODO : graph.js normalizer has some special cases depending on the parent *)
    (right_stmts @ Option.to_list assign_expr, None)

  (* --------- A S S I G N   A R R A Y ---------*)
  | loc, Ast.Expression.Array {elements; _} -> 
    let elems_stmts, elems_exprs = List.split (List.map normalize_array_elem elements) in 
    let elems_exprs = List.map Option.get (List.filter Option.is_some elems_exprs) in 

    let loc = loc_f loc in
    let id = get_identifier context.identifier loc in
    let assign = Statement.AssignArray.build loc id elems_exprs in
    
    (* TODO : arrayExpression keeps array as element if the parent is an expression statement *)
    if not context.is_assignment then 
      let _, decl = createVariableDeclaration None loc ~objId:(Id id) in 
      ((List.flatten elems_stmts) @ decl @ [assign] , Some (Identifier.to_expression id))
    else
      (List.flatten elems_stmts) @ [assign], Some (Identifier.to_expression id)
  
  (* --------- A S S I G N   N E W ---------*)
  | loc, Ast.Expression.New {callee; arguments; _} -> 
    let callee_stmts, callee_expr = ne callee in
    let args_stmts, args_exprs = List.split (map_default normalize_argument_list [] arguments) in 
    let args_exprs = List.flatten (List.map Option.to_list args_exprs) in

    let loc = loc_f loc in
    let id = get_identifier context.identifier loc in
    let assign = Statement.AssignNew.build loc id (Option.get callee_expr) args_exprs in

    if not context.is_assignment then
      let _, decl = createVariableDeclaration None loc ~objId:(Id id) in
      (callee_stmts @ (List.flatten args_stmts) @ decl @ [assign] , Some (Identifier.to_expression id))
    else
      (callee_stmts @ (List.flatten args_stmts) @ [assign], Some (Identifier.to_expression id))

  (* --------- A S S I G N   M E M B E R ---------*)
  | loc, Ast.Expression.Member {_object; property; _} -> 
    let obj_stmts, obj_expr = ne _object in 
    let prop_stmts, prop_expr = normalize_member_property property in 

    let loc = loc_f loc in
    let id = get_identifier context.identifier loc in
    let assign = Statement.AssignMember.build loc id (Option.get obj_expr) (Option.get prop_expr) in

    (* TODO : it has some more restrictions more than being an assignment, like is function call and new expression *)
    if not context.is_assignment then
      let _, decl = createVariableDeclaration None loc ~objId:(Id id) in
      (obj_stmts @ prop_stmts @ decl @ [assign] , Some (Identifier.to_expression id))
    else
      (obj_stmts @ prop_stmts @ [assign], Some (Identifier.to_expression id))

  (* --------- A S S I G N   O B J E C T ---------*)
  | loc, Ast.Expression.Object {properties; _} -> 
      let props_stmts, proprs_exprs = List.split (List.map normalize_property properties) in 
      
      let loc = loc_f loc in
      let id = get_identifier context.identifier loc in
      let assign = Statement.AssignObject.build loc id proprs_exprs in

      if not context.is_assignment then
        let _, decl = createVariableDeclaration None loc ~objId:(Id id) in
        (List.flatten props_stmts @ decl @ [assign] , Some (Identifier.to_expression id))
      else
        (List.flatten props_stmts @ [assign], Some (Identifier.to_expression id))

  (* --------- A S S I G N   F U N C   C A L L ---------*)
  | loc, Ast.Expression.Call {callee; arguments; _} -> 
    let callee_stmts, callee_expr = ne callee in
    let args_stmts, args_exprs = List.split (normalize_argument_list arguments) in 
    let args_exprs = List.flatten (List.map Option.to_list args_exprs) in

    let loc = loc_f loc in
    let id = get_identifier context.identifier loc in
    let assign = Statement.AssignFunCall.build loc id (Option.get callee_expr) args_exprs in

    if not context.is_assignment then
      let _, decl = createVariableDeclaration None loc ~objId:(Id id) in
      (callee_stmts @ (List.flatten args_stmts) @ decl @ [assign] , Some (Identifier.to_expression id))
    else 
      (callee_stmts @ (List.flatten args_stmts) @ [assign], Some (Identifier.to_expression id))

  (* --------- A S S I G N   F U N C T I O N ---------*)
  | loc, Ast.Expression.ArrowFunction {id; params; body; _} -> 
    (* TODO : graph.js checks parent type to see if function should or not be put into an assignment*)
    normalize_function context loc id params body
  | loc, Ast.Expression.Function {id; params; body; _} -> 
    (* TODO : graph.js checks parent type to see if function should or not be put into an assignment*)
    normalize_function context loc id params body
  
  | loc, _ -> 
    let loc_info = Loc.debug_to_string loc in
    failwith ("Unknown expression type to normalize (object on " ^ loc_info ^ ")")


and normalize_pattern (pattern : ('M, 'T) Ast.Pattern.t) : m Identifier.t =
  (* TODO : need to look to other cases *)
  match pattern with
    | _, Ast.Pattern.Identifier {name; _} -> convert_identifier name
    | _ -> failwith "pattern not implemented"

and convert_identifier (loc, {Ast.Identifier.name; _}) : m Identifier.t =
  Identifier.build (loc_f loc) name

and unpattern (loc, {Ast.Statement.VariableDeclaration.Declarator.id; init}) : (m * m Identifier.t * (Loc.t, Loc.t) Ast.Expression.t option) list = 
  (* TODO : full unpattern *)
  let id' = normalize_pattern id in
  [(loc_f loc, id', init)]

and normalize_alternate (_, {Ast.Statement.If.Alternate.body; _}) : norm_stmt_t = 
  normalize_statement empty_context body

and normalize_case (loc, {Ast.Statement.Switch.Case.test; consequent; _}) : m Statement.Switch.Case.t * norm_stmt_t = 
  let ns = normalize_statement empty_context in
  let ne = normalize_expression empty_context in

  let test_stmts, test_expr = map_default ne ([], None) test in
  let cnsq_stmts = List.flatten (List.map ns consequent) in 

  let case = Statement.Switch.Case.build (loc_f loc) test_expr cnsq_stmts in
  (case, test_stmts)

and normalize_catch (loc, { Ast.Statement.Try.CatchClause.param; body; _}) : norm_stmt_t * m Statement.Catch.t option = 
    let param' = Option.map normalize_pattern param in 
    let body_stmts = normalize_statement empty_context (block_to_statement body) in 

    let catch = Statement.Catch.build (loc_f loc) param' body_stmts in
    (body_stmts, Some catch)
  
and normalize_array_elem (element : ('M, 'T) Ast.Expression.Array.element) : norm_expr_t = 
  (* TODO : other cases *)
  match element with
    | Ast.Expression.Array.Expression expr -> normalize_expression empty_context expr
    | _ -> failwith "normalize array element case not defined"

and normalize_argument_list (_, {Ast.Expression.ArgList.arguments; _}) : norm_expr_t list = 
  List.map normalize_argument arguments

and normalize_argument (arg : ('M, 'T) Ast.Expression.expression_or_spread) : norm_expr_t = 
  (* TODO : other cases *)
  match arg with
    | Ast.Expression.Expression expr -> normalize_expression empty_context expr 
    | _ -> failwith "normalize argument case not defined"

and normalize_function (context : context) (loc : Loc.t) (id : (Loc.t, Loc.t) Ast.Identifier.t option) (_, {Ast.Function.Params.params; _}) (body : (Loc.t, Loc.t) Ast.Function.body) : norm_expr_t =
  let loc = loc_f loc in 
  let id = get_identifier (if Option.is_some id then Option.map convert_identifier id else context.identifier) loc in 
  
  let params_stmts, params_exprs = List.split (List.map normalize_param params) in
  let body_stmts = normalize_func_body body in 
  let assign = Statement.AssignFunction.build loc id params_exprs body_stmts in 
  
  if not context.is_assignment then 
    let _, decl = createVariableDeclaration None loc ~objId:(Id id) in 
    (List.flatten params_stmts @ decl @ [assign], Some (Identifier.to_expression id))
  else
    (List.flatten params_stmts @ [assign], Some (Identifier.to_expression id)) 


and normalize_param (loc, {Ast.Function.Param.argument; default}) : m Statement.t list * m Statement.AssignFunction.Param.t  = 
  let argument' = normalize_pattern argument in
  let def_stmts, def_expr = map_default (normalize_expression empty_context) ([], None) default in
  let param = Statement.AssignFunction.Param.build (loc_f loc) argument' def_expr in
  (def_stmts, param)

and normalize_func_body (body : ('M, 'T) Ast.Function.body) : norm_stmt_t =
  match body with 
    | Ast.Function.BodyBlock body-> 
      normalize_statement empty_context (block_to_statement body) 

    | Ast.Function.BodyExpression ((loc, _) as body) -> 
      let body_stmts, body_expr = normalize_expression empty_context body in 
      let return = Statement.Return.build (loc_f loc) body_expr in 
      body_stmts @ [return]

and normalize_member_property (property : ('M, 'T) Ast.Expression.Member.property) : norm_expr_t = 
  match property with
    | PropertyIdentifier ((loc, _) as id) -> normalize_expression empty_context (loc, Ast.Expression.Identifier id)
    | PropertyExpression expr -> normalize_expression empty_context expr
    (* TODO : private name not implemented*)
    | PropertyPrivateName _ -> failwith "property private name not implemented"

and normalize_property (property : ('M, 'T) Ast.Expression.Object.property) = 
  let nk = normalize_property_key in 
  match property with
    | Property (_, Init {key; value; shorthand}) ->
      let key_stmts, key_expr = nk key in 
      let val_stmts, val_expr = normalize_expression empty_context value in 
      let property = Statement.AssignObject.Property.build _init (Option.get key_expr) (Option.get val_expr) (Some shorthand) in
      key_stmts @ val_stmts, property

      | Property (_, Method {key; value=(loc, func); _}) -> 
      let key_stmts, key_expr = nk key in 
      let val_stmts, val_expr = normalize_expression empty_context (loc, Ast.Expression.Function func) in 
      let property = Statement.AssignObject.Property.build _init (Option.get key_expr) (Option.get val_expr) None in
      key_stmts @ val_stmts, property
      
    | Property (_, Get {key; value=(loc, func); _}) -> 
      let key_stmts, key_expr = nk key in 
      let val_stmts, val_expr = normalize_expression empty_context (loc, Ast.Expression.Function func) in 
      let property = Statement.AssignObject.Property.build _init (Option.get key_expr) (Option.get val_expr) None in
      key_stmts @ val_stmts, property

    | Property (_, Set {key; value=(loc, func); _}) -> 
      let key_stmts, key_expr = nk key in 
      let val_stmts, val_expr = normalize_expression empty_context (loc, Ast.Expression.Function func) in 
      let property = Statement.AssignObject.Property.build _init (Option.get key_expr) (Option.get val_expr) None in
      key_stmts @ val_stmts, property

    (* TODO : spread property not implemented *)
    | _ -> failwith "spread property not implemented"

and normalize_property_key (key : ('M, 'T) Ast.Expression.Object.Property.key) : norm_expr_t = 
  match key with
  | StringLiteral (loc, literal) -> normalize_expression empty_context (loc, Ast.Expression.StringLiteral literal)
  | NumberLiteral (loc, literal) -> normalize_expression empty_context (loc, Ast.Expression.NumberLiteral literal)
  | BigIntLiteral (loc, literal) -> normalize_expression empty_context (loc, Ast.Expression.BigIntLiteral literal)
  | Identifier ((loc, _) as id)  -> normalize_expression empty_context (loc, Ast.Expression.Identifier id)
  (* TODO : private name and computed key not implemented *)
  | _ -> failwith "private name and computed key not implemented"

and build_template_element (loc, {Ast.Expression.TemplateLiteral.Element.value={raw; cooked}; tail}) : m Expression.TemplateLiteral.Element.t =
  Expression.TemplateLiteral.Element.build (loc_f loc) raw cooked tail

and get_identifier (id : m Identifier.t option) (loc : m) : m Identifier.t = 
  map_default identity (Identifier.build_random loc) id

and createVariableDeclaration ?(objId : name_or_id = Name None) ?(kind : Statement.VarDecl.kind = _const) (obj : m Expression.t option) (loc : m) : m Identifier.t * norm_stmt_t =
  let id = match objId with 
    | Name objId -> map_default (Identifier.build loc) (Identifier.build_random loc) objId
    | Id objId   -> objId 
  in 
  let kind = if (Option.is_none obj && kind = _const) then _let else kind in 

  let decl = Statement.VarDecl.build loc kind id in 
  let assign = Option.map (Statement.AssignSimple.build loc None id) obj in 
  
  (id, [decl] @ Option.to_list assign)

and is_special_assignment ((_, expr) : ('M, 'T) Ast.Expression.t) : bool =
  match expr with 
    (* -- ASSIGN NEW -- *)
    | Ast.Expression.New _ 
    (* -- ASSIGN CALL -- *)
    | Ast.Expression.Call _
    (* -- ASSING MEMBER -- *)
    | Ast.Expression.Member _    
    (* -- ASSING OBJECT -- *)
    | Ast.Expression.Object _
    (* -- ASSIGN FUNCTION -- *)
    | Ast.Expression.Function _
    | Ast.Expression.ArrowFunction _
    (* -- ASSIGN ARRAY --*)
    | Ast.Expression.Array _ -> true
    | _ -> false

and block_to_statement (loc, block) : (Loc.t, Loc.t) Ast.Statement.t =
  (loc, Ast.Statement.Block block)

and change_kind (kind' : Statement.VarDecl.kind) ((loc, stmt) : m Statement.t) : m Statement.t =
  match stmt with
    | VarDecl decl -> let decl' = Statement.VarDecl {decl with kind = kind'} in 
                      (loc, decl')
    | _ -> failwith "tried to change the kind of non-declaration statement"
  
and is_declaration ((_, stmt) : m Statement.t) : bool = 
  match stmt with 
    | Statement.VarDecl _ -> true 
    | _                   -> false;;


  

