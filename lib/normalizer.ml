module Ast = Flow_ast
open GraphJS 

type normalization_return = {
  statements : Location.t Statement.t list;
  expression : Location.t Expression.t option; 
};;

let empty_normalization : normalization_return = {statements = []; expression = None};;

let rec normalize ((loc, _) as program : ('M, 'T) Ast.Program.t) : Location.t Program.t = 
  let normalized_program = normalize_program program in
  let location = Location.convert_flow_loc loc in 
  let program' = Program.build location normalized_program.statements in
  program';

and normalize_program (_ , ({ Ast.Program.statements; _ })) : normalization_return =
  let statements' = List.map normalize_statement statements in
  let flat_stmts = List.fold_left (fun accumulator normalized_stmt -> normalized_stmt.statements @ accumulator) [] statements' in

  {statements = flat_stmts; expression = None};

and normalize_statement (stmt : ('a, 'b) Ast.Statement.t) : normalization_return =
  match stmt with
    | loc, Ast.Statement.If {test; consequent; alternate; _} ->
      let normalized_test = normalize_expression test in
      let test' = match normalized_test.expression with
        | Some expression -> expression;
        | None -> failwith "if test statment normalization didnt return an expression"
      in
      let consequent' = normalize_statement consequent in
      let alternate' = match alternate with 
        | Some (_, {body; _}) -> normalize_statement body
        | None -> empty_normalization
      in
      
      (* build if statement *)
      let location = Location.convert_flow_loc loc in 
      (* TODO : alternate should be None if alternate is None 
        and the normalization result otherwise *)
      let if_statement = Statement.If.build location test' consequent'.statements (Some alternate'.statements) in
      
      (* also need to add if statemetn to the statements list *)
      {statements = normalized_test.statements @ [if_statement]; expression = None}; 
    | _ -> empty_normalization

and normalize_expression (expr : ('a, 'b) Ast.Expression.t) : normalization_return =
  match expr with
  | _ ->
    let expression = Expression.Literal.build Location.empty 1 in 
    {statements = []; expression = Some expression};;


  

