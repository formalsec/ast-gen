open Grammar 
open Auxiliary.Functions


module Js = struct
  let spaces_per_identation = 3;;

  let rec print (program : m Program.t)  : string = print_program program 0
  and print_program (_, {Program.body; _}) (identation : int): string =
    print_stmts body identation

  and print_stmt (stmt : m Statement.t) (identation : int) : string =
    let identation_str = String.make identation ' ' in
    match stmt with
      | _, If {test; consequent; alternate } -> 
        let test' = print_expr test in 

        let new_identation = identation + spaces_per_identation in
        let consequent' = print_stmts consequent new_identation in 
        let alternate' = map_default (fun alternate -> " else {\n" ^ (print_stmts alternate new_identation) ^ identation_str ^ "}\n") "\n" alternate  in

        identation_str ^ "if (" ^ test' ^ ") {\n" ^ consequent' ^ identation_str ^ "}" ^ alternate'

      | _, Switch {discriminant; cases;} -> 
        let discriminant' = print_expr discriminant in
        let new_identation = identation + spaces_per_identation in 
        let cases' = List.map (flip print_case new_identation) cases in 
        identation_str ^ "switch (" ^ discriminant' ^ ") {\n" ^ (String.concat "" cases') ^ identation_str ^ "}\n"
    
      | _, While {test; body} -> 
        let test' = print_expr test in
        let new_identation = identation + spaces_per_identation in 
        let body' = print_stmts body new_identation in 
        identation_str ^ "while (" ^ test' ^ ") {\n" ^ body' ^ identation_str ^ "}\n"

      | _, ForIn {left; right; body; _} ->
        let left' = print_decl left in 
        let right' = print_expr right in 
        let new_identation = identation + spaces_per_identation in 
        let body' = print_stmts body new_identation in 
        
        identation_str ^ "for (" ^ left' ^ " in " ^ right' ^ ") {\n" ^ body' ^ identation_str ^ "}\n"

      | _, ForOf {left; right; body; await} -> 
        let left' = print_decl left in 
        let right' = print_expr right in 
        let new_identation = identation + spaces_per_identation in 
        let body' = print_stmts body new_identation in 
        
        identation_str ^ "for" ^ if (await) then " await " else " " ^ "(" ^ left' ^ " of " ^ right' ^ ") {\n" ^ body' ^ identation_str ^ "}\n"

      | _, Try {body; finalizer; handler} -> 
        let new_identation = identation + spaces_per_identation in
        let body' = print_stmts body new_identation in
        let handler' = map_default (print_handler identation identation_str) ("") handler  in 
        let finalizer' = map_default (fun fin -> identation_str ^ "finally {\n" ^ (print_stmts fin new_identation)  ^ identation_str ^ "}\n" ) "\n" finalizer in 

        identation_str ^ "try {\n" ^ body' ^ identation_str ^ "} " ^ handler' ^ finalizer'
      
      | _, With {_object; body} -> 
        let _object' = print_expr _object in 
        let new_identation = identation + spaces_per_identation in
        let body' = print_stmts body new_identation in 

        identation_str ^ "with (" ^ _object' ^ ") {\n" ^ body' ^ identation_str ^ "}\n"
        
      | _, Labeled {label; body} ->
        let label' = print_identifier label in
        let new_identation = identation + spaces_per_identation in
        
        let body' = print_stmts body new_identation in 
        identation_str ^ label' ^ ": {\n" ^ body' ^ identation_str ^ "}\n"

      | _, VarDecl {kind; id} -> 
        let kind' = match kind with 
          | Var -> "var "
          | Let -> "let "
          | Const -> "const "
        in
        let id' = print_identifier id in
        identation_str ^ kind' ^ id' ^ ";\n"

      | _, Return {argument; _} -> 
        let argument' = map_default print_expr "" argument in
        identation_str ^ "return " ^ argument' ^ ";\n" 

      | _, Throw {argument} -> 
        let argument' = map_default print_expr "" argument in
        identation_str ^ "throw " ^ argument' ^ ";\n" 

      | _, Break {label} ->
        let label' = map_default ((^) " " << print_identifier) "" label in
        identation_str ^ "break" ^ label' ^ ";\n" 

      | _, Continue {label} -> 
        let label' = map_default ((^) " " << print_identifier) "" label in
        identation_str ^ "continue" ^ label' ^ ";\n" 

      | _, Debugger _ -> identation_str ^ "debugger;\n"
      
      | _, ExportDefaultDecl {declaration} -> 
        let declaration' = print_expr declaration in 
        identation_str ^ "export default " ^ declaration' ^ ";\n" 
      
      | _, ExportNamedDecl {local; exported; all; source} ->
        let exported' = map_default ((^) " as " << print_identifier) "" exported in
        let source' = map_default (fun source -> " from \"" ^ source ^ "\"") "" source in 

        let local' = if all then "*" else print_identifier (Option.get local) in 
        identation_str ^ "export " ^ local' ^ exported' ^ source' ^ ";\n" 

      | _, ImportDecl (Default {source; identifier}) ->
        let identifier' = print_identifier identifier in  
        identation_str ^ "import " ^ identifier' ^ " from \"" ^ source ^ "\";\n"

      | _, ImportDecl (Specifier {source; local; remote; namespace}) -> 
        let local' = map_default ((^ ) " as " << print_identifier) "" local in
        let remote' = if namespace then "*" else print_identifier (Option.get remote) in

        let open_bracket = if namespace then "" else "{ " in 
        let close_bracket = if namespace then "" else " }" in  
        identation_str ^ "import " ^ open_bracket ^ remote' ^ local' ^ close_bracket ^ " from \"" ^ source ^ "\";\n"
        
      | _, AssignSimple {left; right} -> 
        let left' = print_identifier left in
        let right' = print_expr right in
        identation_str ^ left' ^ " = " ^ right' ^ ";\n"
      
      | _, AssignBinary {left; operator; opLeft; opRght; _} -> 
        let left' = print_identifier left in 
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
          | Or -> " || "            | And -> " && "
          | NullishCoalesce -> " ?? " 
        in
        let opLeft' = print_expr opLeft in 
        let opRght' = print_expr opRght in 

        identation_str ^ left' ^ " = " ^ opLeft' ^ operator' ^ opRght' ^ ";\n"

      | _, AssignUnary {left; operator; argument; _} ->
        let left' = print_identifier left in  
        let operator' = match operator with
          | Minus -> "-"          | Plus -> "+"
          | Not -> "!"            | BitNot -> "~"
          | Typeof -> "typeof "   | Void -> "void "
          | Delete -> "delete "   | Await -> "await "
        in
        let argument' = print_expr argument in
        identation_str ^ left' ^ " = " ^ operator' ^ argument' ^ ";\n"

      | _, Yield {left; argument; _ } ->
        let left' = print_identifier left in
        let argument' = map_default ((^) " " << print_expr) "" argument in
        identation_str ^ left' ^ " = yield" ^ argument' ^ ";\n" 

      | _, AssignArray {left; size; _} ->
        let left' = print_identifier left in
        identation_str ^ left' ^ " = new Array(" ^ string_of_int size ^ ");\n"

      | _, AssignObject {left; _} -> 
        let left' = print_identifier left in
        identation_str ^ left' ^ " = " ^ "{};\n"

      | _, AssignNewCall {left; callee; arguments; _} -> 
        let left' = print_identifier left in 
        let callee' = print_identifier callee in 
        let arguments' = List.map print_expr arguments in 
        identation_str ^ left' ^ " = new " ^ callee' ^ "(" ^ (String.concat ", " arguments') ^ ");\n"

      | _, AssignFunCall {left; callee; arguments; _} -> 
        let left' = print_identifier left in 
        let callee' = print_identifier callee in 
        let arguments' = List.map print_expr arguments in 
        identation_str ^ left' ^ " = " ^ callee' ^ "(" ^ (String.concat ", " arguments') ^ ");\n"
      
      | _, AssignMetCallStatic {left; _object; property; arguments; is_literal; _} -> 
        let left' = print_identifier left in 
        let _object' = print_expr _object in
        let arguments' = List.map print_expr arguments in 
        if is_literal
          then identation_str ^ left' ^ " = " ^ _object' ^ "[\"" ^ property ^ "\"]" ^ "(" ^ (String.concat ", " arguments') ^ ");\n"
          else identation_str ^ left' ^ " = " ^ _object' ^ "." ^ property ^ "(" ^ (String.concat ", " arguments') ^ ");\n"

      | _, AssignMetCallDynmic {left; _object; property; arguments; _} -> 
          let left' = print_identifier left in 
          let _object' = print_expr _object in
          let property' = print_expr property in 
          let arguments' = List.map print_expr arguments in 
          identation_str ^ left' ^ " = " ^ _object' ^ "[" ^ property' ^ "]" ^ "(" ^ (String.concat ", " arguments') ^ ");\n"

      | _, StaticUpdate {_object; property; right; is_literal; _} ->
          let _object' = print_expr _object in
          let right' = print_expr right in  
          if is_literal 
            then identation_str ^ _object' ^ "[\"" ^ property ^ "\"]" ^ " = " ^ right' ^ ";\n"
            else identation_str ^ _object' ^ "." ^ property ^ " = " ^ right' ^ ";\n"

      | _, DynmicUpdate {_object; property; right; _} ->
          let _object' = print_expr _object in
          let property' = print_expr property in 
          let right' = print_expr right in  
          identation_str ^ _object' ^ "[" ^ property' ^ "] = " ^ right' ^ ";\n"

      | _, StaticDelete {left; _object; property; is_literal; _} -> 
          let left' = print_identifier left in 
          let _object' = print_expr _object in
          if is_literal
            then identation_str ^ left' ^ " = delete " ^ _object' ^ "[\"" ^ property ^ "\"];\n"
            else identation_str ^ left' ^ " = delete " ^ _object' ^ "." ^ property ^ ";\n"
    
      | _, DynamicDelete {left; _object; property; _} -> 
            let left' = print_identifier left in 
            let _object' = print_expr _object in
            let property' = print_expr property in 
            identation_str ^ left' ^ " = delete " ^ _object' ^ "[" ^ property' ^ "];\n"

      | _, StaticLookup {left; _object; property; is_literal; _} ->
        let left' = print_identifier left in 
        let _object' = print_expr _object in 
        if is_literal 
          then identation_str ^ left' ^ " = " ^ _object' ^ "[\"" ^ property ^ "\"]" ^ ";\n"
          else identation_str ^ left' ^ " = " ^ _object' ^  "." ^ property ^ ";\n"

      | _, DynmicLookup {left; _object; property; _} ->
        let left' = print_identifier left in 
        let _object' = print_expr _object in 
        let property' = print_expr property in
        
        identation_str ^ left' ^ " = " ^ _object' ^ "[" ^ property' ^ "];\n"
      
      | _, AssignFunction {left; params; body; _} ->
        let left' = print_identifier left in 
        let params' = List.map print_param params in 
        let new_identation = identation + spaces_per_identation in
        let body' = print_stmts body new_identation in 

        identation_str ^ left' ^ " = function (" ^ (String.concat ", " params') ^ ") {\n" ^ body' ^ identation_str ^ "}\n"
      
      | _, Expression expr -> identation_str ^ print_expr expr ^ ";\n"

    and print_expr (expr : m Expression.t): string =
    match expr with 
    | _, Literal {raw; _} -> raw
    | _, Identifier {name; _} -> name
    | _, This _ -> "this"
    | _, TemplateLiteral {quasis; expressions} -> 
      let quasis' = List.map (fun (_, {Expression.TemplateLiteral.Element.value={raw;_}; _})-> raw) quasis in 
      let expressions' = List.map print_expr expressions in 
      
      let quasi_expr = List.map (fun (raw, expr) -> raw ^ (if expr != "" then "${" ^ expr ^ "}" else "")) (List.combine quasis' (expressions' @ [""])) in
      "`" ^ String.concat "" quasi_expr ^ "`"
      

  and print_stmts (stmts : m Statement.t list) (identation : int): string =
    String.concat "" (List.map (flip print_stmt identation) stmts)

  and print_identifier (identifier : m Identifier.t) = (print_expr << Identifier.to_expression) identifier

  and print_case (_, {Statement.Switch.Case.test; consequent}) (identation : int) : string =
    let identation_str = String.make identation ' ' in
    let test' = map_default (fun test -> "case " ^ print_expr test ^ ": \n") "default: \n" test in 
    let new_identation = identation + spaces_per_identation in 
    let consequent' = print_stmts consequent new_identation in 

    identation_str ^ test' ^ consequent' ^ "\n"

  and print_param (_, {Statement.AssignFunction.Param.argument; default}) : string =
    let argument' = print_identifier argument in 
    let default' = map_default (fun def -> " = " ^ print_expr def) "" default in  
    argument' ^ default'

  and print_decl {kind; id} = 
    let kind' = match kind with 
          | Var -> "var "
          | Let -> "let "
          | Const -> "const "
        in
        let id' = print_identifier id in
        kind' ^ id'

  and print_handler (identation : int) (identation_str : string) ((_, {param; body}) : 'M Statement.Try.Catch.t) : string  = 
    let param' = map_default (fun param -> "(" ^ print_identifier param ^ ")") "" param in 
    let new_identation = identation + spaces_per_identation in
    let body' = print_stmts body new_identation in 

    "catch " ^ param' ^ "{\n" ^ body' ^ identation_str ^ "}"

end
