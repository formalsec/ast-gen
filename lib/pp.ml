
open GraphJS 

type m = Location.t

let (<<) f g x = f(g(x));;
let flip f x y = f y x

let map_default f x value =
  match value with
    | Some value -> f value
    | None -> x

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
      let alternate' = map_default (fun alternate -> "else {\n" ^ (print_js_stmts alternate new_identation) ^ "}\n") ";\n" alternate  in

      identation_str ^ "if (" ^ test' ^ ") {\n" ^ consequent' ^ "}" ^ alternate'

    | _, Switch {discriminant; cases;} -> 
      let discriminant' = print_js_expr discriminant in
      let new_identation = identation + spaces_per_identation in 
      let cases' = List.map (flip print_js_case new_identation) cases in 
      identation_str ^ "switch (" ^ discriminant' ^ ") {\n" ^ (String.concat "" cases') ^ "}\n"
  
    | _, While {test; body} -> 
      let test' = print_js_expr test in
      let new_identation = identation + spaces_per_identation in 
      let body' = print_js_stmts body new_identation in 
      identation_str ^ "while (" ^ test' ^ ") {\n" ^ body' ^ "}\n"

    | _, Try {body; handler; finalizer} -> 
      let new_identation = identation + spaces_per_identation in
      let body' = print_js_stmts body new_identation in
      let handler' = map_default ((flip print_js_stmt identation) << catch_to_stmt) "" handler in 
      let finalizer' = map_default (fun fin -> identation_str ^ "finally {\n" ^ (print_js_stmts fin new_identation)  ^ "}\n" ) "\n" finalizer in 

      identation_str ^ "try {\n" ^ body' ^ "} " ^ handler' ^ finalizer'

    | _, Catch (_, {param; body}) -> 
      let param' = map_default (fun param -> "(" ^ print_js_expr (Identifier.to_expression param) ^ ")") "" param in 
      let new_identation = identation + spaces_per_identation in
      let body' = print_js_stmts body new_identation in 

      identation_str ^ "catch " ^ param' ^ "{\n" ^ body' ^ "}"

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

    | _, AssignObject _ -> identation_str ^ "(AssignObject)" ^ ";\n"
    | _, AssignNew _ -> identation_str ^ "(AssignNew)" ^ ";\n"
    | _, AssignFunCall _ -> identation_str ^ "(AssignFunCall)" ^ ";\n"
    | _, AssignMetCall _ -> identation_str ^ "(AssignMetCall)" ^ ";\n"
    | _, AssignMember _ -> identation_str ^ "(AssignMember)" ^ ";\n"
    | _, AssignFunction _ -> identation_str ^ "(AssignFunction)" ^ ";\n"

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
      | Minus -> "--"
      | Plus -> "++"
      | Not -> "!"
      | BitNot -> "~"
      | Typeof -> "typeof "
      | Void -> "void "
      | Delete -> "delete "
    in
    let argument' = print_js_expr argument in
    operator' ^ argument'

  | _, This _ -> "this"
  | _, TemplateLiteral _ -> "(TemplateLiteral)"

and print_js_stmts (stmts : m Statement.t list) (identation : int): string =
  String.concat "" (List.map (flip print_js_stmt identation) stmts)

and print_js_case (_, {Statement.Switch.Case.test; consequent}) (identation : int) : string =
  let identation_str = String.make identation ' ' in
  let test' = map_default (fun test -> "case " ^ print_js_expr test ^ ": \n") "default: \n" test in 
  let new_identation = identation + spaces_per_identation in 
  let consequent' = print_js_stmts consequent new_identation in 

  identation_str ^ test' ^ consequent' ^ "\n"

and catch_to_stmt (loc, {Statement.Catch.param; body}) : m Statement.t = 
  let catch_info = Statement.Catch (loc, { param = param; body = body }) in
  (loc, catch_info)