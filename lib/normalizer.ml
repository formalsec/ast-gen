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

type ('M, 'T) generic_left =
  | LeftDeclaration of ('M * ('M, 'T) Ast.Statement.VariableDeclaration.t)
  | LeftPattern of ('M, 'T) Ast.Pattern.t


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
      let while_stmt = Statement.While.build (loc_f loc) (Option.get test_expr) body_stmts in

      (* TODO : normWhileStatement performs some computations over the norm_test.statements *)
      (test_stmts @ [while_stmt])
    
    (* --------- D O - W H I L E --------- *)
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

      let dowhile_stmt = Statement.While.build loc test_expr (body_stmts @ update) in 
      setup @ [dowhile_stmt]

    (* --------- F O R --------- *)
    | loc, Ast.Statement.For {init; test; update; body; _} -> 
      let loc = loc_f loc in 
      let true_val = Expression.Literal.build loc (Expression.Literal.Boolean true) "true" in 

      let init_stmts, init_expr = map_default normalize_init ([], None) init in
      let new_init = if List.length init_stmts > 0 then init_stmts else Option.to_list (Option.map Expression.to_statement init_expr) in 
      
      let test_stmts, test_expr = map_default ne ([], Some true_val) test in 
      let updt_stmts, _         = map_default ne ([], None) update in 
      let body_stmts = ns body in 

      (* TODO : graph.js iterates over the test_stmts to find the test variable and add it to the body of the while for some reason *)
      let for_stmt = Statement.While.build loc (Option.get test_expr) (body_stmts @ updt_stmts) in 
      
      new_init @ test_stmts @ [for_stmt]
    
    
    (* --------- F O R - I N --------- *)
    | loc, Ast.Statement.ForIn {left; right; body; each; _} -> 
      let left = match left with
        | LeftDeclaration decl -> LeftDeclaration decl
        | LeftPattern pat -> LeftPattern pat
      in
      let left_stmts, left_decl = normalize_for_left left in 
      let right_stmts, right_expr = ne right in 
      let body_stmts = ns body in
      
      let for_stmt = Statement.ForIn.build (loc_f loc) left_decl (Option.get right_expr) (left_stmts @ body_stmts) each in 
      right_stmts @ [for_stmt]

    (* --------- F O R - O F --------- *)
    | loc, Ast.Statement.ForOf {left; right; body; await; _} -> 
      let left = match left with
        | LeftDeclaration decl -> LeftDeclaration decl
        | LeftPattern pat -> LeftPattern pat
      in
      let left_stmts, left_decl = normalize_for_left left in 
      let right_stmts, right_expr = ne right in 
      let body_stmts = ns body in
      
      let for_stmt = Statement.ForOf.build (loc_f loc) left_decl (Option.get right_expr) (left_stmts @ body_stmts) await in 
      right_stmts @ [for_stmt]

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
    
    (* --------- W I T H --------- *)
    | loc, Ast.Statement.With {_object; body; _} ->
      let obj_stmts, obj_expr = ne _object in 
      let body_stmts = ns body in 

      let with_stmt = Statement.With.build (loc_f loc) (Option.get obj_expr) body_stmts in
      obj_stmts @ [with_stmt]
    
    (* --------- L A B E L --------- *)
    | loc, Ast.Statement.Labeled {label; body; _} ->
      let label' = convert_identifier label in
      let body_stmts = ns body in

      let labeled_stmt = Statement.Labeled.build (loc_f loc) label' body_stmts in
      [labeled_stmt]

    (* --------- V A R I A B L E   D E C L A R A T I O N --------- *)
    | loc, Ast.Statement.VariableDeclaration {kind; declarations; _} ->
      let kind' : Statement.VarDecl.kind = match kind with 
        | Var -> _var  | Let -> _let  | Const -> _const 
      in

      let assign_stmts, ids = List.split (List.map 
        (fun (_, {Ast.Statement.VariableDeclaration.Declarator.id; init; _}) -> 
          (* get id name into ids list if the init expression
          is not specified (e.g.: var x;)*)
          let is_id, _id  = is_identifier id in 
          let ids = if is_id then Option.to_list _id else [] in 

          map_default (normalize_assignment id None) ([], ids) init
        ) declarations) 
      in 

      let decls = List.map (fun id -> snd (createVariableDeclaration ~kind:kind' ~objId:(Id id) None (loc_f loc))) (List.flatten ids) in 
      List.flatten decls @ List.flatten assign_stmts
    
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
      
    (* --------- B R E A K --------- *)
    | loc, Ast.Statement.Break {label; _} -> 
      let label' = Option.map convert_identifier label in 
      let break_stmt = Statement.Break.build (loc_f loc) label' in 
      [break_stmt]
    
    (* --------- C O N T I N U E --------- *)
    | loc, Ast.Statement.Continue {label; _} -> 
      let label' = Option.map convert_identifier label in 
      let continue_stmt = Statement.Continue.build (loc_f loc) label' in 
      [continue_stmt]

    (* --------- D E B U G G E R --------- *)
    | loc, Ast.Statement.Debugger _ ->
      let debugger_stmt = Statement.Debugger.build (loc_f loc) in 
      
      [debugger_stmt]

    (* --------- E X P O R T   D E F A U L T   D E C L A R A T I O N --------- *)
    | loc, Ast.Statement.ExportDefaultDeclaration {declaration; _} ->
      let decl_stmts, decl_expr = normalize_default_declaration declaration in 

      let export_stmt = Statement.ExportDefaultDecl.build (loc_f loc) (Option.get decl_expr) in 
      decl_stmts @ [export_stmt]

    (* --------- E X P O R T   N A M E D   D E C L A R A T I O N --------- *)
    | loc, ExportNamedDeclaration {declaration; specifiers; source; _ } -> 
      let loc = loc_f loc in 
      let source' = Option.map get_string source in 

      let decl_stmts = map_default (normalize_named_declaration loc source') [] declaration in 
      let spcf_stmts = map_default (normalize_specifiers loc source') [] specifiers in 

      decl_stmts @ spcf_stmts
    
    (* --------- A S S I G N   F U N C T I O N ---------*)
    | loc, Ast.Statement.FunctionDeclaration {id; params; body; _} -> fst (normalize_function context loc id params body)


    (* --------- S T A T E M E N T   E X P R E S S I O N ---------*)
    | _, Ast.Statement.Expression {expression; _} -> 
      let stmts, expr = ne expression in 
      stmts @ Option.to_list (Option.map Expression.to_statement expr)
    
    | _, Ast.Statement.Empty _ -> []

    | loc, _ -> 
      let loc_info = Loc.debug_to_string loc in
      failwith ("Unknown statement type to normalize (object on " ^ loc_info ^ ")")
    
and normalize_expression (context : context) (expr : ('M, 'T) Ast.Expression.t) : norm_expr_t =
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

  (* --------- S E Q U E N C E --------- *)
  | loc, Ast.Expression.Sequence {expressions; _} -> 
    let stmts, exprs = List.split (List.map ne expressions) in 
    let sequence = Expression.Sequence.build (loc_f loc) (List.map Option.get exprs) in 
    
    List.flatten stmts, Some sequence

  (* --------- T A G G E D   T E M P L A T E --------- *)
  | loc, Ast.Expression.TaggedTemplate {tag; quasi=(qloc, quasi'); _} ->
    let tag_stmts, tag_expr = ne tag in 
    let qsi_stmts, qsi_expr = ne (qloc, Ast.Expression.TemplateLiteral quasi') in 
    (* convert quasi back to a template literal *)
    let qsi_expr = match qsi_expr with Some (_, Expression.TemplateLiteral tl) -> tl | _ -> failwith "failed to convert quasi to template literal"in 

    let tagged_template = Expression.TaggedTemplate.build (loc_f loc) (Option.get tag_expr) qsi_expr in 
    tag_stmts @ qsi_stmts, Some tagged_template 

  (* --------- Y I E L D --------- *)
  | loc, Ast.Expression.Yield {argument; delegate; _} -> 
    let arg_stmts, arg_expr = map_default ne ([], None) argument in 
    let yield = Expression.Yield.build (loc_f loc) arg_expr delegate in 
    
    arg_stmts, Some yield

  (* --------- C O N D I T I O N A L --------- *)
  | loc, Ast.Expression.Conditional {test; consequent; alternate; _} ->
    let test_stmts, test_expr = ne test in
    let cnsq_stmts, cnsq_expr = ne consequent in 
    let altr_stmts, altr_expr = ne alternate in 

    let conditional = Expression.Conditional.build (loc_f loc) (Option.get test_expr) (Option.get cnsq_expr) (Option.get altr_expr) in 

    test_stmts @ cnsq_stmts @ altr_stmts, Some conditional
  
  (* --------- A S S I G N   S I M P L E --------- *)
  | _, Ast.Expression.Assignment {operator; left; right; _} ->

    let operator' = Option.map Operator.Assignment.translate operator in
    let assign_stmts, _ = normalize_assignment left operator' right  in 

    (* TODO : graph.js normalizer has some special cases depending on the parent *)
    assign_stmts, None 

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

and normalize_assignment (left : ('M, 'T) Ast.Pattern.t) (op : Operator.Assignment.t option) (right : ('M, 'T) Ast.Expression.t) : norm_stmt_t * m Identifier.t list = 
  let ne = normalize_expression in
  let is_id, id = is_identifier left in  
  let context = if is_id then {identifier = id; is_assignment = true} else empty_context in
  
  let init_stmts, init_expr = ne context right in
  let pat_stmts, ids = 
    if not (is_id && is_special_assignment right) then 
      normalize_pattern (Option.get init_expr) left op
    else 
      (* right expression is a special assignment so when it got 
         normalized it already created a special assignment node 
         (no need to recreate another) *)
      [], [Option.get id]
  in 

  init_stmts @ pat_stmts, ids
  
and normalize_pattern (expr : m Expression.t) (pattern : (Loc.t, Loc.t) Ast.Pattern.t) (op : Operator.Assignment.t option) : norm_stmt_t * m Identifier.t list =
  match pattern with 
    | loc, Identifier {name; _} -> 
      let id = convert_identifier name in 
      let assign = Statement.AssignSimple.build (loc_f loc) op id expr in 
      [assign], [id]
    
    | _, Array {elements; _} -> let assigns, ids = List.split (List.mapi (
      fun i elem ->
        match elem with 
          | Ast.Pattern.Array.Element (loc, {argument; _}) ->
            let loc = loc_f loc in 
            let index = Expression.Literal.build loc (Expression.Literal.BigInt (Some (Int64.of_int i))) (string_of_int i) in
            
            (* simplify generated code *)
            let is_id, id = is_identifier argument in
            if not is_id then 
              let id, decl = createVariableDeclaration None loc in 
              let assign = Statement.AssignMember.build loc id expr index in 
              
              let stmts, ids = normalize_pattern (Identifier.to_expression id) argument op in 
              decl @ [assign] @ stmts, ids
            else 
              let assign = Statement.AssignMember.build loc (Option.get id) expr index in 
              [assign], Option.to_list id

          | Hole _ -> [], [] (* just ignore *)

          | RestElement (loc, {argument; _}) -> 
            let loc = loc_f loc in 
            let index = Expression.Literal.build loc (Expression.Literal.BigInt (Some (Int64.of_int i))) (string_of_int i) in
            (* generate expr.slice(i) *)
            let slide_id, slice_decl = createVariableDeclaration None loc in 
            let slice = Identifier.to_expression (Identifier.build loc "slice") in 
            let member = Statement.AssignMember.build loc slide_id expr slice in 
            
            (* simplify generated code *)
            let is_id, id = is_identifier argument in
            if not is_id then 
              let id, decl = createVariableDeclaration None loc in 
              let call = Statement.AssignFunCall.build loc id (Identifier.to_expression slide_id) [index] in 
              let stmts, ids = normalize_pattern (Identifier.to_expression id) argument op in 

              slice_decl @ [member] @ decl @ [call] @ stmts, ids
            else 
              let call = Statement.AssignFunCall.build loc (Option.get id) (Identifier.to_expression slide_id) [index] in 
              slice_decl @ [member] @ [call], Option.to_list id

      ) elements) in
      List.flatten assigns, List.flatten ids

    
    | _, Object {properties; _ } -> let assigns, ids = List.split (List.map (
      fun property -> match property with 
        | Ast.Pattern.Object.Property (loc, {key; pattern; _}) -> 
          let loc = loc_f loc in 
          let obj_key = to_object_key key in 
          let _, key_expr = normalize_property_key obj_key in 

          (* simplify generated code *)
          let is_id, id = is_identifier pattern in
          if not is_id then
            let id, decl = createVariableDeclaration None loc in 
            let assign = Statement.AssignMember.build loc id expr (Option.get key_expr) in 
            
            let stmts, ids = normalize_pattern (Identifier.to_expression id) pattern op in 
            decl @ [assign] @ stmts, ids
          else
            let assign = Statement.AssignMember.build loc (Option.get id) expr (Option.get key_expr) in 
            [assign], Option.to_list id

        (* TODO : restelement not implemented *)
        | RestElement _ -> failwith "restelement not implemented"
      ) properties) in 
      List.flatten assigns, List.flatten ids
    | _ -> failwith "no other patterns were implemented yet"

and is_identifier (pattern : ('M, 'T) Ast.Pattern.t) : bool * m Identifier.t option =
  match pattern with
  | _, Identifier {name; _} -> true,  Some (convert_identifier name)
  | _                       -> false, None

and to_object_key (key : ('M, 'T) Ast.Pattern.Object.Property.key) : ('M, 'T) Ast.Expression.Object.Property.key = 
  match key with
    | StringLiteral lit -> StringLiteral lit
    | NumberLiteral lit -> NumberLiteral lit
    | BigIntLiteral lit -> BigIntLiteral lit
    | Identifier id     -> Identifier id
    | Computed comp     -> Computed comp

and to_var_decl (stmt : m Statement.t) : m Statement.VarDecl.t =
  match stmt with
    | _, Statement.VarDecl decl -> decl
    | _ -> failwith "tried to conver statement to variable declaration but it isn't possible"

and normalize_alternate (_, {Ast.Statement.If.Alternate.body; _}) : norm_stmt_t = 
  normalize_statement empty_context body

and normalize_default_declaration (declaration : ('M, 'T) Ast.Statement.ExportDefaultDeclaration.declaration) : norm_expr_t = 
  match declaration with 
    | Declaration stmt ->
      let stmt' = normalize_statement empty_context stmt in 

      (* find identifier that represents the exported 
         statement (must be a function or a class) *)
      let norm_stmt = List.hd (List.rev stmt') in 
      let expr = match norm_stmt with 
        | _, Statement.AssignFunction {left; _} -> Identifier.to_expression left
        (* TODO : same for classes *)
        | _ -> failwith "export statement was not of type function or class"
      in
      stmt', Some expr
    
    | Expression expr -> 
      normalize_expression empty_context expr

and normalize_named_declaration (loc : m) (source : string option) (declatation : ('M, 'T) Ast.Statement.t) : norm_stmt_t = 
  let decl_stmts = normalize_statement empty_context declatation in 
  (* convert all declarations into exports *)
  let exports = List.filter_map (fun (_, stmt) -> 
    match stmt with 
    | Statement.VarDecl {id; _} ->
      if not (id_is_generated id) then
        let export = Statement.ExportNamedDecl.build loc (Some id) None false source  in 
        Some export  
      else 
        None
    | _ -> None 
  ) decl_stmts in 

  decl_stmts @ exports

and normalize_specifiers (loc : m) (source : string option) (specifier : ('M, 'T) Ast.Statement.ExportNamedDeclaration.specifier ) : norm_stmt_t = 
  match specifier with 
    | ExportSpecifiers specifiers -> 
      List.map (fun (_, {Ast.Statement.ExportNamedDeclaration.ExportSpecifier.local; exported}) -> 
        let local' = Some (convert_identifier local) in
        let exported' = Option.map convert_identifier exported in 
        Statement.ExportNamedDecl.build loc local' exported' false source
      ) specifiers 
    
    (* ExportAllDeclaration case *)
    | ExportBatchSpecifier (_, id) -> 
      let exported' = Option.map convert_identifier id in
      let export = Statement.ExportNamedDecl.build loc None exported' true source in
      [export] 

and normalize_for_left (left : ('M, 'T) generic_left) : norm_stmt_t * m Statement.VarDecl.t = 
  let ns = normalize_statement empty_context in 
  match left with
    | LeftDeclaration (loc, decl) -> 
      let decl_stmts = ns (loc, Ast.Statement.VariableDeclaration decl) in 
      [], to_var_decl (List.hd decl_stmts)
    
    | LeftPattern pattern -> 
      let id, decl_stmts = createVariableDeclaration None Location.empty in
      let stmts, _ = normalize_pattern (Identifier.to_expression id) pattern None in 
      stmts, to_var_decl (List.hd decl_stmts)

and normalize_case (loc, {Ast.Statement.Switch.Case.test; consequent; _}) : m Statement.Switch.Case.t * norm_stmt_t = 
  let ns = normalize_statement empty_context in
  let ne = normalize_expression empty_context in

  let test_stmts, test_expr = map_default ne ([], None) test in
  let cnsq_stmts = List.flatten (List.map ns consequent) in 

  let case = Statement.Switch.Case.build (loc_f loc) test_expr cnsq_stmts in
  (case, test_stmts)

and normalize_catch (loc, { Ast.Statement.Try.CatchClause.param; body; _}) : norm_stmt_t * m Statement.Catch.t option = 
    let is_id, id = map_default is_identifier (false, None) param in
    let param' = if is_id then id else failwith "param is not an identifier" in 
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
  (* TODO : param can be spread element or other patterns (maybe do like the normalize_for_left ) *)
  let is_id, id = is_identifier argument in 
  let argument' = if is_id then Option.get id else failwith "argument is not an identifier" in 
  
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
  let ne = normalize_expression empty_context in 
  let process_func_property key loc func = 
    let key_stmts, key_expr = nk key in 
    let val_stmts, val_expr = ne (loc, Ast.Expression.Function func) in 
    let property = Statement.AssignObject.Property.build _init (Option.get key_expr) (Option.get val_expr) None in
    key_stmts @ val_stmts, property
  in 
  match property with
    | Property (_, Init {key; value; shorthand}) ->
      let key_stmts, key_expr = nk key in 
      let val_stmts, val_expr = ne value in 
      let property = Statement.AssignObject.Property.build _init (Option.get key_expr) (Option.get val_expr) (Some shorthand) in
      key_stmts @ val_stmts, property

    | Property (_, Method {key; value=(loc, func); _}) -> process_func_property key loc func
    | Property (_, Get {key; value=(loc, func); _}) -> process_func_property key loc func
    | Property (_, Set {key; value=(loc, func); _}) -> process_func_property key loc func
    (* TODO : spread property not implemented *)
    | _ -> failwith "spread property not implemented"

and normalize_property_key (key : ('M, 'T) Ast.Expression.Object.Property.key) : norm_expr_t = 
  let ne = normalize_expression empty_context in 
  match key with
  | StringLiteral (loc, literal) -> ne (loc, Ast.Expression.StringLiteral literal)
  | NumberLiteral (loc, literal) -> ne (loc, Ast.Expression.NumberLiteral literal)
  | BigIntLiteral (loc, literal) -> ne (loc, Ast.Expression.BigIntLiteral literal)
  | Identifier ((loc, _) as id)  -> ne (loc, Ast.Expression.Identifier id)
  (* TODO : private name and computed key not implemented *)
  | _ -> failwith "private name and computed key not implemented"

and normalize_init (init : ('M, 'T) Ast.Statement.For.init) : norm_expr_t =
  let ne = normalize_expression empty_context in 
  let ns = normalize_statement empty_context in
  match init with 
    | InitDeclaration (loc, decl) -> ns (loc, Ast.Statement.VariableDeclaration decl), None 
    | InitExpression expr -> ne expr

and convert_identifier ((loc, {name; _}) : ('M, 'T) Ast.Identifier.t) : m Identifier.t = 
  Identifier.build (loc_f loc) name

and build_template_element (loc, {Ast.Expression.TemplateLiteral.Element.value={raw; cooked}; tail}) : m Expression.TemplateLiteral.Element.t =
  Expression.TemplateLiteral.Element.build (loc_f loc) raw cooked tail

and get_identifier (id : m Identifier.t option) (loc : m) : m Identifier.t = 
  map_default identity (Identifier.build_random loc) id

and get_string ((_, {Ast.StringLiteral.value; _})) : string = value

and id_is_generated ((_, {is_generated; _}) : m Identifier.t) : bool = is_generated

and createVariableDeclaration ?(objId : name_or_id = Name None) ?(kind : Statement.VarDecl.kind = _const) (obj : m Expression.t option) (loc : m) : m Identifier.t * norm_stmt_t =
  let id = match objId with 
    | Name objId -> map_default (Identifier.build loc) (Identifier.build_random loc) objId
    | Id objId   -> objId 
  in 

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


  

