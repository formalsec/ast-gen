module Ast = Flow_ast
(* open GraphJS  *)

type normalization_return = {
  statements : Location.t Statement.t list;
  expression : Location.t Expression.t option; 
};;

let empty_normalization : normalization_return = {statements = []; expression = None};;

let rec normalize ((loc, _) as program : ('M, 'T) Ast.Program.t) : Location.t Program.t = 
  let norm_program = normalize_program program in
  let location = Location.convert_flow_loc loc in 
  let program' = Program.build location norm_program.statements in
  program';

and normalize_program (_ , ({ Ast.Program.statements; _ })) : normalization_return =
  let statements' = List.map normalize_statement statements in
  let flat_stmts = flat_statements statements' in

  {statements = flat_stmts; expression = None};

and normalize_statement (stmt : ('a, 'b) Ast.Statement.t) : normalization_return =
  match stmt with
    (* ----- B L O C K ----- *)
    | _, Ast.Statement.Block {body; _} -> 
      let norm_body = List.map normalize_statement body in
      let body' = flat_statements norm_body in
      { statements = body' ; expression = None}
    
    (* ----- I F ----- *)
    | loc, Ast.Statement.If {test; consequent; alternate; _} ->
      let norm_test = normalize_expression test in
      let test' = match norm_test.expression with
        | Some expression -> expression;
        | None -> failwith "if test statment normalization didnt return an expression"
      in
      
      let norm_consequent = normalize_statement consequent in
      let consequent' = norm_consequent.statements in
      
      let alternate' = match alternate with 
        | Some (_, {body; _}) -> 
            let norm_alternate = normalize_statement body in 
            Some (norm_alternate.statements)
        | None -> None
      in
      
      (* build if statement *)
      let location = Location.convert_flow_loc loc in 
      let if_statement = Statement.If.build location test' consequent' alternate' in
      
      (* return *)
      {statements = norm_test.statements @ [if_statement]; expression = None};
    
    (* ----- W H I L E ----- *)
    | loc, Ast.Statement.While { test; body; _ } -> 
      let norm_test = normalize_expression test in
      let test' = match norm_test.expression with
        | Some expression -> expression;
        | None -> failwith "if test expression normalization didn't produce any result"
      in
      let norm_body = normalize_statement body in
      let body' = norm_body.statements in

      (* build while statement*)
      let location = Location.convert_flow_loc loc in
      let while_statement = Statement.While.build location test' body' in

      (* TODO : normWhileStatement performs some computations 
                over the norm_test.statements *)
      (* return *)
      {statements = norm_test.statements @ [while_statement]; expression = None};
    
    (* all this will be transformed into while statments *) 
    (* TODO *)
    | _, Ast.Statement.For _ (* {init; test; update; body} *) -> 
      empty_normalization

    (* TODO *)
    | _, Ast.Statement.ForIn _ -> empty_normalization
    
    (* TODO *)
    | _, Ast.Statement.ForOf _ -> empty_normalization
    
    (* TODO *)
    | _, Ast.Statement.DoWhile _ -> empty_normalization
    
    (* ----- S W I T C H ----- *)
    | loc, Ast.Statement.Switch  { discriminant; cases; _ } -> 
      let norm_discriminant = normalize_expression discriminant in
      let discriminant' = match norm_discriminant.expression with
        | Some discriminant -> discriminant
        | None -> failwith "switch discriminant expression normalization didn't produce any result"
      in

      let norm_cases = List.map normalize_switch_case cases in
      let cases' = List.map snd norm_cases in 

      (* build switch case *)
      let location = Location.convert_flow_loc loc in
      let switch_statement = Statement.Switch.build location discriminant' cases' in

      (* return *)
      let previous_statements = norm_discriminant.statements @ List.flatten (List.map fst norm_cases) in
      { statements = previous_statements @ [switch_statement]; expression = None }
    
    (* ----- T R Y - C A T C H ----- *)
    (* TODO *)
    | loc, Ast.Statement.Try {block; handler; finalizer; _} -> 
      let norm_block = normalize_statement (block_to_statement block) in
      let block' = norm_block.statements in
      
      (* process catch clause *)
      let (handler', norm_handler) = match handler with 
        | Some (loc, {Ast.Statement.Try.CatchClause.body; _}) -> 
          (* TODO : patterns over param *)
          let norm_param = empty_normalization in
          let norm_body = normalize_statement (block_to_statement body) in
          let body = norm_body.statements in

          (* build catch statement *)
          let location = Location.convert_flow_loc loc in
          let catch_statement = Statement.Catch.build location "TODO" body in 

          (Some catch_statement, { statements = norm_param.statements; expression = None})
        | None -> (None, empty_normalization)
      in

      let finalizer' = match finalizer with
        | Some finalizer -> let norm_finalizer = normalize_statement (block_to_statement finalizer) in 
                            Some norm_finalizer.statements
        | None           -> None
      in

      (* build try statement*)
      let location = Location.convert_flow_loc loc in
      let try_statement = Statement.Try.build location block' handler' finalizer' in

      (* return *)
      {statements = norm_handler.statements @ [try_statement]; expression = None}

    (* ----- V A R I A B L E   D E C L A R A T I O N ----- *)
    | _, Ast.Statement.VariableDeclaration _ (* {kind; declarations; _} *) -> 

      (* TODO : different identifier patterns *)
      empty_normalization
    
    | _ -> empty_normalization

and normalize_expression (expr : ('a, 'b) Ast.Expression.t) : normalization_return =
  match expr with
  (* ----- L I T E R A L ----- *)
  | loc, Ast.Expression.StringLiteral {value; raw; _} -> 
    let location = Location.convert_flow_loc loc in
    let value' = Expression.Literal.String value in 
    (* build null literal expression *)
    let string_expression = Expression.Literal.build location value' raw in 
    {statements = []; expression = Some string_expression}

  | loc, Ast.Expression.NumberLiteral {value; raw; _} -> 
    let location = Location.convert_flow_loc loc in
    let value' = Expression.Literal.Number value in 
    (* build null literal expression *)
    let string_expression = Expression.Literal.build location value' raw in 
    {statements = []; expression = Some string_expression}

  | loc, Ast.Expression.BigIntLiteral {value; raw; _} -> 
    let location = Location.convert_flow_loc loc in
    let value = Expression.Literal.BigInt value in 
    (* build null literal expression *)
    let string_expression = Expression.Literal.build location value raw in 
    {statements = []; expression = Some string_expression}

  | loc, Ast.Expression.BooleanLiteral {value; _} -> 
    let location = Location.convert_flow_loc loc in
    let value' = Expression.Literal.Boolean value in 
    let raw = if value then "true" else "false" in 
    (* build null literal expression *)
    let string_expression = Expression.Literal.build location value' raw in 
    {statements = []; expression = Some string_expression}

  | loc, Ast.Expression.NullLiteral _ -> 
    let location = Location.convert_flow_loc loc in
    let value = Expression.Literal.Null () in
    (* build null literal expression *)
    let null_expression = Expression.Literal.build location value "null" in
    { statements = []; expression = Some null_expression}
  
  (* ----- T E M P L A T E    L I T E R A L ----- *)
  | _, Ast.Expression.TemplateLiteral _ -> empty_normalization 

  (* ----- I D E N T I F I E R ----- *)
  | _, Ast.Expression.Identifier (loc, { name; _ }) -> 
    (* build identifier expression *)
    let location = Location.convert_flow_loc loc in 
    let identifier_expression = Expression.Identifier.build location name in
    { statements = []; expression = Some identifier_expression}

  (* ----- L O G I C A L ----- *)
  (* TODO *)
  | _, Ast.Expression.Logical _ -> empty_normalization
  
  (* ----- B I N A R Y ----- *)
  (* TODO *)
  | _, Ast.Expression.Binary _ -> empty_normalization
  
  (* ----- U N A R Y ----- *)
  (* TODO *)
  | _, Ast.Expression.Unary _ -> empty_normalization

  (* ----- T H I S ----- *)
  | loc, Ast.Expression.This _ -> 
    (* build this expression *)
    let location = Location.convert_flow_loc loc in
    let this_expression = Expression.This.build location in
    {statements = []; expression = Some this_expression}

   
  | _ ->
    let value = Expression.Literal.String "dummy" in
    let expression = Expression.Literal.build Location.empty value "dummy" in 
    {statements = []; expression = Some expression}

and normalize_switch_case (loc, {Ast.Statement.Switch.Case.test; consequent; _}) : Location.t Statement.t list * Location.t Statement.Switch.Case.t = 
  let (test_stmts, test') = match test with 
    | Some test' ->
      let norm_test = normalize_expression test' in
      norm_test.statements, norm_test.expression
    | None -> [], None
  in
  let norm_consequent = List.map normalize_statement consequent in
  let consequent' = flat_statements norm_consequent in

  (* build case *)
  let location = Location.convert_flow_loc loc in
  let switch_case = Statement.Switch.Case.build location test' consequent' in
  (test_stmts, switch_case)

and flat_statements (returns : normalization_return list) : Location.t Statement.t list =
  let statements = List.map (fun norm_return -> norm_return.statements) returns in 
  List.flatten statements

and flat_expressions = ()

and block_to_statement (loc, {Ast.Statement.Block.body; comments}) : ('a, 'b) Ast.Statement.t =
  let block_info = Ast.Statement.Block {
    body = body;
    comments = comments;
  } in 
  (loc, block_info);;


  

