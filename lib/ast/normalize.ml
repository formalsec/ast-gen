module Ast' = Flow_ast
open Auxiliary.Functions
open Grammar

(* --------- A L I A S E S --------- *)
type norm_stmt_t = m Statement.t list;;
type norm_expr_t = m Statement.t list * m Expression.t option;;

let file_path : string ref = ref ""

let _const = Statement.VarDecl.Const;;
let _let = Statement.VarDecl.Let;;
let _var = Statement.VarDecl.Var;;


type name_or_id =
  | Name of string option
  | Id   of m Identifier.t

type property = 
  | Static  of string * bool
  | Dynamic of m Expression.t

type ('M, 'T) generic_left =
  | LeftDeclaration of ('M * ('M, 'T) Ast'.Statement.VariableDeclaration.t)
  | LeftPattern of ('M, 'T) Ast'.Pattern.t


  
let func_call = "FunctionCall";;



(* --------- C O N T E X T --------- *)
type context = { 
  parent_type : string;
  identifier : m Identifier.t option;
  is_assignment : bool;
  has_op : bool;
  is_declaration : bool;
  is_expr_stmt : bool;
  is_expression : bool;

  high_order_expr : bool;
  has_side_effects : bool;
}

let empty_context : context = {parent_type = ""; identifier = None; is_assignment = false; is_declaration = false; has_op = false; is_expr_stmt = false; is_expression = false; high_order_expr = true; has_side_effects = false} 

let rec program (loc , { Ast'.Program.statements; _ }) (file : string): m Program.t = 
  file_path := file;

  let body = List.flatten (List.map (normalize_statement empty_context) statements) in
  let program = Program.build (Location.convert_flow_loc !file_path loc) body in

  program;


and normalize_statement (context : context) (stmt : ('M, 'T) Ast'.Statement.t) : norm_stmt_t =
  let ns  = normalize_statement empty_context in
  let ne  = normalize_expression empty_context in
  let nec = normalize_expression in 
  let loc_f = Location.convert_flow_loc !file_path in

  (* reset context *)
  let context = {context with is_expression = false} in 
  
  match stmt with
    (* --------- B L O C K --------- *)
    | _, Ast'.Statement.Block {body; _} -> 
      let body_stmts = List.map ns body in
      List.flatten body_stmts;
    
    (* --------- I F --------- *)
    | loc, Ast'.Statement.If {test; consequent; alternate; _} ->
      let test_stmts, test_expr = ne test in
      let cons_stmts = ns consequent in
      let altn_stmts = Option.map normalize_alternate alternate in
      let if_stmt = Statement.If.build (loc_f loc) (Option.get test_expr) cons_stmts altn_stmts in
      
      test_stmts @ [if_stmt]
    
    (* --------- W H I L E --------- *)
    | loc, Ast'.Statement.While { test; body; _ } -> 
      let test_stmts, test_expr = ne test in
      let body_stmts = ns body in
      
      (* update test condition inside loop body *)
      let update_stmts = List.filter (not << is_declaration) test_stmts in 
      let while_stmt = Statement.While.build (loc_f loc) (Option.get test_expr) (body_stmts @ update_stmts) in

      (test_stmts @ [while_stmt])
    
    (* --------- D O - W H I L E --------- *)
    | loc, Ast'.Statement.DoWhile {body; test; _} ->
      let loc = loc_f loc in 
      let test_stmts, test_expr = ne test in 
      let body_stmts = ns body in

      let true_val = Expression.Literal.build loc (Expression.Literal.Boolean true) "true" in 
      let setup, update, test_expr = if test_stmts = [] 
        then
          (* simple test expression: false, 1, x, ...*)
          let id, decl = createVariableDeclaration (Some true_val) loc in
          let update = Statement.AssignSimple.build loc id (Option.get test_expr) in 
          decl, [update], Identifier.to_expression id 
        else
          (* complex test expression that was reduced to an identifier *)
          let test_expr = Option.get test_expr in
          let decls, assings = List.partition is_declaration test_stmts in
          let setup = Statement.AssignSimple.build loc (Identifier.from_expression test_expr) true_val in 
          List.map (change_kind _let) decls @ [setup], assings, test_expr 
      in

      let dowhile_stmt = Statement.While.build loc test_expr (body_stmts @ update) in 
      setup @ [dowhile_stmt]

    (* --------- F O R --------- *)
    | loc, Ast'.Statement.For {init; test; update; body; _} -> 
      let loc = loc_f loc in 
      let true_val = Expression.Literal.build loc (Expression.Literal.Boolean true) "true" in 

      let init_stmts, _ = map_default normalize_init ([], None) init in
      
      let test_stmts, test_expr = map_default ne ([], Some true_val) test in 
      let updt_stmts, _         = map_default ne ([], None) update in 
      let body_stmts = ns body in 

      (* update test condition inside loop body *)
      let updt_stmts = updt_stmts @ List.filter (not << is_declaration) test_stmts in 
      let for_stmt = Statement.While.build loc (Option.get test_expr) (body_stmts @ updt_stmts) in 
      
      init_stmts @ test_stmts @ [for_stmt]
    
    
    (* --------- F O R - I N --------- *)
    | loc, Ast'.Statement.ForIn {left; right; body; each; _} -> 
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
    | loc, Ast'.Statement.ForOf {left; right; body; await; _} -> 
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
    | loc, Ast'.Statement.Switch  { discriminant; cases; _ } -> 
      let dicr_stmts, dicr_expr = ne discriminant in 
      (* normalize cases *)
      let cases', tests_stmts = List.split (List.map normalize_case cases) in
      let switch_stmt = Statement.Switch.build (loc_f loc) (Option.get dicr_expr) cases' in

      (* statements generated from the normalization of the 
         discriminant and the test expression of each case*)
      let previous_stmts = dicr_stmts @ List.flatten tests_stmts in
      previous_stmts @ [switch_stmt]
    
    (* --------- T R Y - C A T C H --------- *)
    | loc, Ast'.Statement.Try {block; handler; finalizer; _} -> 
      let block_stmts = ns (block_to_statement block) in
      let fnlzr_stmts = Option.map (ns << block_to_statement) finalizer in

      (* process catch clause *)
      let handler' = map_default normalize_catch (None) handler in
    
      (* build try statement*)
      let try_stmt = Statement.Try.build (loc_f loc) block_stmts handler' fnlzr_stmts in
      
      [try_stmt]
    
    (* --------- W I T H --------- *)
    | loc, Ast'.Statement.With {_object; body; _} ->
      let obj_stmts, obj_expr = ne _object in 
      let body_stmts = ns body in 

      let with_stmt = Statement.With.build (loc_f loc) (Option.get obj_expr) body_stmts in
      obj_stmts @ [with_stmt]
    
    (* --------- L A B E L --------- *)
    | loc, Ast'.Statement.Labeled {label; body; _} ->
      let label' = normalize_identifier label in
      let body_stmts = ns body in

      let labeled_stmt = Statement.Labeled.build (loc_f loc) label' body_stmts in
      [labeled_stmt]

    (* --------- V A R I A B L E   D E C L A R A T I O N --------- *)
    | loc, Ast'.Statement.VariableDeclaration {kind; declarations; _} ->
      let kind' = translate_kind kind in 

      let new_context = {context with is_declaration = true} in 
      let assign_stmts, ids = List.split (List.map 
        (fun (_, {Ast'.Statement.VariableDeclaration.Declarator.id; init; _}) -> 
          (* get id name into ids list if the init expression
          is not specified (e.g.: var x;)*)
          let is_id, _id  = is_identifier id in 
          let ids = if is_id then Option.to_list _id else [] in 

          map_default (normalize_assignment new_context id None) ([], ids) init
        ) declarations) 
      in 

      let decls = List.map (fun id -> snd (createVariableDeclaration ~kind:kind' ~objId:(Id id) None (loc_f loc))) (List.flatten ids) in 
      List.flatten decls @ List.flatten assign_stmts
    
    (* --------- R E T U R N --------- *)
    | loc, Ast'.Statement.Return {argument; _} -> 
      let arg_stmts, arg_expr = map_default ne ([], None) argument in
      let return_stmt = Statement.Return.build (loc_f loc) arg_expr in 

      arg_stmts @ [return_stmt]

    (* --------- T H R O W --------- *)
    | loc, Ast'.Statement.Throw {argument; _} -> 
      let arg_stmts, arg_expr = ne argument in
      let throw_stmt = Statement.Throw.build (loc_f loc) arg_expr in 

      arg_stmts @ [throw_stmt]
      
    (* --------- B R E A K --------- *)
    | loc, Ast'.Statement.Break {label; _} -> 
      let label' = Option.map normalize_identifier label in 
      let break_stmt = Statement.Break.build (loc_f loc) label' in 
      [break_stmt]
    
    (* --------- C O N T I N U E --------- *)
    | loc, Ast'.Statement.Continue {label; _} -> 
      let label' = Option.map normalize_identifier label in 
      let continue_stmt = Statement.Continue.build (loc_f loc) label' in 
      [continue_stmt]

    (* --------- D E B U G G E R --------- *)
    | loc, Ast'.Statement.Debugger _ ->
      let debugger_stmt = Statement.Debugger.build (loc_f loc) in 
      
      [debugger_stmt]

    (* --------- E X P O R T   D E F A U L T   D E C L A R A T I O N --------- *)
    | loc, Ast'.Statement.ExportDefaultDeclaration {declaration; _} ->
      let decl_stmts, decl_expr = normalize_default_declaration declaration in 

      let export_stmt = Statement.ExportDefaultDecl.build (loc_f loc) (Option.get decl_expr) in 
      decl_stmts @ [export_stmt]

    (* --------- E X P O R T   N A M E D   D E C L A R A T I O N --------- *)
    | loc, Ast'.Statement.ExportNamedDeclaration {declaration; specifiers; source; _ } -> 
      let loc = loc_f loc in 
      let source' = Option.map get_string source in 

      let decl_stmts = map_default (normalize_named_declaration loc source') [] declaration in 
      let spcf_stmts = map_default (normalize_exp_specifiers loc source') [] specifiers in 

      decl_stmts @ spcf_stmts

    (* --------- I M P O R T   D E C L A R A T I O N --------- *)
    | loc, Ast'.Statement.ImportDeclaration {source; default; specifiers; _} -> 
      let loc = loc_f loc in 
      let source' = get_string source in 
      let def_stmts = map_default (normalize_default loc source') [] default in 
      let spf_stmts = map_default (normalize_imp_specifiers loc source') [] specifiers in 
      
      def_stmts @ spf_stmts
      
    
    (* --------- F U N C T I O N   D E C L A R A T I O N ---------*)
    | loc, Ast'.Statement.FunctionDeclaration _function -> fst (normalize_function context loc _function)

    (* --------- C L A S S   D E C L A R A T I O N ---------*)
    | loc, Ast'.Statement.ClassDeclaration _class -> fst (normalize_class context loc _class)

    (* --------- S T A T E M E N T   E X P R E S S I O N ---------*)
    | _, Ast'.Statement.Expression {expression; _} -> 
      let new_context = {context with is_expr_stmt = true} in 
      let stmts, expr = nec new_context expression in 

      let expr' = match expr with 
        | Some (loc, expr) -> let expr' : m Statement.t = loc, Statement.Expression (loc, expr) in [expr']
        | _ -> []
      in 
 
      stmts @ expr'
      (* (match expr with 
        | Some (_, Expression.Literal {value=Expression.Literal.String lit; _}) -> 
          if lit = "use strict" then [Statement.UseStrict.build (Location.empty ())] else stmts
        | _ -> stmts
      ) *)
    
    | _, Ast'.Statement.Empty _ -> []

    | loc, _ -> 
      let loc_info = Loc.debug_to_string loc in
      failwith ("[ERROR] Unknown statement type to normalize (object on " ^ loc_info ^ ")")
    
and normalize_expression (context : context) (expr : ('M, 'T) Ast'.Expression.t) : norm_expr_t =
  let nec = normalize_expression in 
  let loc_f = Location.convert_flow_loc !file_path in
  
  (* reset context *)
  let is_expr_stmt   = context.is_expr_stmt in 
  let context        = {(check_side_effects expr context) with is_expr_stmt = false; is_expression = true;} in
  let empty_context' = {empty_context with has_side_effects = context.has_side_effects; high_order_expr = context.high_order_expr} in 

  match expr with
  (* --------- L I T E R A L --------- *)
  | loc, Ast'.Expression.StringLiteral {value; raw; _} -> 
    let value' = Expression.Literal.String value in 
    let literal = Expression.Literal.build (loc_f loc) value' raw in 
    ([], Some literal)

  | loc, Ast'.Expression.NumberLiteral {value; raw; _} -> 
    let value' = Expression.Literal.Number value in 
    let literal = Expression.Literal.build (loc_f loc) value' raw in 
    ([], Some literal)

  | loc, Ast'.Expression.BigIntLiteral {value; raw; _} -> 
    let value = Expression.Literal.BigInt value in 
    let literal = Expression.Literal.build (loc_f loc) value raw in 
    ([], Some literal)

  | loc, Ast'.Expression.BooleanLiteral {value; _} -> 
    let value' = Expression.Literal.Boolean value in 
    let raw = string_of_bool value in
    let literal = Expression.Literal.build (loc_f loc) value' raw in 
    ([], Some literal)

  | loc, Ast'.Expression.RegExpLiteral {pattern; flags; raw; _} ->
    let value' = Expression.Literal.Regex {pattern = pattern; flags = flags} in 
    let literal = Expression.Literal.build (loc_f loc) value' raw in 
    ([], Some literal)

  | loc, Ast'.Expression.NullLiteral _ -> 
    let value = Expression.Literal.Null () in
    let literal = Expression.Literal.build (loc_f loc) value "null" in
    ([], Some literal);
  
  (* --------- T E M P L A T E    L I T E R A L --------- *)
  | loc, Ast'.Expression.TemplateLiteral {quasis; expressions; _} -> 
    let quasis' = List.map build_template_element quasis in 
    let stmts, exprs = List.split (List.map (nec empty_context') expressions) in
    let exprs = List.map Option.get exprs in 

    (* TODO : some applications based on the parent *)
    let literal = Expression.TemplateLiteral.build (loc_f loc) quasis' exprs in
    (List.flatten stmts, Some literal)

  (* --------- I D E N T I F I E R --------- *)
  | _, Ast'.Expression.Identifier (loc, { name; _ }) -> 
    let location = loc_f loc in
    if context.has_side_effects then 
      (* if expression has side effects (assignments) wrap variables around new random identifiers*)
      let identifier = Identifier.to_expression (Identifier.build location name) in 
      let wraper_id, decl = createVariableDeclaration (Some identifier ) location in 
      
      (decl, Some (Identifier.to_expression wraper_id))
    else 
      let identifier = Identifier.to_expression (Identifier.build location name) in 
      ([], Some identifier)

  (* --------- L O G I C A L --------- *)
  | loc, Ast'.Expression.Logical {operator; left; right; _} -> 
    let operator' = Operator.Binary.translate_logical operator in
    let left_stmt, left_expr = nec empty_context' left in  
    let right_stmt, right_expr = nec empty_context' right in  

    let loc = loc_f loc in
    let id = if not context.has_op then get_identifier loc context.identifier else Identifier.build_random loc in
    let assign = Statement.AssignBinary.build loc id operator' (Option.get left_expr) (Option.get right_expr) in 
    
    (* force declaration if it was an operator *)
    if not context.is_assignment || context.has_op then
      let _, decl = createVariableDeclaration None loc ~objId:(Id id) in 
      (left_stmt @ right_stmt @ decl @ [assign] , Some (Identifier.to_expression id))
    else 
      (left_stmt @ right_stmt @ [assign], Some (Identifier.to_expression id))
  
  (* --------- B I N A R Y --------- *)
  | loc, Ast'.Expression.Binary {operator; left; right; _} -> 
    let operator' = Operator.Binary.translate_binary operator in
    let left_stmt, left_expr = nec empty_context' left in  
    let right_stmt, right_expr = nec empty_context' right in

    let loc = loc_f loc in
    let id = if not context.has_op then get_identifier loc context.identifier else Identifier.build_random loc in
    let assign = Statement.AssignBinary.build loc id operator' (Option.get left_expr) (Option.get right_expr) in 
    
    (* force declaration if it was an operator *)
    if not context.is_assignment || context.has_op then
      let _, decl = createVariableDeclaration None loc ~objId:(Id id) in 
      (left_stmt @ right_stmt @ decl @ [assign] , Some (Identifier.to_expression id))
    else 
      (left_stmt @ right_stmt @ [assign], Some (Identifier.to_expression id))
  
  (* --------- D E L E T E --------- *)
  | loc, Ast'.Expression.Unary {operator=Ast'.Expression.Unary.Delete; argument=(_, Member {_object; property; _}); _} -> 
    let obj_stmts, obj_expr = nec empty_context' _object in 
    let prop_stmts, prop_expr = normalize_member_property property in 

    let loc = loc_f loc in
    let id = if not context.has_op then get_identifier loc context.identifier else Identifier.build_random loc in
    let assign = match prop_expr with 
      | Static  (prop, lit) -> Statement.StaticDelete.build  loc id (Option.get obj_expr) prop lit
      | Dynamic  prop       -> Statement.DynamicDelete.build loc id (Option.get obj_expr) prop     in

    if not context.is_assignment || context.has_op then
      let _, decl = createVariableDeclaration None loc ~objId:(Id id) in
      (obj_stmts @ prop_stmts @ decl @ [assign] , Some (Identifier.to_expression id))
    else 
      (obj_stmts @ prop_stmts @ [assign], Some (Identifier.to_expression id))
    
  (* --------- U N A R Y --------- *)
  | loc, Ast'.Expression.Unary {operator; argument; _} -> 
    let operator' = Operator.Unary.translate operator in 
    let arg_stmts, arg_expr = nec empty_context' argument in

    let loc = loc_f loc in
    let id = if not context.has_op then get_identifier loc context.identifier else Identifier.build_random loc in
    let assign = Statement.AssignUnary.build loc id operator' (Option.get arg_expr) in 
    
    if not context.is_assignment || context.has_op then
      let _, decl = createVariableDeclaration None loc ~objId:(Id id) in 
      (arg_stmts @ decl @ [assign] , Some (Identifier.to_expression id))
    else 
      (arg_stmts @ [assign], Some (Identifier.to_expression id))

  
  (* --------- U P D A T E --------- *)
  | loc, Ast'.Expression.Update {operator; argument = ((_, Member {_object; property; _}) as argument); prefix; _} -> 
    (* special update of object proprerty *)
    let operator' = Operator.Binary.translate_update operator in
    let arg_stmts, arg_expr = nec empty_context' argument in 
    let obj_stmts, obj_expr = nec empty_context' _object in 
    let prop_stmts, prop_expr = normalize_member_property property in
    
    let loc = loc_f loc in
    let one = Expression.Literal.build loc (Expression.Literal.Number (Int.to_float 1)) "1" in 

    (* let v1 = Number(x.p) *)
    let old_value_id, v1_decl = createVariableDeclaration None loc in
    let number_wrap = Statement.AssignFunCall.build loc old_value_id (Identifier.build loc "Number") [Option.get arg_expr] in 
    (* v2 = v1 + 1 *)
    let arg_id, v2_decl = createVariableDeclaration None loc in 
    let update = Statement.AssignBinary.build loc arg_id operator' (Identifier.to_expression old_value_id) one in 
    
    (* x.p = v2 *)
    let assign = match prop_expr with 
      | Static  (prop, lit) -> Statement.StaticUpdate.build loc (Option.get obj_expr) prop lit (Identifier.to_expression arg_id)
      | Dynamic  prop       -> Statement.DynmicUpdate.build loc (Option.get obj_expr) prop     (Identifier.to_expression arg_id)
    in

    let id = if prefix 
      then arg_id        (* ++x *)
      else old_value_id  (* x++ *)
    in
    (arg_stmts @ obj_stmts @ prop_stmts @ v1_decl @ [number_wrap] @ v2_decl @ [update; assign] , Some (Identifier.to_expression id))

  | loc, Ast'.Expression.Update {operator; argument; prefix; _} -> 
    let operator' = Operator.Binary.translate_update operator in
    let arg_stmts, arg_expr = nec empty_context' argument in 

    let loc = loc_f loc in
    let one = Expression.Literal.build loc (Expression.Literal.Number (Int.to_float 1)) "1" in 

    (* let v1 = Number(x) *)
    let old_value_id, decl = createVariableDeclaration None loc in
    let number_wrap = Statement.AssignFunCall.build loc old_value_id (Identifier.build loc "Number") [Option.get arg_expr] in 
    (* x = v1 + 1 *)
    let arg_id = Identifier.from_expression (Option.get arg_expr) in
    let update = Statement.AssignBinary.build loc arg_id operator' (Identifier.to_expression old_value_id) one in 
    
    let id = if prefix 
      then arg_id        (* ++x *)
      else old_value_id  (* x++ *)
    in
    (arg_stmts @ decl @ [number_wrap; update] , Some (Identifier.to_expression id))
   

  (* --------- T H I S --------- *)
  | loc, Ast'.Expression.This _ -> 
    let this = Expression.This.build (loc_f loc) in
    ([], Some this)

  (* --------- S U P E R --------- *)
  | loc, Ast'.Expression.Super _ -> 
    let loc = loc_f loc in 
    if context.parent_type = func_call then
      (* var v1 = this.prototype *)
      let class_proto, proto_decl = createVariableDeclaration None loc in 
      let this = Expression.This.build loc in 
      let assign_proto = Statement.StaticLookup.build loc class_proto this "prototype" false in 
      
      (* var v2 = v1.constructor *)
      let super_constr, constr_decl = createVariableDeclaration None loc in 
      let assign_constr = Statement.StaticLookup.build loc super_constr (Identifier.to_expression class_proto) "constructor" false in
      
      proto_decl @ [assign_proto] @ constr_decl @ [assign_constr], Some (Identifier.to_expression super_constr)
    else
      failwith "[ERROR] Super used ouside implemented scope"

  (* --------- S E Q U E N C E --------- *)
  | loc, Ast'.Expression.Sequence {expressions; _} -> 
    let loc = loc_f loc in 

    let stmts, exprs = List.split (List.map (nec empty_context') expressions) in 
    let ids, decls = List.split (List.map (fun expr -> createVariableDeclaration expr loc) exprs) in 
    let last_expr = Identifier.to_expression (List.hd (List.rev ids)) in 
   
    List.flatten stmts @ List.flatten decls, Some last_expr

  (* --------- Y I E L D --------- *)
  | loc, Ast'.Expression.Yield {argument; delegate; _} -> 
    let loc = loc_f loc in 
    let id = if not context.has_op then get_identifier loc context.identifier else Identifier.build_random loc in

    let arg_stmts, arg_expr = map_default (nec empty_context') ([], None) argument in 
    let yield = Statement.Yield.build loc id arg_expr delegate in 
    
    (* check if yield is done as a statement or an expression *)
    if not context.is_assignment || context.has_op then 
      let _, decl = createVariableDeclaration None loc ~objId:(Id id) in 
      (decl @ arg_stmts @ [yield] , Some (Identifier.to_expression id))
    else
      arg_stmts @ [yield], Some (Identifier.to_expression id)
    

  (* --------- C O N D I T I O N A L --------- *)
  | loc, Ast'.Expression.Conditional {test; consequent; alternate; _} ->
    let loc = loc_f loc in 
    let id, decl = createVariableDeclaration None loc in

    let test_stmts, test_expr = nec empty_context' test in
    let cnsq_stmts, cnsq_expr = nec empty_context' consequent in 
    let cnsq_assign = Statement.AssignSimple.build loc id (Option.get cnsq_expr) in 
    
    let altr_stmts, altr_expr = nec empty_context' alternate in 
    let altr_assign = Statement.AssignSimple.build loc id (Option.get altr_expr) in 
    
    let conditional = Statement.If.build loc (Option.get test_expr) (cnsq_stmts @ [cnsq_assign]) (Some (altr_stmts @ [altr_assign])) in
    decl @ test_stmts @ [conditional], Some (Identifier.to_expression id)
  
  (* --------- A S S I G N   S I M P L E --------- *)
  | _, Ast'.Expression.Assignment {operator; left; right; _} ->
    let operator' = Option.map Operator.Assignment.translate operator in
    let assign_stmts, _ = normalize_assignment {context with is_expr_stmt = false} left operator' right  in 

    (* check if the assignment is done as a statement or an expression *)
    if is_expr_stmt
      then assign_stmts, None
      else 
        let norm_stmts, norm_expr = get_pattern_expr left in 
        norm_stmts @ assign_stmts, norm_expr

  (* --------- A S S I G N   A R R A Y ---------*)
  | loc, Ast'.Expression.Array {elements; _} -> 
    let loc = loc_f loc in
    let id = if not context.has_op then get_identifier loc context.identifier else Identifier.build_random loc in
    let assign = Statement.AssignArray.build loc id (List.length elements) in

    let elems_stmts = List.mapi (normalize_array_elem empty_context' id) elements in 
    
    if not context.is_assignment || context.has_op then 
      let _, decl = createVariableDeclaration None loc ~objId:(Id id) in 
      (decl @ [assign] @ (List.flatten elems_stmts) , Some (Identifier.to_expression id))
    else
      [assign] @ (List.flatten elems_stmts), Some (Identifier.to_expression id)
  
  (* --------- A S S I G N   N E W ---------*)
  | loc, Ast'.Expression.New {callee; arguments; _} -> 
    let callee_stmts, callee_expr = nec empty_context' callee in
    let args_stmts, args_exprs = List.split (map_default (normalize_argument_list empty_context') [] arguments) in 
    let args_exprs = List.flatten (List.map Option.to_list args_exprs) in

    let loc = loc_f loc in
    let id = if not context.has_op then get_identifier loc context.identifier else Identifier.build_random loc in
    let assign = Statement.AssignNewCall.build loc id (Identifier.from_expression (Option.get callee_expr)) args_exprs in

    if not context.is_assignment || context.has_op then
      let _, decl = createVariableDeclaration None loc ~objId:(Id id) in
      (callee_stmts @ (List.flatten args_stmts) @ decl @ [assign] , Some (Identifier.to_expression id))
    else
      (callee_stmts @ (List.flatten args_stmts) @ [assign], Some (Identifier.to_expression id))

  (* --------- A S S I G N   M E M B E R ---------*)
  | loc, Ast'.Expression.Member {_object; property; _} -> 
    let obj_stmts, obj_expr = nec empty_context' _object in 
    let prop_stmts, prop_expr = normalize_member_property property in 

    let loc = loc_f loc in
    let id = if not context.has_op then get_identifier loc context.identifier else Identifier.build_random loc in

    (* Statement.AssignMember.build loc id (Option.get obj_expr) (Option.get prop_expr) *)
    let assign = match prop_expr with 
      | Static  (prop, lit) -> Statement.StaticLookup.build loc id (Option.get obj_expr) prop lit
      | Dynamic  prop       -> Statement.DynmicLookup.build loc id (Option.get obj_expr) prop
    in

    (* TODO : it has some more restrictions more than being an assignment, like is function call and new expression *)
    if not context.is_assignment || context.has_op then
      let _, decl = createVariableDeclaration None loc ~objId:(Id id) in
      (obj_stmts @ prop_stmts @ decl @ [assign] , Some (Identifier.to_expression id))
    else
      (obj_stmts @ prop_stmts @ [assign], Some (Identifier.to_expression id))

  (* --------- A S S I G N   O B J E C T ---------*)
  | loc, Ast'.Expression.Object {properties; _} -> 
      let loc = loc_f loc in

      let id = if not context.has_op then get_identifier loc context.identifier else Identifier.build_random loc in
      let empty_obj = Statement.AssignObject.build loc id in
      let props_stmts = List.flatten (List.map (normalize_property empty_context' id) properties) in 
      
      if not context.is_assignment || context.has_op then
        let _, decl = createVariableDeclaration None loc ~objId:(Id id) in
        (decl @ [empty_obj] @ props_stmts , Some (Identifier.to_expression id))
      else
        ([empty_obj] @ props_stmts, Some (Identifier.to_expression id))

  (* --------- A S S I G N   F U N C   C A L L ---------*)
  | loc, Ast'.Expression.Call {callee = (_, Member {_object; property; _}); arguments; _} -> 
    (* callee representation*)
    let obj_stmts, obj_expr = nec empty_context' _object in 
    let prop_stmts, prop_expr = normalize_member_property property in 
    (* arguments *)
    let args_stmts, args_exprs = List.split (normalize_argument_list empty_context' arguments) in 
    let args_exprs = List.flatten (List.map Option.to_list args_exprs) in

    let loc = loc_f loc in
    let id = if not context.has_op then get_identifier loc context.identifier else Identifier.build_random loc in
    let assign = match prop_expr with 
      | Static  (prop, lit) -> Statement.AssignMetCallStatic.build loc id (Option.get obj_expr) prop lit args_exprs
      | Dynamic  prop       -> Statement.AssignMetCallDynmic.build loc id (Option.get obj_expr) prop     args_exprs in

    if not context.is_assignment || context.has_op then
      let _, decl = createVariableDeclaration None loc ~objId:(Id id) in
      (obj_stmts @ prop_stmts @ (List.flatten args_stmts) @ decl @ [assign] , Some (Identifier.to_expression id))
    else 
      (obj_stmts @ prop_stmts @ (List.flatten args_stmts) @ [assign], Some (Identifier.to_expression id))

  | loc, Ast'.Expression.Call {callee; arguments; _} -> 
    let new_context = {empty_context' with parent_type = func_call} in 
    
    let callee_stmts, callee_expr = nec new_context callee in
    let args_stmts, args_exprs = List.split (normalize_argument_list new_context arguments) in 
    let args_exprs = List.flatten (List.map Option.to_list args_exprs) in

    let loc = loc_f loc in
    let id = get_identifier loc context.identifier in
    let assign = Statement.AssignFunCall.build loc id (Identifier.from_expression (Option.get callee_expr)) args_exprs in

    if not context.is_assignment then
      let _, decl = createVariableDeclaration None loc ~objId:(Id id) in
      (callee_stmts @ (List.flatten args_stmts) @ decl @ [assign] , Some (Identifier.to_expression id))
    else 
      (callee_stmts @ (List.flatten args_stmts) @ [assign], Some (Identifier.to_expression id))

  (* --------- A S S I G N   F U N C T I O N ---------*)
  | loc, Ast'.Expression.ArrowFunction _function 
  | loc, Ast'.Expression.Function _function      -> normalize_function context loc _function
  
  (* --------- C L A S S   E X P R E S S I O N ---------*)
  | loc, Ast'.Expression.Class _class -> normalize_class context loc _class

  | loc, _ -> 
    let loc_info = Loc.debug_to_string loc in
    failwith ("[ERROR] Unknown expression type to normalize (object on " ^ loc_info ^ ")")

and normalize_assignment (context : context) (left : ('M, 'T) Ast'.Pattern.t) (op : Operator.Assignment.t option) (right : ('M, 'T) Ast'.Expression.t) : norm_stmt_t * m Identifier.t list = 
  let ne = normalize_expression in
  let is_id, id = is_identifier left in  
  let new_context = if is_id then {context with identifier = id; is_assignment = true; has_op = Option.is_some op; is_expr_stmt = false} else context in
  
  let init_stmts, init_expr = ne new_context right in
  let pat_stmts, ids = normalize_pattern (Option.get init_expr) left op (is_special_assignment right) in 

  init_stmts @ pat_stmts, ids
  
  
and normalize_pattern (expression : m Expression.t) (pattern : ('M, 'T) Ast'.Pattern.t) (op : Operator.Assignment.t option) (is_special_assignment : bool): norm_stmt_t * m Identifier.t list =
  let loc_f = Location.convert_flow_loc !file_path in
  match pattern with 
    | loc, Identifier {name; _} -> 
      let id = normalize_identifier name in 
      let assign = if Option.is_some op 
        then Some (build_operation id expression (Option.get op))
        else if is_special_assignment && is_redundant_assignment id expression then None
        else Some (Statement.AssignSimple.build (loc_f loc) id expression) in 

      Option.to_list assign, [id]
    
    | _, Array {elements; _} -> let assigns, ids = List.split (List.mapi (
      fun i elem ->
        match elem with 
          | Ast'.Pattern.Array.Element (loc, {argument; _}) ->
            let loc = loc_f loc in 
            let index = Expression.Literal.build loc (Expression.Literal.BigInt (Some (Int64.of_int i))) (string_of_int i) in
            
            (* simplify generated code *)
            let is_id, id = is_identifier argument in
            if not is_id then 
              let id, decl = createVariableDeclaration None loc in 
              let assign = Statement.DynmicLookup.build loc id expression index in 
              
              let stmts, ids = normalize_pattern (Identifier.to_expression id) argument op is_special_assignment in 
              decl @ [assign] @ stmts, ids
            else 
              let assign = Statement.DynmicLookup.build loc (Option.get id) expression index in 
              [assign], Option.to_list id

          | Hole _ -> [], [] (* just ignore *)

          | RestElement (loc, {argument; _}) -> 
            let loc = loc_f loc in 
            let index = Expression.Literal.build loc (Expression.Literal.BigInt (Some (Int64.of_int i))) (string_of_int i) in
            (* generate expr.slice(i) *)
            let slide_id, slice_decl = createVariableDeclaration None loc in 
            let member = Statement.StaticLookup.build loc slide_id expression "slice" false in 
            
            (* simplify generated code *)
            let is_id, id = is_identifier argument in
            if not is_id then 
              let id, decl = createVariableDeclaration None loc in 
              let call = Statement.AssignFunCall.build loc id slide_id [index] in 
              let stmts, ids = normalize_pattern (Identifier.to_expression id) argument op is_special_assignment in 

              slice_decl @ [member] @ decl @ [call] @ stmts, ids
            else 
              let call = Statement.AssignFunCall.build loc (Option.get id) slide_id [index] in 
              slice_decl @ [member] @ [call], Option.to_list id

      ) elements) in
      List.flatten assigns, List.flatten ids

    
    | _, Object {properties; _ } -> let assigns, ids = List.split (List.map (
      fun property -> match property with 
        | Ast'.Pattern.Object.Property (loc, {key; pattern; _}) -> 
          let loc = loc_f loc in 
          let obj_key = to_object_key key in 
          let _, key_expr = normalize_property_key obj_key in 

          (* simplify generated code *)
          let is_id, id = is_identifier pattern in
          if not is_id then
            let id, decl = createVariableDeclaration None loc in 
            let assign = match key_expr with 
              | Static  (prop, lit) -> Statement.StaticLookup.build loc id expression prop lit
              | Dynamic  prop       -> Statement.DynmicLookup.build loc id expression prop
            in 
            let stmts, ids = normalize_pattern (Identifier.to_expression id) pattern op is_special_assignment in 
            decl @ [assign] @ stmts, ids
          else
            let assign = match key_expr with 
              | Static  (prop, lit) -> Statement.StaticLookup.build loc (Option.get id) expression prop lit
              | Dynamic  prop       -> Statement.DynmicLookup.build loc (Option.get id) expression prop
            in 
            [assign], Option.to_list id

        (* TODO : restelement not implemented *)
        | RestElement _ -> failwith "[ERROR] Rest element not implemented"
      ) properties) in 
      List.flatten assigns, List.flatten ids
    
    | loc, Expression (_, Member {_object; property; _}) -> 
      let loc = loc_f loc in 
      let obj_stmts, obj_expr = normalize_expression empty_context _object in 
      let prop_stmts, prop_expr = normalize_member_property property in 
      
      let stmts, expr = map_default 
        (fun op -> 
          let mem_id, mem_decl = createVariableDeclaration None loc in 
          let mem_assign = match prop_expr with 
            | Static  (prop, lit) -> Statement.StaticLookup.build loc mem_id (Option.get obj_expr) prop lit
            | Dynamic  prop       -> Statement.DynmicLookup.build loc mem_id (Option.get obj_expr) prop
          in
          let assign_op = build_operation mem_id expression op in 
          mem_decl @ [mem_assign; assign_op], Identifier.to_expression mem_id
        ) ([], expression) op in 
      
      let assign = match prop_expr with 
        | Static  (prop, lit) -> Statement.StaticUpdate.build loc (Option.get obj_expr) prop lit expr
        | Dynamic  prop       -> Statement.DynmicUpdate.build loc (Option.get obj_expr) prop     expr
      in 
      obj_stmts @ prop_stmts @ stmts @ [assign], []

    | _ -> failwith "[ERROR] Pattern expression not implemented"

and is_redundant_assignment ((_, {name; _}) : m Identifier.t) (expr : m Expression.t) : bool =
    let left_name = name in 
    match expr with 
      | _, Identifier {name; _} -> left_name = name 
      | _ -> false 

and is_identifier (pattern : ('M, 'T) Ast'.Pattern.t) : bool * m Identifier.t option =
  match pattern with
  | _, Identifier {name; _} -> true,  Some (normalize_identifier name)
  | _                       -> false, None

and get_pattern_expr (pattern : ('M, 'T) Ast'.Pattern.t) : norm_expr_t = 
  let loc_f = Location.convert_flow_loc !file_path in
  match pattern with 
    | _, Identifier {name; _} -> 
      [], Some ((Identifier.to_expression << normalize_identifier) name)
    
    | _, Expression (loc, Member {_object; property; _}) ->
      let loc = loc_f loc in 
      let id, decl = createVariableDeclaration None loc in
      
      let obj_stmts, obj_expr = normalize_expression empty_context _object in 
      let prop_stmts, prop_expr = normalize_member_property property in 
      let assign = match prop_expr with 
        | Static  (prop, lit) -> Statement.StaticLookup.build loc id (Option.get obj_expr) prop lit
        | Dynamic  prop       -> Statement.DynmicLookup.build loc id (Option.get obj_expr) prop     in 
    
      decl @ obj_stmts @ prop_stmts @ [assign], Some (Identifier.to_expression id)
    
    | _ -> [], None

and to_object_key (key : ('M, 'T) Ast'.Pattern.Object.Property.key) : ('M, 'T) Ast'.Expression.Object.Property.key = 
  match key with
    | StringLiteral lit -> StringLiteral lit
    | NumberLiteral lit -> NumberLiteral lit
    | BigIntLiteral lit -> BigIntLiteral lit
    | Identifier id     -> Identifier id
    | Computed comp     -> Computed comp

and to_var_decl (stmt : m Statement.t) : m Statement.VarDecl.t =
  match stmt with
    | _, Statement.VarDecl decl -> decl
    | _ -> failwith "[ERROR] Tried to convert statement to variable declaration but it isn't possible"

and normalize_alternate (_, {Ast'.Statement.If.Alternate.body; _}) : norm_stmt_t = 
  normalize_statement empty_context body

and normalize_default_declaration (declaration : ('M, 'T) Ast'.Statement.ExportDefaultDeclaration.declaration) : norm_expr_t = 
  match declaration with 
    | Declaration stmt ->
      let stmt' = normalize_statement empty_context stmt in 

      (* find identifier that represents the exported 
         statement (must be a function or a class) *)
      let export_exprs = List.filter_map (
        fun stmt -> 
          match stmt with 
            | _, Statement.VarDecl {id; _} -> if not (Identifier.is_generated id) then Some (Identifier.to_expression id) else None
            | _ -> None
      ) stmt' in 
      
      let expr = if List.length export_exprs = 1 then List.hd export_exprs else failwith "[ERROR] More than one expression found to export" in 
      stmt', Some expr
    
    | Expression expr -> 
      normalize_expression empty_context expr

and normalize_named_declaration (loc : m) (source : string option) (declatation : ('M, 'T) Ast'.Statement.t) : norm_stmt_t = 
  let decl_stmts = normalize_statement empty_context declatation in 
  (* convert all declarations into exports *)
  let exports = List.filter_map (fun (_, stmt) -> 
    match stmt with 
    | Statement.VarDecl {id; _} ->
      if not (Identifier.is_generated id) then
        let export = Statement.ExportNamedDecl.build loc (Some id) None false source  in 
        Some export  
      else 
        None
    | _ -> None 
  ) decl_stmts in 

  decl_stmts @ exports

and normalize_exp_specifiers (loc : m) (source : string option) (specifier : ('M, 'T) Ast'.Statement.ExportNamedDeclaration.specifier ) : norm_stmt_t = 
  match specifier with 
    | ExportSpecifiers specifiers -> 
      List.map (fun (_, {Ast'.Statement.ExportNamedDeclaration.ExportSpecifier.local; exported}) -> 
        let local' = Some (normalize_identifier local) in
        let exported' = Option.map normalize_identifier exported in 
        Statement.ExportNamedDecl.build loc local' exported' false source
      ) specifiers 
    
    (* ExportAllDeclaration case *)
    | ExportBatchSpecifier (_, id) -> 
      let exported' = Option.map normalize_identifier id in
      let export = Statement.ExportNamedDecl.build loc None exported' true source in
      [export] 

and normalize_default (loc : m) (source : string) ({identifier; _} : ('M, 'T) Ast'.Statement.ImportDeclaration.default_identifier) : norm_stmt_t = 
  let identifier' = normalize_identifier identifier in 
  let import = Statement.ImportDecl.build_default loc source identifier' in 
  
  [import]

and normalize_imp_specifiers (loc : m) (source : string) (specifier : ('M, 'T) Ast'.Statement.ImportDeclaration.specifier) : norm_stmt_t = 
  match specifier with 
    | ImportNamedSpecifiers specifiers -> 
      List.map (fun {Ast'.Statement.ImportDeclaration.local; remote; _} -> 
        let local' = Option.map normalize_identifier local in 
        let remote' = Some (normalize_identifier remote) in 
        Statement.ImportDecl.build_specifier loc source local' remote' false 
      ) specifiers
       
    | ImportNamespaceSpecifier (_, id) -> 
      let local' = normalize_identifier id in 
      let import = Statement.ImportDecl.build_specifier loc source (Some local') None true in 
      [import]

and normalize_for_left (left : ('M, 'T) generic_left) : norm_stmt_t * m Statement.VarDecl.t = 
  match left with
    | LeftDeclaration (_, { Ast'.Statement.VariableDeclaration.kind; declarations; _}) ->
      let kind' = translate_kind kind in 
      let declaration = List.hd declarations in 
      let pattern = match declaration with _, {id; _} -> id in 
      
      let id, decl_stmts = createVariableDeclaration None (Location.empty ()) ~kind:kind' in
      let stmts, _ = normalize_pattern (Identifier.to_expression id) pattern None false in 
      stmts, to_var_decl (List.hd decl_stmts)

      
    | LeftPattern pattern -> 
      let id, decl_stmts = createVariableDeclaration None (Location.empty ()) in
      let stmts, _ = normalize_pattern (Identifier.to_expression id) pattern None false in 
      stmts, to_var_decl (List.hd decl_stmts)

and normalize_case (loc, {Ast'.Statement.Switch.Case.test; consequent; _}) : m Statement.Switch.Case.t * norm_stmt_t = 
  let ns = normalize_statement empty_context in
  let ne = normalize_expression empty_context in
  let loc_f = Location.convert_flow_loc !file_path in

  let test_stmts, test_expr = map_default ne ([], None) test in
  let cnsq_stmts = List.flatten (List.map ns consequent) in 

  let case = Statement.Switch.Case.build (loc_f loc) test_expr cnsq_stmts in
  (case, test_stmts)

and normalize_catch (loc, { Ast'.Statement.Try.CatchClause.param; body; _}) : m Statement.Try.Catch.t option = 
    let loc_f = Location.convert_flow_loc !file_path in
    let is_id, id = map_default is_identifier (false, None) param in
    let param' = if is_id then id else failwith "[ERROR] Param is not an identifier" in 
    let body_stmts = normalize_statement empty_context (block_to_statement body) in 

    let catch = Statement.Try.Catch.build (loc_f loc) param' body_stmts in
    Some catch

and normalize_array_elem (context : context) (array : m Identifier.t) (index : int) (element : ('M, 'T) Ast'.Expression.Array.element): norm_stmt_t = 
  let loc_f = Location.convert_flow_loc !file_path in
  match element with
    | Expression ((loc, _) as expr) -> 
      let stmts, expr = normalize_expression context expr in 
      let update_stmt = Statement.StaticUpdate.build (loc_f loc) (Identifier.to_expression array) (string_of_int index) true (Option.get expr) in 
      stmts @ [update_stmt]
    | Hole _ -> []
    | _ -> failwith "[ERROR] Cannot process spread array element"

and normalize_argument_list (context : context) (_, {Ast'.Expression.ArgList.arguments; _}) : norm_expr_t list = 
  List.map (normalize_argument context) arguments

and normalize_argument (context : context) (arg : ('M, 'T) Ast'.Expression.expression_or_spread) : norm_expr_t = 
  (* TODO : other cases *)
  match arg with
    | Ast'.Expression.Expression expr -> normalize_expression context expr 
    | Ast'.Expression.Spread (_, {argument; _}) -> normalize_expression context argument


and normalize_function (context : context) (loc : Loc.t) ({id; params=(_, {params; _}); body; _} : ('M, 'T) Ast'.Function.t): norm_expr_t =
  let loc_f = Location.convert_flow_loc !file_path in

  let loc = loc_f loc in 
  let id = if not context.has_op 
    then get_identifier loc (if Option.is_some id then Option.map normalize_identifier id else context.identifier)
    else Identifier.build_random loc in
  
  let norm_pattern_stmts, params_stmts, params_exprs = split3 (List.map normalize_param params) in
  let body_stmts = normalize_func_body body in 
  let assign = Statement.AssignFunction.build loc id params_exprs (List.flatten norm_pattern_stmts @ body_stmts) in 
  
  if not context.is_assignment || context.has_op then 
    let _, decl = createVariableDeclaration None loc ~objId:(Id id) in 
    (List.flatten params_stmts @ decl @ [assign], Some (Identifier.to_expression id))
  else
    (List.flatten params_stmts @ [assign], Some (Identifier.to_expression id)) 

and normalize_param (loc, {Ast'.Function.Param.argument; default} : ('M, 'T) Ast'.Function.Param.t) : m Statement.t list * m Statement.t list * m Statement.AssignFunction.Param.t  = 
  let loc_f = Location.convert_flow_loc !file_path in

  (* convert argument pattern into an identifier and if needed a   
    set of statements that decompose the pattern into a identifier *)
  let norm_pattern_stmts, argument' = 
    match argument with
      | _, Identifier {name; _} -> [], normalize_identifier name
      | _                       -> let id = Identifier.build_random (Location.empty ()) in
                                   let stmts, _ = normalize_pattern (Identifier.to_expression id) argument None false in 
                                   stmts, id 
    in 

  let def_stmts, def_expr = map_default (normalize_expression empty_context) ([], None) default in
  let param = Statement.AssignFunction.Param.build (loc_f loc) argument' def_expr in
  (norm_pattern_stmts, def_stmts, param)

and normalize_func_body (body : ('M, 'T) Ast'.Function.body) : norm_stmt_t =
  let loc_f = Location.convert_flow_loc !file_path in
  match body with 
    | Ast'.Function.BodyBlock body-> 
      normalize_statement empty_context (block_to_statement body) 

    | Ast'.Function.BodyExpression ((loc, _) as body) -> 
      let body_stmts, body_expr = normalize_expression empty_context body in 
      let return = Statement.Return.build (loc_f loc) body_expr in 
      body_stmts @ [return]

and normalize_class (context : context) (loc : Loc.t) ({id; body=(_, {body; _}); extends; (* implements; *) _} : ('M, 'T) Ast'.Class.t): norm_expr_t = 
  let loc_f = Location.convert_flow_loc !file_path in
  
  let loc = loc_f loc in 
  let id = if not context.has_op 
    then get_identifier loc (if Option.is_some id then Option.map normalize_identifier id else context.identifier) 
    else Identifier.build_random loc in

  let is_decl = context.is_declaration in 

  let exts_stmts, exts_expr = map_default (normalize_extend id) (no_extend id loc) extends in
  
  let constructor, body' = List.partition is_constructor body in 
  let constructor = if constructor != [] then Some (List.hd constructor) else None in 

  let cnstr_stmts = map_default (normalize_body_element is_decl id (Option.get exts_expr)) (empty_constructor is_decl id loc) constructor in 
  let body_stmts  = List.map (normalize_body_element is_decl id (Option.get exts_expr)) body' in  

  cnstr_stmts @ exts_stmts @ List.flatten body_stmts, Some (Identifier.to_expression id)

and empty_constructor (is_declaration : bool) (class_id : m Identifier.t) (loc : m) : norm_stmt_t = 
  let decl = if not is_declaration then snd (createVariableDeclaration ~objId:(Id class_id) None loc) else [] in 
  let cnstr_stmt = Statement.AssignFunction.build loc class_id [] [] in 
  decl @ [cnstr_stmt]

and normalize_body_element (is_declaration : bool) (class_id : m Identifier.t) (class_proto : m Expression.t) (element : ('M, 'T) Ast'.Class.Body.element) : norm_stmt_t = 
  let loc_f = Location.convert_flow_loc !file_path in
  match element with 
    | Method (_, {key; value=(loc, func); _}) -> 
      let id = get_key_identifier key in
      let is_constructor = is_specified_name id "constructor" in 
      
      if is_constructor then
        let new_context = {empty_context with is_assignment = true; identifier = Some class_id} in 
        
        let decl = if not is_declaration then snd (createVariableDeclaration ~kind:_let ~objId:(Id class_id) None (loc_f loc)) else [] in 
        let func_stmts, _ = normalize_function new_context loc func in 
        
        decl @ func_stmts
      else
        let func_stmts, func_expr = normalize_function empty_context loc func in 
        let assign = Statement.StaticUpdate.build (loc_f loc) class_proto (Identifier.get_name id) false (Option.get func_expr)  in 
        func_stmts @ [assign]

    | Property (loc, {key; value; _}) -> 
      let id = get_key_identifier key in 
      let val_stmts, val_expr = match value with 
        | Initialized expr -> normalize_expression empty_context expr

        (* TODO : should do something in this cases? *)
        | Uninitialized | Declared -> [], None
      in

      let assign = Option.map (Statement.StaticUpdate.build (loc_f loc) class_proto (Identifier.get_name id) false) val_expr  in 
      val_stmts @ Option.to_list assign 

    | PrivateField _ -> []

and get_key_identifier (key : ('M, 'T) Ast'.Expression.Object.Property.key) : m Identifier.t = 
  let loc_f = Location.convert_flow_loc !file_path in
  match key with 
    | StringLiteral ((loc, _) as str) -> Identifier.build (loc_f loc) (get_string str) 
    | Identifier id -> normalize_identifier id
    | PrivateName (loc, {name; _}) -> Identifier.build (loc_f loc) name
    | _ -> failwith "[ERROR] Class method key cannot be translated"


and is_constructor (element : ('M, 'T) Ast'.Class.Body.element) : bool =
  match element with 
    | Method (_, {key; _}) -> 
      let id = get_key_identifier key in 
      is_specified_name id "constructor"
    | _ -> false 

and is_specified_name ((_, {name; _}) : m Identifier.t) (specified_name : string) : bool = 
  name = specified_name

and normalize_extend (class_id : m Identifier.t) ((loc', {expr=(loc, _) as expr; _}) : ('M, 'T) Ast'.Class.Extends.t) : norm_expr_t = 
  let loc_f = Location.convert_flow_loc !file_path in
  let ext_stmts, ext_expr = normalize_expression empty_context expr in 
  
  let loc = loc_f loc in
  (* let v1 = new ext_expr(); *)
  let id, decl = createVariableDeclaration None loc  in 
  let super_init = Statement.AssignNewCall.build loc id (Identifier.from_expression (Option.get ext_expr)) [] in

  (* class_id.prototype = v1; *)
  let assign_proto = Statement.StaticUpdate.build (loc_f loc') (Identifier.to_expression class_id) "prototype" false (Identifier.to_expression id) in
  ext_stmts @ decl @ [super_init; assign_proto] , Some (Identifier.to_expression id)

and no_extend (class_id : m Identifier.t) (loc : m) : norm_expr_t =
  (* let v1 = X.prototype; *)
  let id, decl = createVariableDeclaration None loc  in 
  let assign = Statement.StaticLookup.build loc id (Identifier.to_expression class_id) "prototype" false in

  decl @ [assign], Some (Identifier.to_expression id)

and normalize_member_property (property : ('M, 'T) Ast'.Expression.Member.property) : m Statement.t list * property = 
  match property with
    (* --------- S T A T I C --------- *)
    | PropertyIdentifier (_, id) -> [], Static (id.name, false)
    | PropertyExpression (_, StringLiteral literal) ->  [], Static (literal.value, true)
    | PropertyExpression (_, NumberLiteral literal) ->  [], Static (literal.raw, true)
    | PropertyExpression (_, BigIntLiteral literal) ->  [], Static (literal.raw, true)
    | PropertyExpression (_, BooleanLiteral literal) -> [], Static (string_of_bool literal.value, true)
    | PropertyExpression (_, NullLiteral _) ->          [], Static ("null", true)

    (* --------- D Y N A M I C --------- *)
    | PropertyExpression expr -> 
      let stmts, expr = normalize_expression empty_context expr in 
      stmts, Dynamic (Option.get expr)
    
    (* TODO : private name not implemented*)
    | PropertyPrivateName _ -> failwith "[ERROR] Property private name not implemented"
  

and normalize_property (context : context) (obj_id : m Identifier.t) (property : ('M, 'T) Ast'.Expression.Object.property) : norm_stmt_t = 
  let nk = normalize_property_key in
  let nec = normalize_expression in 
  let loc_f = Location.convert_flow_loc !file_path in
  let obj_id = Identifier.to_expression obj_id in 

  let object_define_property (obj : m Expression.t) (property : m Expression.t) (value : m Expression.t) : m Statement.t list = 
    let loc = Location.empty () in
    let id, decl = createVariableDeclaration None loc in 
    let object_class = Identifier.to_expression (Identifier.build loc "Object") in 
    let arguments = [obj; property; value] in 

    let object_define_property = Statement.AssignMetCallStatic.build loc id object_class "defineProperty" false arguments in 
    decl @ [object_define_property]
  in

  match property with
    | Property (loc, Init {key; value; _}) ->
      let key_stmts, key_expr = nk key in 
      let val_stmts, val_expr = nec context value in 
      
      let set_prop = match key_expr with
        | Static  (prop, lit) -> Statement.StaticUpdate.build (loc_f loc) obj_id prop lit (Option.get val_expr)
        | Dynamic  prop       -> Statement.DynmicUpdate.build (loc_f loc) obj_id prop     (Option.get val_expr)
      in
      key_stmts @ val_stmts @ [set_prop]

    | Property (_, Method {key; value=(loc, func); _}) -> 
      let key_stmts, key_expr = nk key in 
      let val_stmts, val_expr = nec context (loc, Ast'.Expression.Function func) in 
      let set_prop = match key_expr with
        | Static  (prop, lit) -> Statement.StaticUpdate.build (loc_f loc) obj_id prop lit (Option.get val_expr)
        | Dynamic  prop       -> Statement.DynmicUpdate.build (loc_f loc) obj_id prop     (Option.get val_expr)
      in
      key_stmts @ val_stmts @ [set_prop]

    | Property (_, Get {key; value=(loc, func); _}) -> 
      let key_stmts, key_expr = nk key in 
      let val_stmts, val_expr = nec context (loc, Ast'.Expression.Function func) in 

      (* create get object *)
      let id, decl = createVariableDeclaration None (loc_f loc) in 
      let new_obj  = Statement.AssignObject.build (loc_f loc) id in 
      let set_get  = Statement.StaticUpdate.build (loc_f loc) (Identifier.to_expression id) "get" false (Option.get val_expr) in 

      let property = match key_expr with
        | Static  (prop, _) -> Expression.Literal.build (loc_f loc) (Expression.Literal.String prop) ("\"" ^ prop ^ "\"")
        | Dynamic  prop     -> prop
      in

      let set_prop = object_define_property obj_id property (Identifier.to_expression id) in 
      key_stmts @ val_stmts @ decl @ [new_obj; set_get] @ set_prop


    | Property (_, Set {key; value=(loc, func); _}) -> 
      let key_stmts, key_expr = nk key in 
      let val_stmts, val_expr = nec context (loc, Ast'.Expression.Function func) in 

      (* create get object *)
      let id, decl = createVariableDeclaration None (loc_f loc) in 
      let new_obj  = Statement.AssignObject.build (loc_f loc) id in 
      let set_get  = Statement.StaticUpdate.build (loc_f loc) (Identifier.to_expression id) "set" false (Option.get val_expr) in 

      let property = match key_expr with
        | Static  (prop, _) -> Expression.Literal.build (loc_f loc) (Expression.Literal.String prop) prop
        | Dynamic  prop     -> prop
      in

      let set_prop = object_define_property obj_id property (Identifier.to_expression id) in 
      key_stmts @ val_stmts @ decl @ [new_obj; set_get] @ set_prop

    (* TODO : spread property not implemented *)
    | _ -> failwith "[ERROR] Spread property not implemented"

and normalize_property_key (key : ('M, 'T) Ast'.Expression.Object.Property.key) : m Statement.t list * property = 
  match key with
    | StringLiteral (_, literal) -> [], Static (literal.value, true)
    | NumberLiteral (_, literal) -> [], Static (literal.raw  , true)
    | BigIntLiteral (_, literal) -> [], Static (literal.raw  , true)
    | Identifier    (_, id)      -> [], Static (id.name, false)
    
    (* TODO : private name and computed key not implemented *)
    | _ -> failwith "[ERROR] Private name and computed key not implemented"

and normalize_init (init : ('M, 'T) Ast'.Statement.For.init) : norm_expr_t =
  let ne = normalize_expression empty_context in 
  let ns = normalize_statement empty_context in
  match init with 
    | InitDeclaration (loc, decl) -> ns (loc, Ast'.Statement.VariableDeclaration decl), None 
    | InitExpression expr -> ne expr

and normalize_identifier ((loc, {name; _}) : ('M, 'T) Ast'.Identifier.t) : m Identifier.t = 
  Identifier.build (Location.convert_flow_loc !file_path loc) name

and build_template_element (loc, {Ast'.Expression.TemplateLiteral.Element.value={raw; cooked}; tail}) : m Expression.TemplateLiteral.Element.t =
  Expression.TemplateLiteral.Element.build (Location.convert_flow_loc !file_path loc) raw cooked tail

and get_identifier (loc : m) (id : m Identifier.t option) : m Identifier.t = 
  let random_id = lazy (Identifier.build_random loc) in
  map_default_lazy identity random_id id

and get_string ((_, {Ast'.StringLiteral.value; _})) : string = value

and check_side_effects (expr : ('M, 'T) Ast'.Expression.t) (context : context) : context = 
  let rec traverse_exprs (expr : ('M, 'T) Ast'.Expression.t) (context : context) (iteration : int) : context = 
    (* get expressions to visit next *)
    let to_process = match expr with 
      | _, Ast'.Expression.Logical {left; right; _}
      | _, Ast'.Expression.Binary {left; right; _}                      -> [left; right]
      | _, Ast'.Expression.Unary {argument; _}   
      | _, Ast'.Expression.Update {argument; _}                         -> [argument]
      | _, Ast'.Expression.Sequence {expressions; _}                    -> expressions
      | _, Ast'.Expression.Yield {argument; _}                          -> Option.to_list argument 
      | _, Ast'.Expression.Conditional {test; consequent; alternate; _} -> [test; consequent; alternate] 
      | _, Ast'.Expression.Member {_object; property=PropertyExpression expr; _} ->  [_object; expr]
      | _, Ast'.Expression.Array {elements; _} ->  
        List.filter_map (fun element -> match element with 
          | Ast'.Expression.Array.Expression expr -> Some expr
          | _ -> None
        ) elements

      | _, Ast'.Expression.Object {properties; _} ->  
        List.filter_map (function 
          | Ast'.Expression.Object.Property (_, Init {value; _}) -> Some value
          | _ -> None
        ) properties 
        
      
      | _ -> []
    in 

    (* update context *)
    let context = match expr with 
      | _, Ast'.Expression.Assignment _ -> if iteration > 0 then {context with has_side_effects = true} else context
      | _ -> context
    in
    List.fold_left (fun acc expr -> traverse_exprs expr acc (iteration+1)) context to_process
  in
  
  (* only check for side effects for the most high 
  order expression this is done to avoid repetition*)
  if context.high_order_expr then 
    let context = traverse_exprs expr context 0 in 
    {context with high_order_expr = false} 
  else
    context 

and createVariableDeclaration ?(objId : name_or_id = Name None) ?(kind : Statement.VarDecl.kind = _let) (obj : m Expression.t option) (loc : m) : m Identifier.t * norm_stmt_t =
  let id = match objId with 
    | Name objId -> map_default_lazy (Identifier.build loc) (lazy (Identifier.build_random loc)) objId
    | Id objId   -> objId 
  in 

  let decl = Statement.VarDecl.build loc kind id in 
  let assign = Option.map (Statement.AssignSimple.build loc id) obj in 
  
  (id, [decl] @ Option.to_list assign)

and is_special_assignment ((_, expr) : ('M, 'T) Ast'.Expression.t) : bool =
  match expr with 
    (* -- ASSIGN OP -- *)
    | Ast'.Expression.Binary _
    | Ast'.Expression.Logical _ 
    | Ast'.Expression.Update _
    (* -- ASSIGN YIELD -- *)
    | Ast'.Expression.Yield _
    (* -- ASSIGN NEW -- *)
    | Ast'.Expression.New _ 
    (* -- ASSIGN CALL -- *)
    | Ast'.Expression.Call _
    (* -- ASSING MEMBER -- *)
    | Ast'.Expression.Member _    
    (* -- ASSING OBJECT -- *)
    | Ast'.Expression.Object _
    (* -- ASSIGN FUNCTION -- *)
    | Ast'.Expression.Function _
    | Ast'.Expression.ArrowFunction _
    | Ast'.Expression.Class _
    (* -- ASSIGN ARRAY --*)
    | Ast'.Expression.Array _ -> true
    | _ -> false

and is_operation ((_, expr) : ('M, 'T) Ast'.Expression.t) : bool =
  match expr with 
    (* -- ASSIGN OP -- *)
    | Ast'.Expression.Binary _
    | Ast'.Expression.Logical _ 
    | Ast'.Expression.Update _ 
    | Ast'.Expression.Unary _ -> true
    | _ -> false


and block_to_statement (loc, block) : (Loc.t, Loc.t) Ast'.Statement.t =
  (loc, Ast'.Statement.Block block)

and change_kind (kind' : Statement.VarDecl.kind) ((loc, stmt) : m Statement.t) : m Statement.t =
  match stmt with
    | VarDecl decl -> let decl' = Statement.VarDecl {decl with kind = kind'} in 
                      (loc, decl')
    | _ -> failwith "[ERROR] Tried to change the kind of non-declaration statement"

and translate_kind (kind : Ast'.Variable.kind): Statement.VarDecl.kind = 
  match kind with 
    | Var -> _var  
    | Let -> _let  
    | Const -> _const 
  
and is_declaration ((_, stmt) : m Statement.t) : bool = 
  match stmt with 
    | Statement.VarDecl _ -> true 
    | _                   -> false
  
and build_operation (left : m Identifier.t) ((loc, _) as right : m Expression.t) (op : Operator.Assignment.t): m Statement.t = 
  let left_expr = Identifier.to_expression left in 
  match op with 
    | PlusAssign    -> Statement.AssignBinary.build loc left Operator.Binary.Plus left_expr right       
    | MinusAssign   -> Statement.AssignBinary.build loc left Operator.Binary.Minus left_expr right
    | MultAssign    -> Statement.AssignBinary.build loc left Operator.Binary.Mult left_expr right        
    | ExpAssign     -> Statement.AssignBinary.build loc left Operator.Binary.Exp left_expr right 
    | DivAssign     -> Statement.AssignBinary.build loc left Operator.Binary.Div left_expr right          
    | ModAssign     -> Statement.AssignBinary.build loc left Operator.Binary.Mod left_expr right 
    | LShiftAssign  -> Statement.AssignBinary.build loc left Operator.Binary.LShift left_expr right    
    | RShiftAssign  -> Statement.AssignBinary.build loc left Operator.Binary.RShift left_expr right 
    | RShift3Assign -> Statement.AssignBinary.build loc left Operator.Binary.RShift3 left_expr right 
    | BitOrAssign   -> Statement.AssignBinary.build loc left Operator.Binary.BitOr left_expr right 
    | BitXorAssign  -> Statement.AssignBinary.build loc left Operator.Binary.Xor left_expr right    
    | BitAndAssign  -> Statement.AssignBinary.build loc left Operator.Binary.BitAnd left_expr right 
    | NullishAssign -> Statement.AssignBinary.build loc left Operator.Binary.NullishCoalesce left_expr right  
    | AndAssign     -> Statement.AssignBinary.build loc left Operator.Binary.And left_expr right 
    | OrAssign      -> Statement.AssignBinary.build loc left Operator.Binary.Or left_expr right