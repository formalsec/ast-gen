
open GraphJS 
open Aux

type m = Location.t
let spaces_per_identation = 3;;


let rec print_js (program : m Program.t)  : string = print_js_program program 0
and print_js_program (_, {Program.body}) (identation : int): string =
  print_js_stmts body identation

and print_js_stmt (stmt : m Statement.t) (identation : int) : string =
  let identation_str = String.make identation ' ' in
  match stmt with
    | _, If {test; consequent; alternate } -> 
      let test' = print_js_expr test in 

      let new_identation = identation + spaces_per_identation in
      let consequent' = print_js_stmts consequent new_identation in 
      let alternate' = map_default (fun alternate -> "else {\n" ^ (print_js_stmts alternate new_identation) ^ identation_str ^ "}\n") ";\n" alternate  in

      identation_str ^ "if (" ^ test' ^ ") {\n" ^ consequent' ^ identation_str ^ "}" ^ alternate'

    | _, Switch {discriminant; cases;} -> 
      let discriminant' = print_js_expr discriminant in
      let new_identation = identation + spaces_per_identation in 
      let cases' = List.map (flip print_js_case new_identation) cases in 
      identation_str ^ "switch (" ^ discriminant' ^ ") {\n" ^ (String.concat "" cases') ^ identation_str ^ "}\n"
  
    | _, While {test; body} -> 
      let test' = print_js_expr test in
      let new_identation = identation + spaces_per_identation in 
      let body' = print_js_stmts body new_identation in 
      identation_str ^ "while (" ^ test' ^ ") {\n" ^ body' ^ identation_str ^ "}\n"

    | _, Try {body; handler; finalizer} -> 
      let new_identation = identation + spaces_per_identation in
      let body' = print_js_stmts body new_identation in
      let handler' = map_default ((flip print_js_stmt identation) << catch_to_stmt) "" handler in 
      let finalizer' = map_default (fun fin -> identation_str ^ "finally {\n" ^ (print_js_stmts fin new_identation)  ^ identation_str ^ "}\n" ) "\n" finalizer in 

      identation_str ^ "try {\n" ^ body' ^ identation_str ^ "} " ^ handler' ^ finalizer'

    | _, Catch (_, {param; body}) -> 
      let param' = map_default (fun param -> "(" ^ print_js_expr (Identifier.to_expression param) ^ ")") "" param in 
      let new_identation = identation + spaces_per_identation in
      let body' = print_js_stmts body new_identation in 

      identation_str ^ "catch " ^ param' ^ "{\n" ^ body' ^ identation_str ^ "}"
    
    | _, Labeled {label; body} ->
      let label' = print_js_expr (Identifier.to_expression label) in  
      let body' = print_js_stmts body identation in 
      identation_str ^ label' ^ ":\n" ^ body' ^ "\n"

    | _, VarDecl {kind; id} -> 
      let kind' = match kind with 
        | Var -> "var "
        | Let -> "let "
        | Const -> "const "
      in
      let id' = print_js_expr (Identifier.to_expression id) in
      identation_str ^ kind' ^ id' ^ ";\n"

    | _, Return {argument} -> 
      let argument' = map_default print_js_expr "" argument in
      identation_str ^ "return " ^ argument' ^ ";\n" 

    | _, Throw {argument} -> 
      let argument' = map_default print_js_expr "" argument in
      identation_str ^ "throw " ^ argument' ^ ";\n" 

    | _, Break {label} ->
      let label' = map_default ((^) " " << print_js_expr << Identifier.to_expression) "" label in
      identation_str ^ "break" ^ label' ^ ";\n" 

    | _, Continue {label} -> 
      let label' = map_default ((^) " " << print_js_expr << Identifier.to_expression) "" label in
      identation_str ^ "continue" ^ label' ^ ";\n" 

    | _, Expression expr -> 
      identation_str ^ print_js_expr expr ^ ";\n" 

    | _, AssignSimple {operator; left; right} -> 
      let operator' = match operator with 
        | Some PlusAssign -> " += "
        | Some MinusAssign -> " -= "
        | Some MultAssign -> " *= "
        | Some ExpAssign -> " **= "
        | Some DivAssign -> " /= "
        | Some ModAssign -> " %= "
        | Some LShiftAssign -> " <<= "
        | Some RShiftAssign -> " >>= "
        | Some RShift3Assign -> " >>>= "
        | Some BitOrAssign -> " |= "
        | Some BitXorAssign -> " ^= "
        | Some BitAndAssign -> " &= "
        | Some NullishAssign -> " ??= "
        | Some AndAssign -> " &&= "
        | Some OrAssign -> " ||= "
        | None -> " = "
      in
      let left' = print_js_expr (Identifier.to_expression left) in
      let right' = print_js_expr right in
      identation_str ^ left' ^ operator' ^ right' ^ ";\n"

    | _, AssignArray {left; array} ->
      let left' = print_js_expr (Identifier.to_expression left) in
      let array' = "[" ^ String.concat (", \n      " ^ identation_str) (List.map print_js_expr array) ^ "]" in 
      identation_str ^ left' ^ " = " ^ array' ^ ";\n"

    | _, AssignObject {left; properties} -> 
      let left' = print_js_expr (Identifier.to_expression left) in
      let properties' = List.map print_js_property properties in 
      identation_str ^ left' ^ " = " ^ "{ " ^ String.concat ",\n      " properties' ^ " };\n"

    | _, AssignNew {left; callee; arguments} -> 
      let left' = print_js_expr (Identifier.to_expression left) in 
      let callee' = print_js_expr callee in 
      let arguments' = List.map print_js_expr arguments in 
      identation_str ^ left' ^ " = new " ^ callee' ^ "(" ^ (String.concat ", " arguments') ^ ");\n"

    | _, AssignFunCall {left; callee; arguments} -> 
      let left' = print_js_expr (Identifier.to_expression left) in 
      let callee' = print_js_expr callee in 
      let arguments' = List.map print_js_expr arguments in 
      identation_str ^ left' ^ " = " ^ callee' ^ "(" ^ (String.concat ", " arguments') ^ ");\n"

    | _, AssignMember {left; _object; property} ->
       let left' = print_js_expr (Identifier.to_expression left) in 
       let _object' = print_js_expr _object in 
       let property' = print_js_expr property in

       let is_literal = match property with _, Expression.Literal _ -> true | _ -> false in 

       identation_str ^ left' ^ " = " ^ _object' ^ if is_literal then "[" ^ property' ^ "];\n" else  "." ^ property' ^ ";\n"

    | _, AssignFunction {left; params; body} ->
      let left' = print_js_expr (Identifier.to_expression left) in 
      let params' = List.map print_js_param params in 
      let new_identation = identation + spaces_per_identation in
      let body' = print_js_stmts body new_identation in 

      identation_str ^ left' ^ " = function (" ^ (String.concat ", " params') ^ ") {\n" ^ body' ^ identation_str ^ "}\n"

  and print_js_expr (expr : m Expression.t): string =
  match expr with 
  | _, Literal {raw; _} -> raw
  | _, Identifier {name; _} -> name
  | _, Logical {operator; left; right} -> 
    let operator' = match operator with
      | Or -> " || "
      | And -> " && "
      | NullishCoalesce -> " ?? "
    in
    let left' = print_js_expr left in
    let right' = print_js_expr right in
    left' ^ operator' ^ right'
  
  | _, Binary {operator; left; right} -> 
    let operator' = match operator with
      | Equal -> " == "         | NotEqual -> " != "
      | StrictEqual -> " === "  | StrictNotEqual -> " !== "
      | LessThan -> " < "       | LessThanEqual -> " <= "
      | GreaterThan -> " > "    | GreaterThanEqual -> " >= "
      | LShift -> " << "        | RShift -> " >> "
      | RShift3 -> " >>> "      | Plus -> " + "
      | Minus -> " - "          | Mult -> " * "
      | Exp -> " ** "           | Div -> " / "
      | Mod -> " % "            | BitOr -> " | "
      | Xor -> " ^ "            | BitAnd -> " & "
      | In -> " in "            | Instanceof -> " instanceof "
    in
    let left' = print_js_expr left in
    let right' = print_js_expr right in
    left' ^ operator' ^ right'
  
  | _, Unary {operator; argument} ->
    let operator' = match operator with
      | Minus -> "-"
      | Plus -> "+"
      | Not -> "!"
      | BitNot -> "~"
      | Typeof -> "typeof "
      | Void -> "void "
      | Delete -> "delete "
    in
    let argument' = print_js_expr argument in
    operator' ^ argument'
  | _, Update {operator; argument; prefix} ->
    let operator' = match operator with
      | Increment -> "++"
      | Decrement -> "--"
    in
    let argument' = print_js_expr argument in 
    if prefix then operator' ^ argument' else argument' ^ operator'
  | _, This _ -> "this"
  | _, Super _ -> "super"
  | _, TemplateLiteral {quasis; expressions} -> 
    let quasis' = List.map (fun (_, {Expression.TemplateLiteral.Element.value={raw;_}; _})-> raw) quasis in 
    let expressions' = List.map print_js_expr expressions in 
    
    let quasi_expr = List.map (fun (raw, expr) -> raw ^ (if expr != "" then "${" ^ expr ^ "}" else "")) (List.combine quasis' (expressions' @ [""])) in
    "`" ^ String.concat "" quasi_expr ^ "`"

and print_js_stmts (stmts : m Statement.t list) (identation : int): string =
  String.concat "" (List.map (flip print_js_stmt identation) stmts)

and print_js_case (_, {Statement.Switch.Case.test; consequent}) (identation : int) : string =
  let identation_str = String.make identation ' ' in
  let test' = map_default (fun test -> "case " ^ print_js_expr test ^ ": \n") "default: \n" test in 
  let new_identation = identation + spaces_per_identation in 
  let consequent' = print_js_stmts consequent new_identation in 

  identation_str ^ test' ^ consequent' ^ "\n"

and print_js_param (_, {Statement.AssignFunction.Param.argument; default}) : string =
  let argument' = print_js_expr (Identifier.to_expression argument) in 
  let default' = map_default (fun def -> " = " ^ print_js_expr def) "" default in  
  argument' ^ default'

and print_js_property {key; value; _} : string = 
  let key' = print_js_expr key in 
  let value' = print_js_expr value in

  key' ^ " : " ^ value'

and catch_to_stmt (loc, {Statement.Catch.param; body}) : m Statement.t = 
  let catch_info = Statement.Catch (loc, { param = param; body = body }) in
  (loc, catch_info)
