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

  module Try : sig
    type 'M t = unit
  end

  module Catch : sig
    type 'M t = unit
  end

  module VarDecl : sig
    type 'M t = unit
  end

  module Return : sig
    type 'M t = unit
  end

  (* module Block : sig
    type 'M t' = {
      body : 'M Statement.t list;
    }

    type 'M t = 'M * 'M t'
    val build : 'M -> 'M Statement.t list -> 'M t
  end *)

  (* --------- assignment statements --------- *)
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
    (* | Block   of 'M Block.t *)
    
    (* ---- assignment statements ---- *)
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

  module Try = struct
    type 'M t = unit
  end

  module Catch = struct
    type 'M t = unit
  end

  module VarDecl = struct
    type 'M t = unit
  end

  module Return = struct
    type 'M t = unit
  end

  (* module Block = struct
    type 'M t' = {
      body : 'M Statement.t list;
    }

    type 'M t = 'M * 'M t'

    let build metadata statements = 
      let block_info = { body = statements } in
      (metadata, block_info)
      
  end *)

  (* --------- assignment statements --------- *)
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
    (* | Block   of 'M Block.t *)
    
    (* ---- assignment statements ---- *)
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

  Expression ::= Literal(...) | Identifier(...) | LogicalExpression(...) 
               | BinaryExpression(...) | UnaryExpression(...) | ThisExpression(...) 
               | TemplateLiteral(...)
  
  ============================================================
  **)

  module Literal : sig
    module Value : sig 
      type t =
        | String  of string
        | Number  of float
        | BigInt  of int64 option
        | Boolean of bool
        | Null    of unit
    end

    type 'M t = {
      value : Value.t; 
      raw : string
    }

    val build : 'M -> Value.t -> string -> 'M Expression.t
  end

  module Identifier : sig
    type 'M t = {
      name : string
    }

    val build : 'M -> string -> 'M Expression.t
  end

  module LogicalExpression : sig
    type 'M t = unit
  end

  module BinaryExpression : sig
    type 'M t = unit
  end

  module UnaryExpression : sig
    type 'M t = unit
  end

  module ThisExpression : sig
    type 'M t = unit
  end

  module TemplateLiteral : sig
    type 'M t = unit
  end

  type 'M t' = 
    | Literal           of 'M Literal.t 
    | Identifier        of 'M Identifier.t 
    | LogicalExpression of 'M LogicalExpression.t
    | BinaryExpression  of 'M BinaryExpression.t
    | UnaryExpression   of 'M UnaryExpression.t
    | ThisExpression    of 'M ThisExpression.t
    | TemplateLiteral   of 'M TemplateLiteral.t 

  type 'M t = 'M * 'M t'

end = struct
  module Literal = struct
    module Value = struct
      type t =
        | String  of string
        | Number  of float
        | BigInt  of int64 option
        | Boolean of bool
        | Null    of unit
    end

    type 'M t = {
      value : Value.t; 
      raw : string
    }

    let build (metadata : 'M) (value' : Value.t) (raw' : string) : 'M Expression.t =
      let literal_info = Expression.Literal { value = value'; raw = raw' } in
      (metadata, literal_info)

  end

  module Identifier = struct
    type 'M t = {
      name : string
    }

    let build (metadata : 'M) (name' : string) : 'M Expression.t =
      let identifier_info = Expression.Identifier { name = name' } in
      (metadata, identifier_info)
  end

  module LogicalExpression = struct
    type 'M t = unit
  end

  module BinaryExpression = struct
    type 'M t = unit
  end

  module UnaryExpression = struct
    type 'M t = unit
  end

  module ThisExpression = struct
    type 'M t = unit
  end

  module TemplateLiteral = struct
    type 'M t = unit
  end

  type 'M t' = 
    | Literal           of 'M Literal.t 
    | Identifier        of 'M Identifier.t 
    | LogicalExpression of 'M LogicalExpression.t
    | BinaryExpression  of 'M BinaryExpression.t
    | UnaryExpression   of 'M UnaryExpression.t
    | ThisExpression    of 'M ThisExpression.t
    | TemplateLiteral   of 'M TemplateLiteral.t 

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