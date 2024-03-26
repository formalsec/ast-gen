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



module rec Statement : sig
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
      param : string;
      body : 'M Statement.t list;
    }

    type 'M t = 'M * 'M t'

    val build : 'M -> string -> 'M Statement.t list -> 'M t
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
      id : string;
    }
  end

  module Return : sig
    type 'M t = unit
  end

  (* --------- assignment statements --------- *)
  module AssignExpr : sig
    type 'M t = unit
  end

  module AssignArray : sig
    type 'M t = unit
  end

  module AssignObject : sig
    type 'M t = unit
  end

  module AssignNew : sig
    type 'M t = unit
  end

  module AssignFunCall : sig
    type 'M t = unit
  end

  module AssignMetCall : sig
    type 'M t = unit
  end

  module AssignSimple : sig
    type 'M t = unit
  end

  module AssignMember : sig
    type 'M t = unit
  end

  module AssignFunction : sig
    type 'M t = unit
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
    | AssignExpr     of 'M AssignExpr.t
    | AssignArray    of 'M AssignArray.t
    | AssignObject   of 'M AssignObject.t
    | AssignNew      of 'M AssignNew.t
    | AssignFunCall  of 'M AssignFunCall.t
    | AssignMetCall  of 'M AssignMetCall.t
    | AssignSimple   of 'M AssignSimple.t
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
      param : string;
      body : 'M Statement.t list;
    }

    type 'M t = 'M * 'M t'

    let build (metadata : 'M)(param' : string) (body' : 'M Statement.t list) : 'M t =
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
      id : string;
    }
  end

  module Return = struct
    type 'M t = unit
  end

  (* --------- assignment statements --------- *)
  module AssignExpr = struct
    type 'M t = unit
  end

  module AssignArray = struct
    type 'M t = unit
  end

  module AssignObject = struct
    type 'M t = unit
  end

  module AssignNew = struct
    type 'M t = unit
  end

  module AssignFunCall = struct
    type 'M t = unit
  end

  module AssignMetCall = struct
    type 'M t = unit
  end

  module AssignSimple = struct
    type 'M t = unit
  end

  module AssignMember = struct
    type 'M t = unit
  end

  module AssignFunction = struct
    type 'M t = unit
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
    | AssignExpr     of 'M AssignExpr.t
    | AssignArray    of 'M AssignArray.t
    | AssignObject   of 'M AssignObject.t
    | AssignNew      of 'M AssignNew.t
    | AssignFunCall  of 'M AssignFunCall.t
    | AssignMetCall  of 'M AssignMetCall.t
    | AssignSimple   of 'M AssignSimple.t
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

  module Identifier : sig
    type t = {
      name : string
    }

    val build : 'M -> string -> 'M Expression.t
  end

  module Logical : sig
    type operator =
      | Or
      | And
      | NullishCoalesce
    
    type 'M t = {
      operator : operator;
      left : 'M Expression.t;
      right : 'M Expression.t
    }

    val build : 'M -> operator -> 'M Expression.t -> 'M Expression.t -> 'M Expression.t
  end

  module Binary : sig
    type operator = 
      | Equal
      | NotEqual
      | StrictEqual
      | StrictNotEqual
      | LessThan
      | LessThanEqual
      | GreaterThan
      | GreaterThanEqual
      | LShift
      | RShift
      | RShift3
      | Plus
      | Minus
      | Mult
      | Exp
      | Div
      | Mod
      | BitOr
      | Xor
      | BitAnd
      | In
      | Instanceof
    
    type 'M t = {
      operator : operator;
      left : 'M Expression.t;
      right : 'M Expression.t;
    }

    val build : 'M -> operator -> 'M Expression.t -> 'M Expression.t -> 'M Expression.t
  end

  module Unary : sig
    type operator =
      | Minus
      | Plus
      | Not
      | BitNot
      | Typeof
      | Void
      | Delete
      | Await

    type 'M t = {
      operator : operator;
      argument : 'M Expression.t;
    }

    val build : 'M -> operator -> 'M Expression.t -> 'M Expression.t
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
    | Identifier      of    Identifier.t 
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

  module Identifier = struct
    type t = {
      name : string
    }

    let build (metadata : 'M) (name' : string) : 'M Expression.t =
      let identifier_info = Expression.Identifier { name = name' } in
      (metadata, identifier_info)
  end

  module Logical = struct
    type operator =
      | Or
      | And
      | NullishCoalesce
    
    type 'M t = {
      operator : operator;
      left : 'M Expression.t;
      right : 'M Expression.t
    }

    let build (metadata : 'M) (operator' : operator) (left' : 'M Expression.t) (right' : 'M Expression.t) : 'M Expression.t = 
      let logical_info = Expression.Logical {
        operator = operator';
        left = left';
        right = right';
      } in
      (metadata, logical_info)
  end

  module Binary = struct
    type operator = 
      | Equal
      | NotEqual
      | StrictEqual
      | StrictNotEqual
      | LessThan
      | LessThanEqual
      | GreaterThan
      | GreaterThanEqual
      | LShift
      | RShift
      | RShift3
      | Plus
      | Minus
      | Mult
      | Exp
      | Div
      | Mod
      | BitOr
      | Xor
      | BitAnd
      | In
      | Instanceof
    
    type 'M t = {
      operator : operator;
      left : 'M Expression.t;
      right : 'M Expression.t
    }

    let build (metadata : 'M) (operator' : operator) (left' : 'M Expression.t) (right' : 'M Expression.t) : 'M Expression.t = 
      let binary_info = Expression.Binary {
        operator = operator';
        left = left';
        right = right';
      } in
      (metadata, binary_info)
  end

  module Unary = struct
    type operator =
      | Minus
      | Plus
      | Not
      | BitNot
      | Typeof
      | Void
      | Delete
      | Await

    type 'M t = {
      operator : operator;
      argument : 'M Expression.t;
    }

    let build (metadata : 'M) (operator' : operator) (argument' : 'M Expression.t) : 'M Expression.t = 
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
    | Identifier      of    Identifier.t 
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