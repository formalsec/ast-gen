module Ast = Flow_ast
open GraphJS 

let (<<) f g x = f(g(x));;

let map_default f x value =
  match value with
    | Some value -> f value
    | None -> x

type norm_stmt_t = Location.t Statement.t list;;
type norm_expr_t = Location.t Statement.t list * Location.t Expression.t option;;

let empty_stmt_return : norm_stmt_t = [];;
let empty_expr_return : norm_expr_t = ([], None);;

let loc_f = Location.convert_flow_loc;;




let rec normalize ((loc, _) as program : ('M, 'T) Ast.Program.t) : Location.t Program.t = 
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

      let location = loc_f loc in 
      let if_stmt = Statement.If.build location (Option.get test_expr) cons_stmts altn_stmts in
      
      test_stmts @ [if_stmt]
    
    (* ----- W H I L E ----- *)
    | loc, Ast.Statement.While { test; body; _ } -> 
      let test_stmts, test_expr = ne test in
      let body_stmts = ns body in

      let location = loc_f loc in
      let while_stmt= Statement.While.build location (Option.get test_expr) body_stmts in

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

      let location = loc_f loc in
      let switch = Statement.Switch.build location (Option.get dicr_expr) cases' in

      (* statements generated from the normalization of the 
         discriminant and the test expression of each case*)
      let previous_stmts = dicr_stmts @ List.flatten tests_stmts in
      previous_stmts @ [switch]
    
    (* ----- T R Y - C A T C H ----- *)
    | loc, Ast.Statement.Try {block; handler; finalizer; _} -> 
      let block_stmts = ns (block_to_statement block) in
      let fnlzr_stmts = Option.map (ns << block_to_statement) finalizer in

      (* process catch clause *)
      let handler', handler_stmts = map_default normalize_catch (None, empty_stmt_return) handler in
    
      (* build try statement*)
      let location = loc_f loc in
      let try_statement = Statement.Try.build location block_stmts handler' fnlzr_stmts in

      handler_stmts @ [try_statement]

    (* ----- V A R I A B L E   D E C L A R A T I O N ----- *)
    (* TODO *)
    | _, Ast.Statement.VariableDeclaration _ (* {kind; declarations; _} *) ->
      empty_stmt_return
    
    (* ----- R E T U R N ----- *)
    | loc, Ast.Statement.Return {argument; _} -> 
      let arg_stmts, arg_expr = map_default ne ([], None) argument in

      let location = loc_f loc in
      let return = Statement.Return.build location arg_expr in 

      arg_stmts @ [return]
    
    
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
    let location = loc_f loc in
    let value' = Expression.Literal.String value in 
    let literal = Expression.Literal.build location value' raw in 
    ([], Some literal);

  | loc, Ast.Expression.NumberLiteral {value; raw; _} -> 
    let location = loc_f loc in
    let value' = Expression.Literal.Number value in 
    let literal = Expression.Literal.build location value' raw in 
    ([], Some literal);

  | loc, Ast.Expression.BigIntLiteral {value; raw; _} -> 
    let location = loc_f loc in
    let value = Expression.Literal.BigInt value in 
    let literal = Expression.Literal.build location value raw in 
    ([], Some literal);

  | loc, Ast.Expression.BooleanLiteral {value; _} -> 
    let location = loc_f loc in
    let value' = Expression.Literal.Boolean value in 
    let raw = if value then "true" else "false" in 
    let literal = Expression.Literal.build location value' raw in 
    ([], Some literal);

  | loc, Ast.Expression.NullLiteral _ -> 
    let location = loc_f loc in
    let value = Expression.Literal.Null () in
    let literal = Expression.Literal.build location value "null" in
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

    let location = loc_f loc in
    let unary = Expression.Unary.build location operator' (Option.get arg_expr) in 

    (arg_stmts, Some unary)

  (* ----- T H I S ----- *)
  | loc, Ast.Expression.This _ -> 
    let location = loc_f loc in
    let this = Expression.This.build location in
    ([], Some this)
  
  (* ----- A S S I G N   S I M P L E ----- *)
  | loc, Ast.Expression.Assignment {operator; left; right; _} ->
    let operator' = Option.map Operator.Assignment.translate operator in
    let left' = normalize_pattern left in 
    let right_stmts, right_expr = ne right in

    let location = loc_f loc in 
    let assignment = Statement.AssignSimple.build location operator' left' (Option.get right_expr) in
    (* TODO : graph.js normalizer has some special cases depending on the parent *)

    (right_stmts @ [assignment], None)

  (* ----- A S S I G N   A R R A Y -----*)
  (* TODO : simplify *)
  | loc, Ast.Expression.Array {elements; _} -> 

    (* TODO : other cases *)
    let normalize_element (element : ('a, 'b) Ast.Expression.Array.element) = match element with
      | Ast.Expression.Array.Expression expr -> ne expr
      | _ -> failwith "normalize array element case not defined"
    in  

    let location = loc_f loc in
    (* TODO : check parent type and build identifier accordingly 
      var x = [1, 2, 3] == REPETITIVE var v1; v1 = [1, 2, 3]; var x; var x = v1;
                           BETTER     var x; x = [1, 2, 3]
    *)
    let identifer = Identifier.build_random location in
    let declaration = Statement.VarDecl.build location Statement.VarDecl.Var identifer in 
    
    let elems_stmts, elems_exprs = List.split (List.map normalize_element elements) in 
    let elems_stmts = List.flatten elems_stmts in 
    let elems_exprs = List.map Option.get (List.filter Option.is_none elems_exprs) in 
    let assignment = Statement.AssignArray.build location identifer elems_exprs in

    (elems_stmts @ [declaration; assignment] , Some (Identifier.to_expression identifer))
  
  | loc, _ -> 
    let loc_info = Loc.debug_to_string loc in
    failwith ("Unknown expression type to normalize (object on " ^ loc_info ^ ")")

and normalize_alternate (_, {Ast.Statement.If.Alternate.body; _}) : norm_stmt_t = 
  normalize_statement body

and normalize_pattern (pattern : ('a, 'b) Ast.Pattern.t) : Location.t Identifier.t =
  match pattern with
    | _, Ast.Pattern.Identifier {name = (loc, {Ast.Identifier.name; _}); _} -> 
      let location = loc_f loc in
      Identifier.build location name

    (* TODO : need to look to other cases *)
    | _ -> failwith "pattern not implemented"

and normalize_case (loc, {Ast.Statement.Switch.Case.test; consequent; _}) : Location.t Statement.Switch.Case.t * norm_stmt_t = 
  let ns = normalize_statement in
  let ne = normalize_expression in

  let test_stmts, test_expr = map_default ne ([], None) test in
  let cnsq_stmts = List.flatten (List.map ns consequent) in 

  let location = loc_f loc in
  let case = Statement.Switch.Case.build location test_expr cnsq_stmts in
  (case, test_stmts)

and normalize_catch (loc, { Ast.Statement.Try.CatchClause.param; body; _}) : Location.t Statement.Catch.t option * norm_stmt_t = 
    let param' = Option.map normalize_pattern param in 
    let body_stmts = normalize_statement (block_to_statement body) in 

    let location = loc_f loc in
    let catch = Statement.Catch.build location param' body_stmts in
    (Some catch, body_stmts)
  

and block_to_statement (loc, {Ast.Statement.Block.body; comments}) : (Loc.t, Loc.t) Ast.Statement.t =
  let block_info = Ast.Statement.Block {
    body = body;
    comments = comments;
  } in 
  (loc, block_info);;


  

