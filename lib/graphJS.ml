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
    type t = Minus | Plus | Not | BitNot | Typeof | Void | Delete | Await

    let translate (op : Ast.Expression.Unary.operator) : t =
      match op with
        | Minus -> Minus   | Plus -> Plus
        | Not -> Not       | BitNot -> BitNot
        | Typeof -> Typeof | Void -> Void
        | Delete -> Delete
        | Await -> Await
        
  end

  module Update = struct
    type t = Increment | Decrement

    let translate (op : Ast.Expression.Update.operator) : t =
      match op with
        | Increment -> Increment
        | Decrement -> Decrement
  end
end


module rec Identifier : sig
  type t' = {
    name : string;
    is_generated : bool
  }

  type 'M t = 'M * t'

  val build : 'M -> string -> 'M t
  val build_random : 'M -> 'M t
  val to_expression: 'M t -> 'M Expression.t
  val from_expression : 'M Expression.t -> 'M t 

end = struct
  type t' = {
    name : string;
    is_generated : bool
  }

  type 'M t = 'M * t'

  let count : int ref = ref 1

  let build (metadata : 'M) (name' : string) : 'M t =
    let identifier_info = {
      name = name';
      is_generated = false
    } in
    (metadata, identifier_info)
  
  let build_random (metadata : 'M) : 'M t =
    let name' = "v" ^ string_of_int !count in
    count := !count + 1;

    let identifier_info = {
      name = name';
      is_generated = true
    } in
    (metadata, identifier_info)

  let to_expression (metadata, id : 'M t) : 'M Expression.t =
    (metadata, Expression.Identifier id)
  
  let from_expression ((loc, expr) : 'M Expression.t) : 'M t =
    match expr with
      | Expression.Identifier {name; _} -> build loc name
      | _ -> failwith "attempted to convert an expression into an identifier, but the expression provided does not correspond to a valid identifier."
  end

and Statement : sig

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

  module ForIn : sig
    type 'M t = {
      left : 'M VarDecl.t;
      right : 'M Expression.t;
      body : 'M Statement.t list;
      each : bool
    }

    val build : 'M -> 'M VarDecl.t -> 'M Expression.t -> 'M Statement.t list -> bool -> 'M Statement.t
  end

  module ForOf : sig
    type 'M t = {
      left : 'M VarDecl.t;
      right : 'M Expression.t;
      body : 'M Statement.t list;
      await : bool
    }

    val build : 'M -> 'M VarDecl.t -> 'M Expression.t -> 'M Statement.t list -> bool -> 'M Statement.t
  end


  module Catch : sig
    type 'M t' = {
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

  module With : sig 
    type 'M t = {
      _object : 'M Expression.t;
      body : 'M Statement.t list;
    }

    val build : 'M -> 'M Expression.t -> 'M Statement.t list -> 'M Statement.t
  end

  module Labeled : sig
    type 'M t = {
      label : 'M Identifier.t;
      body : 'M Statement.t list
    }

    val build : 'M -> 'M Identifier.t -> 'M Statement.t list -> 'M Statement.t
  end

  module Return : sig
    type 'M t = {
      argument : 'M Expression.t option
    }

    val build : 'M -> 'M Expression.t option -> 'M Statement.t
  end

  module Throw : sig
    type 'M t = {
      argument : 'M Expression.t option
    }

    val build : 'M -> 'M Expression.t option -> 'M Statement.t
  end

  module Break : sig
    type 'M t = {  label : 'M Identifier.t option }
    val build : 'M -> 'M Identifier.t option -> 'M Statement.t
  end

  module Continue : sig
    type 'M t = { label : 'M Identifier.t option }
    val build : 'M -> 'M Identifier.t option -> 'M Statement.t
  end

  module Debugger : sig
    type t = unit
    val build : 'M -> 'M Statement.t
  end

  (* ---------- imports // exports ----------  *)
  module ExportDefaultDecl : sig 
    type 'M t = {
      declaration : 'M Expression.t
    }

    val build : 'M -> 'M Expression.t -> 'M Statement.t
  end

  module ExportNamedDecl : sig 
    type 'M t = {
      local : 'M Identifier.t option;
      exported : 'M Identifier.t option;
      all : bool;
      source : string option
    }

    val build : 'M -> 'M Identifier.t option -> 'M Identifier.t option -> bool -> string option -> 'M Statement.t
  end

  module ImportDecl : sig
    type 'M t = 
      | Default   of { source : string;
                       identifier : 'M Identifier.t }

      | Specifier of { source : string;
                       local: 'M Identifier.t option;
                       remote: 'M Identifier.t option;
                       namespace : bool }

    val build_default : 'M -> string -> 'M Identifier.t -> 'M Statement.t
    val build_specifier : 'M -> string -> 'M Identifier.t option -> 'M Identifier.t option -> bool -> 'M Statement.t
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
    module Property : sig
      type kind = Init | Method | Get | Set

      type 'M t = {
        kind: kind;
        key : 'M Expression.t;
        value : 'M Expression.t;
        shorthand: bool option;
      }

      val build : kind -> 'M Expression.t -> 'M Expression.t -> bool option -> 'M t
    end

    type 'M t = {
      left : 'M Identifier.t;
      (* -- right -- *)
      properties : 'M Property.t list;
    }

    val build : 'M -> 'M Identifier.t -> 'M Property.t list -> 'M Statement.t
  end

  module AssignNew : sig
    type 'M t = {
      left : 'M Identifier.t;
      (* -- right -- *)
      callee : 'M Expression.t;
      arguments : 'M Expression.t list;
    }

    val build : 'M -> 'M Identifier.t -> 'M Expression.t -> 'M Expression.t list -> 'M Statement.t
  end

  module AssignFunCall : sig
    type 'M t = {
      left : 'M Identifier.t;
      (* -- right -- *)
      callee : 'M Expression.t;
      arguments : 'M Expression.t list;
    }

    val build : 'M -> 'M Identifier.t -> 'M Expression.t -> 'M Expression.t list -> 'M Statement.t
  end

  module AssignMember : sig
    type 'M t = {
      left : 'M Identifier.t;
      (* -- right -- *)
      _object : 'M Expression.t;
      property : 'M Expression.t;
    }

    val build : 'M  -> 'M Identifier.t ->'M Expression.t ->'M Expression.t ->'M Statement.t
  end

  module AssignFunction : sig
    module Param : sig 
      type 'M t' = {
        argument : 'M Identifier.t;
        default : 'M Expression.t option;
      }

      type 'M t = 'M * 'M t'

      val build : 'M -> 'M Identifier.t -> 'M Expression.t option -> 'M t
    end
    
    type 'M t = {
      left : 'M Identifier.t;
      (* -- right -- *)
      params : 'M Param.t list;
      body : 'M Statement.t list;
    } 

    val build : 'M -> 'M Identifier.t -> 'M Param.t list -> 'M Statement.t list -> 'M Statement.t
  end

  type 'M t' = 
    | If       of 'M If.t
    | Switch   of 'M Switch.t
    | While    of 'M While.t
    | ForIn    of 'M ForIn.t
    | ForOf    of 'M ForOf.t
    | Try      of 'M Try.t 
    | Catch    of 'M Catch.t 
    | With     of 'M With.t
    | Labeled  of 'M Labeled.t
    | VarDecl  of 'M VarDecl.t
    | Return   of 'M Return.t
    | Throw    of 'M Throw.t
    | Break    of 'M Break.t
    | Continue of 'M Continue.t
    | Debugger of    Debugger.t
    
    | Expression of 'M Expression.t

    (* ----- imports // exports ------ *)
    | ExportDefaultDecl of 'M ExportDefaultDecl.t
    | ExportNamedDecl   of 'M ExportNamedDecl.t
    | ImportDecl        of 'M ImportDecl.t
    
    (* ---- assignment statements ---- *)
    | AssignSimple   of 'M AssignSimple.t
    | AssignArray    of 'M AssignArray.t
    | AssignObject   of 'M AssignObject.t
    | AssignNew      of 'M AssignNew.t
    | AssignFunCall  of 'M AssignFunCall.t
    | AssignMember   of 'M AssignMember.t
    | AssignFunction of 'M AssignFunction.t
  
  type 'M t = 'M * 'M t'
  

end = struct
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

  module ForIn = struct
    type 'M t = {
      left : 'M VarDecl.t;
      right : 'M Expression.t;
      body : 'M Statement.t list;
      each : bool
    }

    let build (metadata : 'M) (left' : 'M VarDecl.t) (right' : 'M Expression.t) (body' : 'M Statement.t list) (each' : bool): 'M Statement.t =
      let for_info = Statement.ForIn {
        left = left';
        right = right';
        body = body';
        each = each'
      } in
      (metadata, for_info)
  end

  module ForOf = struct
    type 'M t = {
      left : 'M VarDecl.t;
      right : 'M Expression.t;
      body : 'M Statement.t list;
      await : bool
    }

    let build (metadata : 'M) (left' : 'M VarDecl.t) (right' : 'M Expression.t) (body' : 'M Statement.t list) (await' : bool) : 'M Statement.t =
      let for_info = Statement.ForOf {
        left = left';
        right = right';
        body = body';
        await = await'
      } in
      (metadata, for_info)
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

  module With = struct
    type 'M t = {
      _object : 'M Expression.t;
      body : 'M Statement.t list;
    }

    let build (metadata : 'M) (_object' : 'M Expression.t) (body' : 'M Statement.t list) : 'M Statement.t =
      let with_info = Statement.With {
        _object = _object';
        body = body';
      } in
      (metadata, with_info)
  end

  module Labeled = struct
    type 'M t = {
      label : 'M Identifier.t;
      body : 'M Statement.t list
    }

    let build (metadata : 'M) (label' : 'M Identifier.t) (body' : 'M Statement.t list) : 'M Statement.t =
      let labeled_info = Statement.Labeled {
        label = label';
        body = body'
      } in 
      (metadata, labeled_info)
  end

  module Return = struct
    type 'M t = {
      argument : 'M Expression.t option
    }

    let build (metadata : 'M) (argument' : 'M Expression.t option) : 'M Statement.t =
      let return_info = Statement.Return {argument = argument'} in
      (metadata, return_info)
  end

  module Throw = struct
    type 'M t = {
      argument : 'M Expression.t option
    }

    let build (metadata : 'M) (argument' : 'M Expression.t option) : 'M Statement.t =
      let return_info = Statement.Return {argument = argument'} in
      (metadata, return_info)
  end

  module Break = struct
    type 'M t = {  label : 'M Identifier.t option }

    let build (metadata: 'M) (label' : 'M Identifier.t option ): 'M Statement.t =
      let break_info = Statement.Break { label = label' } in
      (metadata, break_info)
  end

  module Continue = struct
    type 'M t = {  label : 'M Identifier.t option }

    let build (metadata: 'M) (label' : 'M Identifier.t option): 'M Statement.t =
      let continue_info = Statement.Continue { label = label' } in
      (metadata, continue_info)
  end

  module Debugger = struct
    type t = unit
    
    let build (metadata : 'M) : 'M Statement.t =
      (metadata, Statement.Debugger ())
  end

  (* ---------- imports // exports ----------  *)
  module ExportDefaultDecl = struct 
    type 'M t = {
      declaration : 'M Expression.t
    }

    let build (metadata : 'M) (declaration' : 'M Expression.t) : 'M Statement.t =
      let export_info = Statement.ExportDefaultDecl {
        declaration = declaration'; 
      } in 
      (metadata, export_info)
  end

  module ExportNamedDecl = struct
    type 'M t = {
      local : 'M Identifier.t option;
      exported : 'M Identifier.t option;
      all : bool;
      source : string option
    }

    let build (metadata : 'M) (local' : 'M Identifier.t option) (exported' : 'M Identifier.t option) (all' : bool) (source' : string option) : 'M Statement.t = 
      let export_info = Statement.ExportNamedDecl {
        local = local';
        exported = exported';
        all = all';
        source = source';
      } in 
      (metadata, export_info)

  end

  module ImportDecl = struct
    type 'M t = 
      | Default   of { source : string;
                       identifier : 'M Identifier.t }

      | Specifier of { source : string;
                       local: 'M Identifier.t option;
                       remote: 'M Identifier.t option;
                       namespace : bool }

    let build_default (metadata : 'M) (source' : string) (identifier' : 'M Identifier.t) : 'M Statement.t =
      let import_info = Statement.ImportDecl.Default {
        source = source';
        identifier = identifier'
      } in 
      (metadata, Statement.ImportDecl import_info)

    let build_specifier (metadata : 'M) (source' : string) (local' : 'M Identifier.t option) (remote' : 'M Identifier.t option) (namespace' : bool) : 'M Statement.t =
      let import_info = Statement.ImportDecl.Specifier {
        source = source';
        local = local';
        remote = remote';
        namespace = namespace'
      } in 
      (metadata, Statement.ImportDecl import_info)
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
    module Property = struct
      type kind = Init | Method | Get | Set

      type 'M t = {
        kind: kind;
        key : 'M Expression.t;
        value : 'M Expression.t;
        shorthand: bool option;
      }

      let build (kind' : kind) (key' : 'M Expression.t) (value' : 'M Expression.t) (shorthand' : bool option) : 'M t = 
        {
          kind = kind';
          key = key';
          value = value';
          shorthand = shorthand';
        }
    end

    type 'M t = {
      left : 'M Identifier.t;
      (* -- right -- *)
      properties : 'M Property.t list;
    }

    let build (metadata : 'M) (left' : 'M Identifier.t) (properties': 'M Property.t list) : 'M Statement.t = 
      let assign_info = Statement.AssignObject {
        left = left';
        properties = properties'
      } in 
      (metadata, assign_info)
  end

  module AssignNew = struct
    type 'M t = {
      left : 'M Identifier.t;
      (* -- right -- *)
      callee : 'M Expression.t;
      arguments : 'M Expression.t list;
    }

    let build (metadata : 'M) (left' : 'M Identifier.t) (callee' : 'M Expression.t) (arguments' : 'M Expression.t list) : 'M Statement.t =
      let assign_info = Statement.AssignNew {
        left = left';
        callee = callee';
        arguments = arguments';
      } in 
      (metadata, assign_info)
  end

  module AssignFunCall = struct
    type 'M t = {
      left : 'M Identifier.t;
      (* -- right -- *)
      callee : 'M Expression.t;
      arguments : 'M Expression.t list;
    }

    let build (metadata : 'M) (left' : 'M Identifier.t) (callee' : 'M Expression.t) (arguments' : 'M Expression.t list) : 'M Statement.t =
      let assign_info = Statement.AssignFunCall {
        left = left';
        callee = callee';
        arguments = arguments';
      } in 
      (metadata, assign_info)
  end

  module AssignMember = struct
    type 'M t = {
      left : 'M Identifier.t;
      (* -- right -- *)
      _object : 'M Expression.t;
      property : 'M Expression.t;
    }

    let build (metadata : 'M) (left': 'M Identifier.t) (_object' : 'M Expression.t) (property' : 'M Expression.t) : 'M Statement.t =
      let assign_info = Statement.AssignMember {
        left = left';
        _object = _object';
        property = property'
      } in
      (metadata, assign_info)

  end

  module AssignFunction = struct
    module Param = struct
      type 'M t' = {
        argument : 'M Identifier.t;
        default : 'M Expression.t option;
      }

      type 'M t = 'M * 'M t'

      let build (metadata : 'M) (argument' : 'M Identifier.t) (default' : 'M Expression.t option) : 'M t =
        let param_info = {
          argument = argument';
          default = default';
        } in
        (metadata, param_info)
    end

    type 'M t = {
      left : 'M Identifier.t;
      (* -- right -- *)
      params : 'M Param.t list;
      body : 'M Statement.t list;
    } 

    let build (metadata : 'M) (left' : 'M Identifier.t) (params' : 'M Param.t list) (body' : 'M Statement.t list) : 'M Statement.t =
      let assign_info = Statement.AssignFunction {
        left = left';
        params = params';
        body = body';
      } in 
      (metadata, assign_info)
  end

  type 'M t' = 
    | If       of 'M If.t
    | Switch   of 'M Switch.t
    | While    of 'M While.t
    | ForIn    of 'M ForIn.t
    | ForOf    of 'M ForOf.t
    | Try      of 'M Try.t 
    | Catch    of 'M Catch.t 
    | With     of 'M With.t
    | Labeled  of 'M Labeled.t
    | VarDecl  of 'M VarDecl.t
    | Return   of 'M Return.t
    | Throw    of 'M Throw.t
    | Break    of 'M Break.t
    | Continue of 'M Continue.t
    | Debugger of    Debugger.t

    
    | Expression of 'M Expression.t

    (* ----- imports // exports ------ *)
    | ExportDefaultDecl of 'M ExportDefaultDecl.t
    | ExportNamedDecl   of 'M ExportNamedDecl.t
    | ImportDecl        of 'M ImportDecl.t

    (* ---- assignment statements ---- *)
    | AssignSimple   of 'M AssignSimple.t
    | AssignArray    of 'M AssignArray.t
    | AssignObject   of 'M AssignObject.t
    | AssignNew      of 'M AssignNew.t
    | AssignFunCall  of 'M AssignFunCall.t
    | AssignMember   of 'M AssignMember.t
    | AssignFunction of 'M AssignFunction.t
  
  type 'M t = 'M * 'M t'
end

and Expression : sig

  module Literal : sig
    type value = 
      | String  of string
      | Number  of float
      | BigInt  of int64 option
      | Boolean of bool
      | Regex   of { pattern: string; flags: string; }
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

  module Update : sig
    type 'M t = {
      operator : Operator.Update.t;
      argument : 'M Expression.t;
      prefix   : bool
    }

    val build : 'M -> Operator.Update.t -> 'M Expression.t -> bool -> 'M Expression.t
  end

  module This : sig
    type t = unit
    val build : 'M -> 'M Expression.t
  end

  module Super : sig
    type t = unit
    val build : 'M -> 'M Expression.t
  end

  module TemplateLiteral : sig
    module Element : sig
      type value = {
        raw: string;
        cooked: string;
      }

      and t' = {
        value: value;
        tail: bool;
      }

      and 'M t = 'M * t'

      val build : 'M -> string -> string -> bool -> 'M t
    end

    type 'M t = {
      quasis: 'M Element.t list;
      expressions: 'M Expression.t list;
    }

    val build : 'M -> 'M Element.t list -> 'M Expression.t list -> 'M Expression.t
  end

  module TaggedTemplate : sig
    type 'M t = {
      tag : 'M Expression.t;
      quasi : 'M TemplateLiteral.t
    }

    val build : 'M -> 'M Expression.t -> 'M TemplateLiteral.t -> 'M Expression.t
  end

  module Sequence : sig
    type 'M t = { expressions : 'M Expression.t list}
    val build : 'M -> 'M Expression.t list -> 'M Expression.t
  end

  module Yield : sig
    type 'M t = {
      argument : 'M Expression.t option;
      delegate : bool
    } 

    val build : 'M -> 'M Expression.t option -> bool -> 'M Expression.t
  end

  module Conditional : sig 
    type 'M t = {
      test : 'M Expression.t;
      consequent : 'M Expression.t;
      alternate : 'M Expression.t; 
    }

    val build : 'M -> 'M Expression.t -> 'M Expression.t -> 'M Expression.t -> 'M Expression.t
  end

  module MetaProperty : sig
    type 'M t = {
      meta : 'M Identifier.t;
      property : 'M Identifier.t
    }

    val build : 'M -> 'M Identifier.t -> 'M Identifier.t -> 'M Expression.t
  end

  val to_statement : 'M Expression.t -> 'M Statement.t

  type 'M t' = 
    | Literal         of    Literal.t 
    | Identifier      of    Identifier.t' 
    | This            of    This.t
    | Super           of    Super.t
    | Logical         of 'M Logical.t
    | Binary          of 'M Binary.t
    | Unary           of 'M Unary.t
    | Update          of 'M Update.t
    
    | Yield           of 'M Yield.t
    | Sequence        of 'M Sequence.t
    | Conditional     of 'M Conditional.t

    | TemplateLiteral of 'M TemplateLiteral.t
    | TaggedTemplate  of 'M TaggedTemplate.t
    | MetaProperty    of 'M MetaProperty.t


  type 'M t = 'M * 'M t'

end = struct
  module Literal = struct
    type value = 
      | String  of string
      | Number  of float
      | BigInt  of int64 option
      | Boolean of bool
      | Regex   of { pattern: string; flags: string; }
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

  module Update = struct
    type 'M t = {
      operator : Operator.Update.t;
      argument : 'M Expression.t;
      prefix   : bool;
    }

    let build (metadata : 'M) (operator' : Operator.Update.t) (argument' : 'M Expression.t) (prefix' : bool) : 'M Expression.t = 
      let unary_info = Expression.Update {
        operator = operator';
        argument = argument';
        prefix   = prefix';
      } in
      (metadata, unary_info)
  end

  module This = struct
    type t = unit

    let build (metadata: 'M) : 'M Expression.t =
      (metadata, Expression.This ())
  end

  module Super = struct
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

      and t' = {
        value: value;
        tail: bool;
      }

      and 'M t = 'M * t'

      let build (metadata : 'M) (raw' : string) (cooked' : string) (tail' : bool) : 'M t =
        let elem_info = {
          value = {raw = raw'; cooked = cooked'};
          tail = tail';
        } in
        (metadata, elem_info)
    end

    type 'M t = {
      quasis: 'M Element.t list;
      expressions: 'M Expression.t list;
    }

    let build (metadata : 'M) (quasis' : 'M Element.t list) (expressions': 'M Expression.t list) : 'M Expression.t =
      let literal_info = Expression.TemplateLiteral {
        quasis = quasis';
        expressions = expressions';
      } in 
      (metadata, literal_info)
  end

  module TaggedTemplate = struct
    type 'M t = {
      tag : 'M Expression.t;
      quasi : 'M TemplateLiteral.t
    }

    let build (metadata : 'M) (tag' : 'M Expression.t) (quasi' : 'M TemplateLiteral.t) : 'M Expression.t =
      let tagged_info = Expression.TaggedTemplate {
        tag = tag';
        quasi = quasi'
      } in
      (metadata, tagged_info)

  end

  module Sequence = struct
    type 'M t = { expressions : 'M Expression.t list}

    let build (metadata : 'M) (expressions' : 'M Expression.t list) : 'M Expression.t =
      let sequence_info = Expression.Sequence {
        expressions = expressions'
      } in
      (metadata, sequence_info)
  end

  module Yield = struct
    type 'M t = {
      argument : 'M Expression.t option;
      delegate : bool
    } 

    let build (metadata : 'M) (argument' : 'M Expression.t option) (delegate': bool) : 'M Expression.t =
      let yield_info = Expression.Yield {
        argument = argument';
        delegate = delegate'
      } in 
      (metadata, yield_info)
  end

  module Conditional = struct 
    type 'M t = {
      test : 'M Expression.t;
      consequent : 'M Expression.t;
      alternate : 'M Expression.t; 
    }

    let build (metadata : 'M) (test' : 'M Expression.t) (consequent' : 'M Expression.t) (alternate' : 'M Expression.t) : 'M Expression.t =
      let cond_info = Expression.Conditional {
        test = test';
        consequent = consequent';
        alternate = alternate'
      } in
      (metadata, cond_info)
  end

  module MetaProperty = struct
    type 'M t = {
      meta : 'M Identifier.t;
      property : 'M Identifier.t
    }

    let build (metadata : 'M) (meta' : 'M Identifier.t) (property' : 'M Identifier.t) : 'M Expression.t =
      let metaprop_info = Expression.MetaProperty {
        meta = meta';
        property = property'
      } in 
      (metadata, metaprop_info)
  end

  let to_statement ((loc, _) as expr : 'M Expression.t) : 'M Statement.t = 
    (loc, Statement.Expression expr)

  type 'M t' = 
    | Literal         of    Literal.t 
    | Identifier      of    Identifier.t' 
    | This            of    This.t
    | Super           of    Super.t
    | Logical         of 'M Logical.t
    | Binary          of 'M Binary.t
    | Unary           of 'M Unary.t
    | Update          of 'M Update.t
    
    | Yield           of 'M Yield.t
    | Sequence        of 'M Sequence.t
    | Conditional     of 'M Conditional.t

    | TemplateLiteral of 'M TemplateLiteral.t
    | TaggedTemplate  of 'M TaggedTemplate.t
    | MetaProperty    of 'M MetaProperty.t
  


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