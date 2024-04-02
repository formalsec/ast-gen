module Ast = Flow_ast

module Location = struct
  type position = {
    line : int;
    column : int;
  }

  type t = {
    (* maybe add file source*)
    _start : position;
    _end   : position; 
  } 

  let empty : t = 
    let empty_position = {line = 0; column = 0} in
    { _start = empty_position; _end = empty_position };; 

  let rec convert_flow_loc ({start; _end; _} : Loc.t) : t = 
    let start' = convert_flow_pos start in
    let end'   = convert_flow_pos _end  in
    { _start = start'; _end = end' }
  and convert_flow_pos ({line; column} : Loc.position) : position = 
    { line = line; column = column };;

end

module Operator = struct
  module Assignment = struct
    type t = PlusAssign | MinusAssign | MultAssign | ExpAssign | DivAssign |
             ModAssign | LShiftAssign | RShiftAssign | RShift3Assign | BitOrAssign |
             BitXorAssign | BitAndAssign | NullishAssign | AndAssign | OrAssign
    
    let translate (op : Ast.Expression.Assignment.operator) : t = 
      match op with 
        | PlusAssign -> PlusAssign       | MinusAssign -> MinusAssign
        | MultAssign -> MultAssign       | ExpAssign -> ExpAssign
        | DivAssign -> DivAssign         | ModAssign -> ModAssign
        | LShiftAssign -> LShiftAssign   | RShiftAssign -> RShiftAssign
        | RShift3Assign -> RShift3Assign | BitOrAssign -> BitOrAssign
        | BitXorAssign -> BitXorAssign   | BitAndAssign -> BitAndAssign
        | NullishAssign -> NullishAssign | AndAssign -> AndAssign
        | OrAssign -> OrAssign
  end

  module Logical = struct
    type t =  Or | And | NullishCoalesce
    
    let translate (op : Ast.Expression.Logical.operator) : t =
      match op with
        | Or -> Or | And -> And | NullishCoalesce -> NullishCoalesce
  end

  module Binary = struct
    type t = Equal | NotEqual | StrictEqual | StrictNotEqual | LessThan | LessThanEqual |
             GreaterThan | GreaterThanEqual | LShift | RShift | RShift3 | Plus |
             Minus | Mult | Exp | Div | Mod | BitOr | Xor | BitAnd | In | Instanceof

    let translate (op : Ast.Expression.Binary.operator) : t =
      match op with
        | Equal -> Equal             | NotEqual -> NotEqual
        | StrictEqual -> StrictEqual | StrictNotEqual -> StrictNotEqual
        | LessThan -> LessThan       | LessThanEqual -> LessThanEqual
        | GreaterThan -> GreaterThan | GreaterThanEqual -> GreaterThanEqual
        | LShift -> LShift           | RShift -> RShift
        | RShift3 -> RShift3         | Plus -> Plus
        | Minus -> Minus             | Mult -> Mult
        | Exp -> Exp                 | Div -> Div
        | Mod -> Mod                 | BitOr -> BitOr
        | Xor -> Xor                 | BitAnd -> BitAnd
        | In -> In                   | Instanceof -> Instanceof
  end 

  module Unary = struct
    type t = Minus | Plus | Not | BitNot | Typeof | Void | Delete

    let translate (op : Ast.Expression.Unary.operator) : t =
      match op with
        | Minus -> Minus   | Plus -> Plus
        | Not -> Not       | BitNot -> BitNot
        | Typeof -> Typeof | Void -> Void
        | Delete -> Delete
        | Await -> failwith "await operator is not an unary expression"
        
  end
end


module rec Identifier : sig
  type t' = {
    name : string
  }

  type 'M t = 'M * t'

  val build : 'M -> string -> 'M t
  val build_random : 'M -> 'M t
  val to_expression: 'M t -> 'M Expression.t

end = struct
  type t' = {
    name : string
  }

  type 'M t = 'M * t'

  let count : int ref = ref 1

  let build (metadata : 'M) (name' : string) : 'M t =
    let identifier_info = {
      name = name'
    } in
    (metadata, identifier_info)
  
  let build_random (metadata : 'M) : 'M t =
    let name' = "v" ^ string_of_int !count in
    count := !count + 1;

    let identifier_info = {
      name = name'
    } in
    (metadata, identifier_info)

  let to_expression (identifier : 'M t) : 'M Expression.t =
    match identifier with
      | metadata, {name} -> 
        let identifier_info = Expression.Identifier { name = name } in
        (metadata, identifier_info)

end

and Statement : sig
  (**  
  ==================== Statement Grammar =====================

  Statement ::= If(e, s, s) | Switch(...) | While(e, s) | Try (s, s option, s option) 
              | Catch(e, s) | VarDecl(x) | Return e  
              | AssignArray (x, ...) | AssignObject(x, ...) | AssignNew(x, ...) 
              | AssignFunCall(x, ...) | AssignMetCall(x, ...) | AssignSimple(x, ...) 
              | AssignMember(x, o1, o2) | AssignFunction(x, ...) 
  
  ============================================================
  **)


  module If : sig
    type 'M t = {
      test : 'M Expression.t;
      consequent : 'M Statement.t list;
      alternate : 'M Statement.t list option;
    }

    val build : 'M -> 'M Expression.t -> 'M Statement.t list -> 'M Statement.t list option -> 'M Statement.t
  end

  module Switch : sig
    module Case : sig
      type 'M t = 'M * 'M t'

      and 'M t' = {
        test: 'M Expression.t option;
        consequent: 'M Statement.t list;
      }

      val build : 'M -> 'M Expression.t option -> 'M Statement.t list -> 'M Statement.Switch.Case.t
    end

    type 'M t = {
      discriminant: 'M Expression.t;
      cases: 'M Case.t list;
    }
    
    val build : 'M -> 'M Expression.t -> 'M Case.t list -> 'M Statement.t 
  end
  
  module While : sig
    type 'M t = {
      test : 'M Expression.t;
      body : 'M Statement.t list;
    }

    val build : 'M -> 'M Expression.t -> 'M Statement.t list -> 'M Statement.t
  end


  module Catch : sig
    type 'M t' = {
      (* TODO : change param type ??identifier?? *)
      param : 'M Identifier.t option;
      body : 'M Statement.t list;
    }

    type 'M t = 'M * 'M t'

    val build : 'M -> 'M Identifier.t option -> 'M Statement.t list -> 'M t
  end

  module Try : sig
    type 'M t = {
      body : 'M Statement.t list;
      handler : 'M Catch.t option;
      finalizer : 'M Statement.t list option;
    }

    val build : 'M -> 'M Statement.t list -> 'M Statement.Catch.t option -> 'M Statement.t list option -> 'M Statement.t
  end

  module VarDecl : sig
    type kind =
      | Var
      | Let
      | Const

    type 'M t = {
      kind : kind;
      id : 'M Identifier.t;
    }

    val build : 'M -> kind -> 'M Identifier.t -> 'M Statement.t
  end

  module Return : sig
    type 'M t = {
      argument : 'M Expression.t option
    }

    val build : 'M -> 'M Expression.t option -> 'M Statement.t
  end

  (* --------- assignment statements --------- *)
  module AssignSimple : sig
    type 'M t = {
      operator : Operator.Assignment.t option;
      left : 'M Identifier.t;
      right : 'M Expression.t;
    }

    val build : 'M -> Operator.Assignment.t option -> 'M Identifier.t -> 'M Expression.t -> 'M Statement.t
  end

  module AssignArray : sig
    type 'M t = {
      left : 'M Identifier.t;
      (* -- right -- *)
      array : 'M Expression.t list;
    }

    val build : 'M -> 'M Identifier.t -> 'M Expression.t list -> 'M Statement.t
  end

  module AssignObject : sig
    type 'M t = {
      left : 'M Identifier.t;
      (* -- right -- *)
      properties : 'M Expression.t * 'M Expression.t list;
    }
  end

  module AssignNew : sig
    type 'M t = {
      left : 'M Identifier.t;
      (* -- right -- *)
      callee : 'M Identifier.t;
      arguments : 'M Expression.t list;
    }
  end

  module AssignFunCall : sig
    type 'M t = {
      left : 'M Identifier.t;
      (* -- right -- *)
      callee : 'M Identifier.t;
      arguments : 'M Expression.t list;
    }
  end

  module AssignMetCall : sig
    type 'M t = {
      left : 'M Identifier.t;
      (* -- right -- *)
      callee : 'M Identifier.t;
      arguments : 'M Expression.t list;
    }
  end

  module AssignMember : sig
    type 'M t = {
      left : 'M Identifier.t;
      (* -- right -- *)
      obj : 'M Expression.t;
      property : 'M Expression.t;
    }
  end

  module AssignFunction : sig
    type 'M t = {
      left : 'M Identifier.t;
      (* -- right -- *)
      body : 'M Statement.t list;
    } 
  end

  type 'M t' = 
    | If      of 'M If.t
    | Switch  of 'M Switch.t
    | While   of 'M While.t
    | Try     of 'M Try.t 
    | Catch   of 'M Catch.t 
    | VarDecl of 'M VarDecl.t
    | Return  of 'M Return.t
    
    (* ---- assignment statements ---- *)
    | AssignSimple   of 'M AssignSimple.t
    | AssignArray    of 'M AssignArray.t
    | AssignObject   of 'M AssignObject.t
    | AssignNew      of 'M AssignNew.t
    | AssignFunCall  of 'M AssignFunCall.t
    | AssignMetCall  of 'M AssignMetCall.t
    | AssignMember   of 'M AssignMember.t
    | AssignFunction of 'M AssignFunction.t
  
  type 'M t = 'M * 'M t'
  

end = struct
  module If = struct
    
    type 'M t = {
      test : 'M Expression.t;
      consequent : 'M Statement.t list;
      alternate : 'M Statement.t list option;
    }

    let build (metadata : 'M) (test' : 'M Expression.t) (consequent' : 'M Statement.t list) (alternate' : 'M Statement.t list option) : 'M Statement.t =
      let if_info = Statement.If {
        test = test';
        consequent = consequent';
        alternate = alternate'
      } in
      (metadata, if_info)

  end
  

  module Switch = struct
    module Case = struct
      type 'M t = 'M * 'M t'

      and 'M t' = {
        test: 'M Expression.t option;
        consequent: 'M Statement.t list;
      }

      let build (metadata : 'M) (test' : 'M Expression.t option) (consequent': 'M Statement.t list) : 'M Statement.Switch.Case.t = 
        let case_info = {
          test = test';
          consequent = consequent';
        } in
        (metadata, case_info)

    end

    type 'M t = {
      discriminant: 'M Expression.t;
      cases: 'M Case.t list;
    }

    let build (metadata : 'M) (discriminant' : 'M Expression.t) (cases' : 'M Case.t list) : 'M Statement.t =
      let switch_info = Statement.Switch {
        discriminant = discriminant';
        cases = cases';
      } in
      (metadata, switch_info)

  end
  
  module While = struct
    type 'M t = {
      test : 'M Expression.t;
      body : 'M Statement.t list;
    }

    (* val build : 'M -> 'M Expression.t -> 'M Statement.t list -> 'M Statement.t *)
    let build (metadata : 'M) (test' : 'M Expression.t) (body' : 'M Statement.t list) : 'M Statement.t =
      let while_info = Statement.While {
        test = test';
        body = body';
      } in 
      (metadata, while_info)
  end

  module Catch = struct
    type 'M t' = {
      param : 'M Identifier.t option;
      body : 'M Statement.t list;
    }

    type 'M t = 'M * 'M t'

    let build (metadata : 'M) (param' : 'M Identifier.t option) (body' : 'M Statement.t list) : 'M t =
      let build_info = {
        param = param';
        body = body';
      } in
      
      (metadata, build_info)
  end

  module Try = struct
    type 'M t = {
      body : 'M Statement.t list;
      handler : 'M Catch.t option;
      finalizer : 'M Statement.t list option;
    }

    let build (metadata : 'M) (body' : 'M Statement.t list) (handler' : 'M Statement.Catch.t option) (finalizer' : 'M Statement.t list option) : 'M Statement.t =
      let try_info = Statement.Try {
        body = body';
        handler = handler';
        finalizer = finalizer';
      } in
      (metadata, try_info)

  end

  module VarDecl = struct
    type kind =
      | Var
      | Let
      | Const

    type 'M t = {
      kind : kind;
      id : 'M Identifier.t;
    }

    let build (metadata : 'M) (kind' : kind) (id' : 'M Identifier.t) : 'M Statement.t =
      let variabledecl_info = Statement.VarDecl {
        kind = kind';
        id = id';
      } in
      (metadata, variabledecl_info)
    
  end

  module Return = struct
    type 'M t = {
      argument : 'M Expression.t option
    }

    let build (metadata : 'M) (argument' : 'M Expression.t option) : 'M Statement.t =
      let return_info = Statement.Return {argument = argument'} in
      (metadata, return_info)
  end

  (* --------- assignment statements --------- *)
  module AssignSimple = struct
    type 'M t = {
      operator : Operator.Assignment.t option;
      left : 'M Identifier.t;
      right : 'M Expression.t;
    }

    let build (metadata : 'M) (operator' : Operator.Assignment.t option) (left' : 'M Identifier.t) (right' : 'M Expression.t) : 'M Statement.t =
      let assign_info = Statement.AssignSimple {
        operator = operator';
        left = left';
        right = right';
      } 
      in
      (metadata, assign_info)
  end

  module AssignArray = struct
    type 'M t = {
      left : 'M Identifier.t;
      (* -- right -- *)
      array : 'M Expression.t list;
    }

    let build (metadata : 'M) (left' : 'M Identifier.t) (array' : 'M Expression.t list) : 'M Statement.t =
      let assign_info = Statement.AssignArray {
        left = left';
        array = array';
      } 
      in
      (metadata, assign_info)
  end

  module AssignObject = struct
    type 'M t = {
      left : 'M Identifier.t;
      (* -- right -- *)
      properties : 'M Expression.t * 'M Expression.t list;
    }
  end

  module AssignNew = struct
    type 'M t = {
      left : 'M Identifier.t;
      (* -- right -- *)
      callee : 'M Identifier.t;
      arguments : 'M Expression.t list;
    }
  end

  module AssignFunCall = struct
    type 'M t = {
      left : 'M Identifier.t;
      (* -- right -- *)
      callee : 'M Identifier.t;
      arguments : 'M Expression.t list;
    }
  end

  module AssignMetCall = struct
    type 'M t = {
      left : 'M Identifier.t;
      (* -- right -- *)
      callee : 'M Identifier.t;
      arguments : 'M Expression.t list;
    }
  end

  module AssignMember = struct
    type 'M t = {
      left : 'M Identifier.t;
      (* -- right -- *)
      obj : 'M Expression.t;
      property : 'M Expression.t;
    }
  end

  module AssignFunction = struct
    type 'M t = {
      left : 'M Identifier.t;
      (* -- right -- *)
      body : 'M Statement.t list;
    } 
  end

  type 'M t' = 
    | If      of 'M If.t
    | Switch  of 'M Switch.t
    | While   of 'M While.t
    | Try     of 'M Try.t 
    | Catch   of 'M Catch.t 
    | VarDecl of 'M VarDecl.t
    | Return  of 'M Return.t
    
    (* ---- assignment statements ---- *)
    | AssignSimple   of 'M AssignSimple.t
    | AssignArray    of 'M AssignArray.t
    | AssignObject   of 'M AssignObject.t
    | AssignNew      of 'M AssignNew.t
    | AssignFunCall  of 'M AssignFunCall.t
    | AssignMetCall  of 'M AssignMetCall.t
    | AssignMember   of 'M AssignMember.t
    | AssignFunction of 'M AssignFunction.t
  
  type 'M t = 'M * 'M t'
end

and Expression : sig
  (**
  ==================== Expression Grammar ====================

  Expression ::= Literal(...) | Identifier(...) | Logical(...) 
               | Binary(...) | Unary(...) | This(...) 
               | TemplateLiteral(...)
  
  ============================================================
  **)

  module Literal : sig
    type value = 
      | String  of string
      | Number  of float
      | BigInt  of int64 option
      | Boolean of bool
      | Null    of unit


    type t = {
      value : value; 
      raw : string
    }

    val build : 'M -> value -> string -> 'M Expression.t
  end

  module Logical : sig 
    type 'M t = {
      operator : Operator.Logical.t;
      left : 'M Expression.t;
      right : 'M Expression.t
    }

    val build : 'M -> Operator.Logical.t -> 'M Expression.t -> 'M Expression.t -> 'M Expression.t
  end

  module Binary : sig    
    type 'M t = {
      operator : Operator.Binary.t;
      left : 'M Expression.t;
      right : 'M Expression.t;
    }

    val build : 'M -> Operator.Binary.t -> 'M Expression.t -> 'M Expression.t -> 'M Expression.t
  end

  module Unary : sig
    type 'M t = {
      operator : Operator.Unary.t;
      argument : 'M Expression.t;
    }

    val build : 'M -> Operator.Unary.t -> 'M Expression.t -> 'M Expression.t
  end

  module This : sig
    type t = unit
    val build : 'M -> 'M Expression.t
  end

  module TemplateLiteral : sig
    module Element : sig
      type value = {
        raw: string;
        cooked: string;
      }

      and 'M t = 'M * t'

      and t' = {
        value: value;
        tail: bool;
      }
    end

    type 'M t = {
      quasis: 'M Element.t list;
      expressions: 'M Expression.t list;
    }
  end

  type 'M t' = 
    | Literal         of    Literal.t 
    | Identifier      of    Identifier.t' 
    | Logical         of 'M Logical.t
    | Binary          of 'M Binary.t
    | Unary           of 'M Unary.t
    | This            of    This.t
    | TemplateLiteral of 'M TemplateLiteral.t 

  type 'M t = 'M * 'M t'

end = struct
  module Literal = struct
    type value = 
      | String  of string
      | Number  of float
      | BigInt  of int64 option
      | Boolean of bool
      | Null    of unit

    type t = {
      value : value; 
      raw : string
    }

    let build (metadata : 'M) (value' : value) (raw' : string) : 'M Expression.t =
      let literal_info = Expression.Literal { value = value'; raw = raw' } in
      (metadata, literal_info)

  end

  module Logical = struct    
    type 'M t = {
      operator : Operator.Logical.t;
      left : 'M Expression.t;
      right : 'M Expression.t
    }

    let build (metadata : 'M) (operator' : Operator.Logical.t) (left' : 'M Expression.t) (right' : 'M Expression.t) : 'M Expression.t = 
      let logical_info = Expression.Logical {
        operator = operator';
        left = left';
        right = right';
      } in
      (metadata, logical_info)
  end

  module Binary = struct
    type 'M t = {
      operator : Operator.Binary.t;
      left : 'M Expression.t;
      right : 'M Expression.t
    }

    let build (metadata : 'M) (operator' : Operator.Binary.t) (left' : 'M Expression.t) (right' : 'M Expression.t) : 'M Expression.t = 
      let binary_info = Expression.Binary {
        operator = operator';
        left = left';
        right = right';
      } in
      (metadata, binary_info)
  end

  module Unary = struct
    type 'M t = {
      operator : Operator.Unary.t;
      argument : 'M Expression.t;
    }

    let build (metadata : 'M) (operator' : Operator.Unary.t) (argument' : 'M Expression.t) : 'M Expression.t = 
      let unary_info = Expression.Unary {
        operator = operator';
        argument = argument';
      } in
      (metadata, unary_info)
  end

  module This = struct
    type t = unit

    let build (metadata: 'M) : 'M Expression.t =
      (metadata, Expression.This ())
  end

  module TemplateLiteral = struct
    module Element = struct
      type value = {
        raw: string;
        cooked: string;
      }

      and 'M t = 'M * t'

      and t' = {
        value: value;
        tail: bool;
      }
    end

    type 'M t = {
      quasis: 'M Element.t list;
      expressions: 'M Expression.t list;
    }
  end

  type 'M t' = 
    | Literal         of    Literal.t 
    | Identifier      of    Identifier.t' 
    | Logical         of 'M Logical.t
    | Binary          of 'M Binary.t
    | Unary           of 'M Unary.t
    | This            of    This.t
    | TemplateLiteral of 'M TemplateLiteral.t 

  type 'M t = 'M * 'M t'
     
end

and Program : sig
  type 'M t' = {
    body : 'M Statement.t list;
  }

  type 'M t = 'M * 'M t'
  val build :  'M -> 'M Statement.t list -> 'M t
end = struct
  type 'M t' = {
    body : 'M Statement.t list;
  }

  type 'M t = 'M * 'M t'
  let build (metadata : 'M) (stmts : 'M Statement.t list) : 'M t = 
    (metadata, { body = stmts });; 

end