module Ast = Flow_ast
open GraphJS

let (<<) f g x = f(g(x));;
let identity x = x 

let map_default f x value =
  match value with
    | Some value -> f value
    | None -> x

type m = Location.t;;
type norm_stmt_t = m Statement.t list;;
type norm_expr_t = m Statement.t list * m Expression.t option;;

let empty_stmt_return : norm_stmt_t = [];;
let empty_expr_return : norm_expr_t = ([], None);;

let loc_f = Location.convert_flow_loc;;

let _const = Statement.VarDecl.Const;;
let _let = Statement.VarDecl.Let;;
let _var = Statement.VarDecl.Var;;


let rec normalize ((loc, _) as program : ('M, 'T) Ast.Program.t) : m Program.t = 
  let prog_stmts = normalize_program program in
  let location   = loc_f loc in 
  let program'   = Program.build location prog_stmts in
  program';

and normalize_program (_ , ({ Ast.Program.statements; _ })) : norm_stmt_t =
  let statements' = List.map normalize_statement statements in
  List.flatten statements'

and normalize_statement (stmt : ('M, 'T) Ast.Statement.t) : norm_stmt_t =
  let ns  = normalize_statement in
  let ne  = normalize_expression in

  match stmt with
    (* ----- B L O C K ----- *)
    | _, Ast.Statement.Block {body; _} -> 
      let body_stmts = List.map ns body in
      List.flatten body_stmts;
    
    (* ----- I F ----- *)
    | loc, Ast.Statement.If {test; consequent; alternate; _} ->
      let test_stmts, test_expr = ne test in
      let cons_stmts = ns consequent in
      let altn_stmts = Option.map normalize_alternate alternate in
      let if_stmt = Statement.If.build (loc_f loc) (Option.get test_expr) cons_stmts altn_stmts in
      
      test_stmts @ [if_stmt]
    
    (* ----- W H I L E ----- *)
    | loc, Ast.Statement.While { test; body; _ } -> 
      let test_stmts, test_expr = ne test in
      let body_stmts = ns body in
      let while_stmt= Statement.While.build (loc_f loc) (Option.get test_expr) body_stmts in

      (* TODO : normWhileStatement performs some computations over the norm_test.statements *)
      (test_stmts @ [while_stmt])
    
    (* all this will be transformed into while statments *) 
    | _, Ast.Statement.For _ (* {init; test; update; body} *) -> empty_stmt_return

    | _, Ast.Statement.ForIn _ -> empty_stmt_return
    
    | _, Ast.Statement.ForOf _ -> empty_stmt_return
    
    | _, Ast.Statement.DoWhile _ -> empty_stmt_return
    
    (* ----- S W I T C H ----- *)
    | loc, Ast.Statement.Switch  { discriminant; cases; _ } -> 
      let dicr_stmts, dicr_expr = ne discriminant in 
      (* normalize cases *)
      let cases', tests_stmts = List.split (List.map normalize_case cases) in
      let switch_stmt = Statement.Switch.build (loc_f loc) (Option.get dicr_expr) cases' in

      (* statements generated from the normalization of the 
         discriminant and the test expression of each case*)
      let previous_stmts = dicr_stmts @ List.flatten tests_stmts in
      previous_stmts @ [switch_stmt]
    
    (* ----- T R Y - C A T C H ----- *)
    | loc, Ast.Statement.Try {block; handler; finalizer; _} -> 
      let block_stmts = ns (block_to_statement block) in
      let fnlzr_stmts = Option.map (ns << block_to_statement) finalizer in

      (* process catch clause *)
      let handler', handler_stmts = map_default normalize_catch (None, empty_stmt_return) handler in
    
      (* build try statement*)
      let try_stmt = Statement.Try.build (loc_f loc) block_stmts handler' fnlzr_stmts in

      handler_stmts @ [try_stmt]

    (* ----- V A R I A B L E   D E C L A R A T I O N ----- *)
    | _, Ast.Statement.VariableDeclaration {kind; declarations; _} ->
      let kind' : Statement.VarDecl.kind = match kind with 
        | Var -> _var  | Let -> _let  | Const -> _const 
      in

      let unpattern_decls = List.flatten (List.map unpattern declarations) in
      let decl_stmts = List.map (fun (loc, name, init ) -> 
        let init_stmt, init_expr = map_default ne ([], None) init in 
        let _, decl = createVariableDeclaration init_expr loc ~objId:(Some name) ~kind:kind' () in     
        init_stmt @ decl
      ) unpattern_decls in 

      List.flatten decl_stmts
    
    (* ----- R E T U R N ----- *)
    | loc, Ast.Statement.Return {argument; _} -> 
      let arg_stmts, arg_expr = map_default ne ([], None) argument in
      let return_stmt = Statement.Return.build (loc_f loc) arg_expr in 

      arg_stmts @ [return_stmt]
    
    (* ----- A S S I G N   F U N C T I O N -----*)
    | loc, Ast.Statement.FunctionDeclaration {id; params; body; _} -> fst (normalize_function loc id params body)
    
    | _, Ast.Statement.Expression {expression; _} -> 
      fst (ne expression)
            
    | loc, _ -> 
      let loc_info = Loc.debug_to_string loc in
      failwith ("Unknown statement type to normalize (object on " ^ loc_info ^ ")")
    
and normalize_expression (expr : ('M, 'T) Ast.Expression.t) : norm_expr_t =
  let ne = normalize_expression in
  match expr with
  (* ----- L I T E R A L ----- *)
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
  
  (* ----- T E M P L A T E    L I T E R A L ----- *)
  | _, Ast.Expression.TemplateLiteral _ -> empty_expr_return 

  (* ----- I D E N T I F I E R ----- *)
  | _, Ast.Expression.Identifier (loc, { name; _ }) -> 
    let location = loc_f loc in
    let identifier = Identifier.to_expression (Identifier.build location name) in 
    ([], Some identifier)

  (* ----- L O G I C A L ----- *)
  | loc, Ast.Expression.Logical {operator; left; right; _} -> 
    let operator' = Operator.Logical.translate operator in
    let left_stmt, left_expr = ne left in  
    let right_stmt, right_expr = ne right in  

    (* TODO : check the parent to check it is already an assignment -> avoid repetition *)
    let location = loc_f loc in
    let logical = Expression.Logical.build location operator' (Option.get left_expr) (Option.get right_expr) in 
    let id, decl = createVariableDeclaration (Some logical) location () in 

    (left_stmt @ right_stmt @ decl, Some (Identifier.to_expression id))
  
  (* ----- B I N A R Y ----- *)
  | loc, Ast.Expression.Binary {operator; left; right; _} -> 
    let operator' = Operator.Binary.translate operator in
    let left_stmt, left_expr = ne left in  
    let right_stmt, right_expr = ne right in  

    (* TODO : check the parent to check it is already an assignment -> avoid repetition *)
    let location = loc_f loc in
    let binary = Expression.Binary.build location operator' (Option.get left_expr) (Option.get right_expr) in 
    let id, decl = createVariableDeclaration (Some binary) location () in 

    (left_stmt @ right_stmt @ decl, Some (Identifier.to_expression id))
  
  (* ----- U N A R Y ----- *)
  | loc, Ast.Expression.Unary {operator; argument; _} -> 
    let operator' = Operator.Unary.translate operator in 
    let arg_stmts, arg_expr = ne argument in

    (* TODO : check the parent to check it is already an assignment -> avoid repetition *)
    let location = loc_f loc in
    let unary_expr = Expression.Unary.build location operator' (Option.get arg_expr) in 
    let id, decl = createVariableDeclaration (Some unary_expr) location () in 

    (arg_stmts @ decl, Some (Identifier.to_expression id))

  (* ----- T H I S ----- *)
  | loc, Ast.Expression.This _ -> 
    let this = Expression.This.build (loc_f loc) in
    ([], Some this)
  
  (* ----- A S S I G N   S I M P L E ----- *)
  | loc, Ast.Expression.Assignment {operator; left; right; _} ->
    let operator' = Option.map Operator.Assignment.translate operator in
    let left' = normalize_pattern left in 
    let right_stmts, right_expr = ne right in

    let assign_expr = Statement.AssignSimple.build (loc_f loc) operator' left' (Option.get right_expr) in
    (* TODO : graph.js normalizer has some special cases depending on the parent *)

    (right_stmts @ [assign_expr], None)

  (* ----- A S S I G N   A R R A Y -----*)
  | loc, Ast.Expression.Array {elements; _} -> 
    let elems_stmts, elems_exprs = List.split (List.map normalize_array_elem elements) in 
    let elems_exprs = List.map Option.get (List.filter Option.is_some elems_exprs) in 

    let loc = loc_f loc in
    (* TODO : check the parent to check it is already an assignment -> avoid repetition *)
    let id = Identifier.build_random loc in
    let decl = Statement.VarDecl.build loc _const id in 
    let assign = Statement.AssignArray.build loc id elems_exprs in

    ((List.flatten elems_stmts) @ [decl; assign] , Some (Identifier.to_expression id))
  
  (* ----- A S S I G N   N E W -----*)
  | loc, Ast.Expression.New {callee; arguments; _} -> 
    let callee_stmts, callee_expr = ne callee in
    let args_stmts, args_exprs = List.split (map_default normalize_argument_list [] arguments) in 
    let args_exprs = List.flatten (List.map Option.to_list args_exprs) in

    let loc = loc_f loc in
    (* TODO : check the parent to check it is already an assignment -> avoid repetition *)
    let id = Identifier.build_random loc in
    let decl = Statement.VarDecl.build loc _const id in
    let assign = Statement.AssignNew.build loc id (Option.get callee_expr) args_exprs in

    (callee_stmts @ (List.flatten args_stmts) @ [decl; assign] , Some (Identifier.to_expression id))

  (* ----- A S S I G N   F U N C   C A L L -----*)
  | loc, Ast.Expression.Call {callee; arguments; _} -> 
    let callee_stmts, callee_expr = ne callee in
    let args_stmts, args_exprs = List.split (normalize_argument_list arguments) in 
    let args_exprs = List.flatten (List.map Option.to_list args_exprs) in

    let loc = loc_f loc in
    (* TODO : check the parent to check it is already an assignment -> avoid repetition *)
    let id = Identifier.build_random loc in
    let decl = Statement.VarDecl.build loc _const id in
    let assign = Statement.AssignNew.build loc id (Option.get callee_expr) args_exprs in

    (callee_stmts @ (List.flatten args_stmts) @ [decl; assign] , Some (Identifier.to_expression id))

  (* ----- A S S I G N   F U N C T I O N -----*)
  | loc, Ast.Expression.ArrowFunction {id; params; body; _} -> normalize_function loc id params body
  | loc, Ast.Expression.Function {id; params; body; _} -> normalize_function loc id params body
  
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

and unpattern (loc, {Ast.Statement.VariableDeclaration.Declarator.id; init}) : (m * string * (Loc.t, Loc.t) Ast.Expression.t option) list = 
  (* TODO : full unpattern *)
  let id' = normalize_pattern id in
  let name = match id' with _, {Identifier.name} -> name in
  [(loc_f loc, name, init)]

and normalize_alternate (_, {Ast.Statement.If.Alternate.body; _}) : norm_stmt_t = 
  normalize_statement body

and normalize_case (loc, {Ast.Statement.Switch.Case.test; consequent; _}) : m Statement.Switch.Case.t * norm_stmt_t = 
  let ns = normalize_statement in
  let ne = normalize_expression in

  let test_stmts, test_expr = map_default ne ([], None) test in
  let cnsq_stmts = List.flatten (List.map ns consequent) in 

  let case = Statement.Switch.Case.build (loc_f loc) test_expr cnsq_stmts in
  (case, test_stmts)

and normalize_catch (loc, { Ast.Statement.Try.CatchClause.param; body; _}) : m Statement.Catch.t option * norm_stmt_t = 
    let param' = Option.map normalize_pattern param in 
    let body_stmts = normalize_statement (block_to_statement body) in 

    let catch = Statement.Catch.build (loc_f loc) param' body_stmts in
    (Some catch, body_stmts)
  
and normalize_array_elem (element : ('M, 'T) Ast.Expression.Array.element) : norm_expr_t = 
  (* TODO : other cases *)
  match element with
    | Ast.Expression.Array.Expression expr -> normalize_expression expr
    | _ -> failwith "normalize array element case not defined"

and normalize_argument_list (_, {Ast.Expression.ArgList.arguments; _}) : norm_expr_t list = 
  List.map normalize_argument arguments

and normalize_argument (arg : ('M, 'T) Ast.Expression.expression_or_spread) : norm_expr_t = 
  (* TODO : other cases *)
  match arg with
    | Ast.Expression.Expression expr -> normalize_expression expr 
    | _ -> failwith "normalize argument case not defined"

and normalize_function (loc : Loc.t) (id : (Loc.t, Loc.t) Ast.Identifier.t option) (_, {Ast.Function.Params.params; _}) (body : (Loc.t, Loc.t) Ast.Function.body) : norm_expr_t =
  (* TODO : check the parent to check it is already an assignment -> avoid repetition *)
  let loc = loc_f loc in 
  let id = map_default identity (Identifier.build_random loc) (Option.map convert_identifier id) in 
  let params_stmts, params_exprs = List.split (List.map normalize_param params) in
  let body_stmts = normalize_func_body body in 
  
  let decl = Statement.VarDecl.build loc _const id in 
  let assign = Statement.AssignFunction.build loc id params_exprs body_stmts in 

  (List.flatten params_stmts @ [decl; assign], Some (Identifier.to_expression id))

and normalize_param (loc, {Ast.Function.Param.argument; default}) : m Statement.t list * m Statement.AssignFunction.Param.t  = 
  let argument' = normalize_pattern argument in
  let def_stmts, def_expr = map_default normalize_expression ([], None) default in
  let param = Statement.AssignFunction.Param.build (loc_f loc) argument' def_expr in
  (def_stmts, param)

and normalize_func_body (body : ('M, 'T) Ast.Function.body) : norm_stmt_t =
  match body with 
    | Ast.Function.BodyBlock body-> 
      normalize_statement (block_to_statement body) 

    | Ast.Function.BodyExpression ((loc, _) as body) -> 
      let body_stmts, body_expr = normalize_expression body in 
      let return = Statement.Return.build (loc_f loc) body_expr in 
      body_stmts @ [return]

and createVariableDeclaration (obj : m Expression.t option) (loc : m) ?(objId : string option = None) ?(kind : Statement.VarDecl.kind = _const) () : m Identifier.t * norm_stmt_t =
  let id = map_default (Identifier.build loc) (Identifier.build_random loc) objId in 
  let kind = if (Option.is_none obj && kind == _const) then _let else kind in 

  let decl = Statement.VarDecl.build loc kind id in 
  let assign = Option.map (Statement.AssignSimple.build loc None id) obj in 
  
  (id, [decl] @ Option.to_list assign)

and block_to_statement (loc, {Ast.Statement.Block.body; comments}) : (Loc.t, Loc.t) Ast.Statement.t =
  let block_info = Ast.Statement.Block {
    body = body;
    comments = comments;
  } in 
  (loc, block_info);;


  

