module Ast = Flow_ast
open GraphJS

let (<<) f g x = f(g(x));;

let map_default f x value =
  match value with
    | Some value -> f value
    | None -> x

type m = Location.t
type norm_stmt_t = m Statement.t list;;
type norm_expr_t = m Statement.t list * m Expression.t option;;

let empty_stmt_return : norm_stmt_t = [];;
let empty_expr_return : norm_expr_t = ([], None);;

let loc_f = Location.convert_flow_loc;;


let rec normalize ((loc, _) as program : ('M, 'T) Ast.Program.t) : m Program.t = 
  let prog_stmts = normalize_program program in
  let location   = loc_f loc in 
  let program'   = Program.build location prog_stmts in
  program';

and normalize_program (_ , ({ Ast.Program.statements; _ })) : norm_stmt_t =
  let statements' = List.map normalize_statement statements in
  List.flatten statements'

and normalize_statement (stmt : ('a, 'b) Ast.Statement.t) : norm_stmt_t =
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
    (* TODO *)
    | _, Ast.Statement.For _ (* {init; test; update; body} *) -> empty_stmt_return

    (* TODO *)
    | _, Ast.Statement.ForIn _ -> empty_stmt_return
    
    (* TODO *)
    | _, Ast.Statement.ForOf _ -> empty_stmt_return
    
    (* TODO *)
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
    (* TODO *)
    | _, Ast.Statement.VariableDeclaration _ (* {kind; declarations; _} *) ->
      empty_stmt_return
    
    (* ----- R E T U R N ----- *)
    | loc, Ast.Statement.Return {argument; _} -> 
      let arg_stmts, arg_expr = map_default ne ([], None) argument in
      let return_stmt = Statement.Return.build (loc_f loc) arg_expr in 

      arg_stmts @ [return_stmt]
    
    
    | _, Ast.Statement.Expression {expression; _} -> 
      fst (ne expression)
            
    | loc, _ -> 
      let loc_info = Loc.debug_to_string loc in
      failwith ("Unknown statement type to normalize (object on " ^ loc_info ^ ")")
    
and normalize_expression (expr : ('a, 'b) Ast.Expression.t) : norm_expr_t =
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
  (* TODO *)
  | _, Ast.Expression.Logical _ -> empty_expr_return
  
  (* ----- B I N A R Y ----- *)
  (* TODO *)
  | _, Ast.Expression.Binary _ -> empty_expr_return
  
  (* ----- U N A R Y ----- *)
  (* TODO *)
  | loc, Ast.Expression.Unary {operator; argument; _} -> 
    let operator' = Operator.Unary.translate operator in 
    let arg_stmts, arg_expr = ne argument in

    let unary_expr = Expression.Unary.build (loc_f loc) operator' (Option.get arg_expr) in 

    (arg_stmts, Some unary_expr)

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
  (* TODO : simplify *)
  (* TODO : check parent type and build identifier accordingly 
      var x = [1, 2, 3] == REPETITIVE var v1; v1 = [1, 2, 3]; var x; var x = v1;
                           BETTER     var x; x = [1, 2, 3]
  *)
  | loc, Ast.Expression.Array {elements; _} -> 
    let elems_stmts, elems_exprs = List.split (List.map normalize_array_elem elements) in 
    let elems_exprs = List.map Option.get (List.filter Option.is_some elems_exprs) in 

    let location = loc_f loc in
    let identifer = Identifier.build_random location in
    let declaration = Statement.VarDecl.build location Statement.VarDecl.Var identifer in 
    let assignment = Statement.AssignArray.build location identifer elems_exprs in

    ((List.flatten elems_stmts) @ [declaration; assignment] , Some (Identifier.to_expression identifer))
  
  | loc, _ -> 
    let loc_info = Loc.debug_to_string loc in
    failwith ("Unknown expression type to normalize (object on " ^ loc_info ^ ")")

and normalize_pattern (pattern : ('a, 'b) Ast.Pattern.t) : m Identifier.t =
  match pattern with
    | _, Ast.Pattern.Identifier {name = (loc, {Ast.Identifier.name; _}); _} -> 
      Identifier.build (loc_f loc) name

    (* TODO : need to look to other cases *)
    | _ -> failwith "pattern not implemented"

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
  
and normalize_array_elem (element : ('a, 'b) Ast.Expression.Array.element) : norm_expr_t = 
  (* TODO : other cases *)
  match element with
    | Ast.Expression.Array.Expression expr -> normalize_expression expr
    | _ -> failwith "normalize array element case not defined"

and block_to_statement (loc, {Ast.Statement.Block.body; comments}) : (Loc.t, Loc.t) Ast.Statement.t =
  let block_info = Ast.Statement.Block {
    body = body;
    comments = comments;
  } in 
  (loc, block_info);;


  

