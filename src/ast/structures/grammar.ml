open Graphjs_base
module Ast' = Flow_ast

module Location = struct
  type position = {
    line : int;
    column : int;
  }

  type t = {
    (* maybe add file source*)
    _start : position;
    _end   : position;
    _file  : string; 
  } 

  let empty () : t = 
    let empty_position () : position = {line = 0; column = 0} in
    { _start = empty_position (); _end = empty_position (); _file = ""};; 

  let rec convert_flow_loc (file' : string) ({start; _end; _} : Loc.t) : t = 
    let start' = convert_flow_pos start in
    let end'   = convert_flow_pos _end  in
    { _start = start'; _end = end' ; _file = file'}
  and convert_flow_pos ({line; column} : Loc.position) : position = 
    { line = line; column = column };;

  let rec to_string (loc : t) : string =
    "{\"start\":" ^ position_to_string loc._start ^ ",\"end\":" ^ position_to_string loc._end ^ ",\"fname\":\"" ^ loc._file ^ "\"}"
  and position_to_string (position : position) : string =
    "{\"line\":" ^ string_of_int position.line ^ ",\"column\":" ^ string_of_int position.column ^ "}"

end

type m = Location.t;;


module Operator = struct
  module Assignment = struct
    type t = PlusAssign | MinusAssign | MultAssign | ExpAssign | DivAssign |
             ModAssign | LShiftAssign | RShiftAssign | RShift3Assign | BitOrAssign |
             BitXorAssign | BitAndAssign | NullishAssign | AndAssign | OrAssign
    
    let translate (op : Ast'.Expression.Assignment.operator) : t = 
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

  module Binary = struct
    type t = (* ------------------------ B I N A R Y ------------------------*)
             Equal | NotEqual | StrictEqual | StrictNotEqual | LessThan | LessThanEqual |
             GreaterThan | GreaterThanEqual | LShift | RShift | RShift3 | Plus |
             Minus | Mult | Exp | Div | Mod | BitOr | Xor | BitAnd | In | Instanceof |
             (* ------------------------ L O G I C A L -----------------------*)
             Or | And | NullishCoalesce

    let translate_binary (op : Ast'.Expression.Binary.operator) : t =
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
    
    let translate_logical (op : Ast'.Expression.Logical.operator) : t =
      match op with
        | Or -> Or | And -> And | NullishCoalesce -> NullishCoalesce

    let translate_update (op : Ast'.Expression.Update.operator) : t =
      match op with 
        | Increment -> Plus  | Decrement -> Minus 

   end 

  module Unary = struct
    type t = Minus | Plus | Not | BitNot | Typeof | Void | Delete | Await

    let translate (op : Ast'.Expression.Unary.operator) : t =
      match op with
        | Minus -> Minus   | Plus -> Plus
        | Not -> Not       | BitNot -> BitNot
        | Typeof -> Typeof | Void -> Void
        | Delete -> Delete
        | Await -> Await
        
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
  val get_name : 'M t -> string 
  val is_generated : 'M t -> bool

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
      | _ -> failwith "[ERROR] Attempted to convert an expression into an identifier, but the expression provided does not correspond to a valid identifier."

  let get_name ((_, id) : 'M t) : string = id.name
  let is_generated ((_, id) : 'M t) : bool = id.is_generated
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

  module Try : sig
    module Catch : sig
      type 'M t' = {
        param : 'M Identifier.t option;
        body : 'M Statement.t list;
      }
  
      type 'M t = 'M * 'M t'
      val build : 'M -> 'M Identifier.t option -> 'M Statement.t list -> 'M t
    end

    type 'M t = {
      body : 'M Statement.t list;
      handler : 'M Catch.t option;
      finalizer : 'M Statement.t list option;
    }

    val build : 'M -> 'M Statement.t list -> 'M Catch.t option -> 'M Statement.t list option -> 'M Statement.t
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
      id : int;
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
      left : 'M Identifier.t;
      right : 'M Expression.t;
    }

    val build : 'M -> 'M Identifier.t -> 'M Expression.t -> 'M Statement.t
  end

  module AssignBinary : sig
    type 'M t = {
      id : int;
      left : 'M Identifier.t;
      operator : Operator.Binary.t;
      (* -- right -- *)
      opLeft : 'M Expression.t;
      opRght : 'M Expression.t;
    }

    val build : 'M -> 'M Identifier.t -> Operator.Binary.t -> 'M Expression.t -> 'M Expression.t -> 'M Statement.t 
  end

  module AssignUnary : sig
    type 'M t = {
      id : int;
      left : 'M Identifier.t;
      (* -- right -- *)
      operator : Operator.Unary.t;
      argument : 'M Expression.t;
    }

    val build : 'M -> 'M Identifier.t -> Operator.Unary.t -> 'M Expression.t -> 'M Statement.t
  end

  module AssignYield : sig
    type 'M t = {
      id : int;
      left : 'M Identifier.t;
      (* -- right -- *)
      argument : 'M Expression.t option;
      delegate : bool
    } 

    val build : 'M -> 'M Identifier.t -> 'M Expression.t option -> bool -> 'M Statement.t
  end

  module AssignArray : sig
    type 'M t = {
      id : int;
      left : 'M Identifier.t;
    }

    val build : 'M -> 'M Identifier.t -> 'M Statement.t
  end

  module AssignObject : sig
    type 'M t = {
      id : int;
      left : 'M Identifier.t;
    }

    val build : 'M -> 'M Identifier.t -> 'M Statement.t
  end

  module StaticUpdate : sig
    type 'M t = {
      id : int;
      (* -- left -- *)
      _object : 'M Expression.t;
      property : string;
      is_literal : bool;

      right : 'M Expression.t;
    }

    val build : 'M -> 'M Expression.t -> string -> bool -> 'M Expression.t -> 'M Statement.t
  end

  module DynmicUpdate : sig
    type 'M t = {
      id : int;
      (* -- left -- *)
      _object : 'M Expression.t;
      property : 'M Expression.t;

      right : 'M Expression.t
    }

    val build : 'M -> 'M Expression.t -> 'M Expression.t -> 'M Expression.t -> 'M Statement.t
  end

  module StaticLookup : sig
    type 'M t = {
      id : int;
      left : 'M Identifier.t;
      (* -- right -- *)
      _object : 'M Expression.t;
      property : string;
      is_literal : bool;
    }

    val build : 'M  -> 'M Identifier.t ->'M Expression.t -> string -> bool ->'M Statement.t
  end

  module DynmicLookup : sig
    type 'M t = {
      id : int;
      left : 'M Identifier.t;
      (* -- right -- *)
      _object : 'M Expression.t;
      property : 'M Expression.t;
    }

    val build : 'M  -> 'M Identifier.t ->'M Expression.t ->'M Expression.t ->'M Statement.t
  end

  module AssignNewCall : sig
    type 'M t = {
      id_call : int;
      id_retn : int;
      left : 'M Identifier.t;
      (* -- right -- *)
      callee : 'M Identifier.t;
      arguments : 'M Expression.t list;
    }

    val build : 'M -> 'M Identifier.t -> 'M Identifier.t -> 'M Expression.t list -> 'M Statement.t
  end

  module AssignFunCall : sig
    type 'M t = {
      id_call : int;
      id_retn : int;
      left : 'M Identifier.t;
      (* -- right -- *)
      callee : 'M Identifier.t;
      arguments : 'M Expression.t list;
    }

    val build : 'M -> 'M Identifier.t -> 'M Identifier.t -> 'M Expression.t list -> 'M Statement.t
  end

  module AssignMetCallStatic : sig
    type 'M t = {
      id_call : int;
      id_retn : int;
      left : 'M Identifier.t;
      (* -- right -- *)
      _object : 'M Expression.t;
      property : string;
      is_literal : bool;

      arguments : 'M Expression.t list;
    }

    val build : 'M -> 'M Identifier.t -> 'M Expression.t -> string -> bool -> 'M Expression.t list -> 'M Statement.t
  end

  module AssignMetCallDynmic : sig
    type 'M t = {
      id_call : int;
      id_retn : int;
      left : 'M Identifier.t;
      (* -- right -- *)
      _object : 'M Expression.t;
      property : 'M Expression.t;

      arguments : 'M Expression.t list;
    }

    val build : 'M -> 'M Identifier.t -> 'M Expression.t -> 'M Expression.t -> 'M Expression.t list -> 'M Statement.t
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
      id : int;
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
    | With     of 'M With.t
    | Labeled  of 'M Labeled.t
    | VarDecl  of 'M VarDecl.t
    | Return   of 'M Return.t
    | Throw    of 'M Throw.t
    | Break    of 'M Break.t
    | Continue of 'M Continue.t
    | Debugger of    Debugger.t
    
    (* ----- imports // exports ------ *)
    | ExportDefaultDecl of 'M ExportDefaultDecl.t
    | ExportNamedDecl   of 'M ExportNamedDecl.t
    | ImportDecl        of 'M ImportDecl.t
    
    (* ---- assignment statements ---- *)
    | AssignSimple        of 'M AssignSimple.t
    | AssignBinary        of 'M AssignBinary.t
    | AssignUnary         of 'M AssignUnary.t
    | AssignYield         of 'M AssignYield.t
    | AssignArray         of 'M AssignArray.t
    | AssignObject        of 'M AssignObject.t
    | StaticUpdate        of 'M StaticUpdate.t
    | DynmicUpdate        of 'M DynmicUpdate.t
    | StaticLookup        of 'M StaticLookup.t
    | DynmicLookup        of 'M DynmicLookup.t
    | AssignNewCall       of 'M AssignNewCall.t
    | AssignFunCall       of 'M AssignFunCall.t
    | AssignMetCallStatic of 'M AssignMetCallStatic.t
    | AssignMetCallDynmic of 'M AssignMetCallDynmic.t
    | AssignFunction      of 'M AssignFunction.t
  
  type 'M t = 'M * 'M t'  

end = struct

  let id_count : int ref = ref (-1)
  let get_id () : int = 
    id_count := !id_count + 1;
    !id_count


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

  module Try = struct
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

    type 'M t = {
      body : 'M Statement.t list;
      handler : 'M Catch.t option;
      finalizer : 'M Statement.t list option;
    }

    let build (metadata : 'M) (body' : 'M Statement.t list) (handler' : 'M Catch.t option) (finalizer' : 'M Statement.t list option) : 'M Statement.t =
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
      id : int;
      argument : 'M Expression.t option
    }

    let build (metadata : 'M) (argument' : 'M Expression.t option) : 'M Statement.t =
      let return_info = Statement.Return {id = get_id (); argument = argument'} in
      (metadata, return_info)
  end

  module Throw = struct
    type 'M t = {
      argument : 'M Expression.t option
    }

    let build (metadata : 'M) (argument' : 'M Expression.t option) : 'M Statement.t =
      let return_info = Statement.Throw {argument = argument'} in
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
      left : 'M Identifier.t;
      right : 'M Expression.t;
    }

    let build (metadata : 'M) (left' : 'M Identifier.t) (right' : 'M Expression.t) : 'M Statement.t =
      let assign_info = Statement.AssignSimple {
        left = left';
        right = right';
      } 
      in
      (metadata, assign_info)
  end

  module AssignBinary = struct
    type 'M t = {
      id : int;
      left : 'M Identifier.t;
      operator : Operator.Binary.t;
      (* -- right -- *)
      opLeft : 'M Expression.t;
      opRght : 'M Expression.t;
    }

    let build (metadata : 'M) (left' : 'M Identifier.t) (operator' : Operator.Binary.t) (opLeft' : 'M Expression.t) (opRght' : 'M Expression.t) : 'M Statement.t =
      let assign_info = Statement.AssignBinary {
        id = get_id (); 
        left = left';
        operator = operator';
        opLeft = opLeft';
        opRght = opRght';
      } in 
      (metadata, assign_info)
  end

  module AssignUnary = struct
    type 'M t = {
      id : int;
      left : 'M Identifier.t;
      (* -- right -- *)
      operator : Operator.Unary.t;
      argument : 'M Expression.t;
    }

    let build (metadata : 'M) (left' : 'M Identifier.t) (operator' : Operator.Unary.t) (argument' : 'M Expression.t) : 'M Statement.t = 
      let unary_info = Statement.AssignUnary {
        id = get_id ();
        left = left';
        operator = operator';
        argument = argument';
      } in
      (metadata, unary_info)
  end

  module AssignArray = struct
    type 'M t = {
      id : int;
      left : 'M Identifier.t;
    }

    let build (metadata : 'M) (left' : 'M Identifier.t) : 'M Statement.t =
      let assign_info = Statement.AssignArray {
        id = get_id ();
        left = left';
      } 
      in
      (metadata, assign_info)
  end

  module AssignYield = struct
    type 'M t = {
      id : int;
      left : 'M Identifier.t;
      (* -- right -- *)
      argument : 'M Expression.t option;
      delegate : bool
    } 

    let build (metadata : 'M) (left' : 'M Identifier.t) (argument' : 'M Expression.t option) (delegate': bool) : 'M Statement.t =
      let yield_info = Statement.AssignYield {
        id = get_id ();
        left = left';
        argument = argument';
        delegate = delegate'
      } in 
      (metadata, yield_info)
  end

  module AssignObject = struct

    type 'M t = {
      id : int;
      left : 'M Identifier.t;
    }

    let build (metadata : 'M) (left' : 'M Identifier.t) : 'M Statement.t = 
      let assign_info = Statement.AssignObject {
        id = get_id ();
        left = left';
      } in 
      (metadata, assign_info)
  end

  module AssignNewCall = struct
    type 'M t = {
      id_call : int;
      id_retn : int;
      left : 'M Identifier.t;
      (* -- right -- *)
      callee : 'M Identifier.t;
      arguments : 'M Expression.t list;
    }

    let build (metadata : 'M) (left' : 'M Identifier.t) (callee' : 'M Identifier.t) (arguments' : 'M Expression.t list) : 'M Statement.t =
      let assign_info = Statement.AssignNewCall {
        id_call = get_id ();
        id_retn = get_id ();
        left = left';
        callee = callee';
        arguments = arguments';
      } in 
      (metadata, assign_info)
  end

  module StaticUpdate = struct
    type 'M t = {
      id : int;
      (* -- left -- *)
      _object : 'M Expression.t;
      property : string;
      is_literal : bool;


      right : 'M Expression.t
    }

    let build (metadata : 'M) (_object' : 'M Expression.t) (property' : string) (is_literal' : bool) (right' : 'M Expression.t): 'M Statement.t =
      let assign_info = Statement.StaticUpdate {
        id = get_id ();
        _object = _object';
        property = property';
        is_literal = is_literal';
        right = right';
      } in 
      (metadata, assign_info)
  end

  module DynmicUpdate = struct
    type 'M t = {
      id : int;
      (* -- left -- *)
      _object : 'M Expression.t;
      property : 'M Expression.t;

      right : 'M Expression.t
    }

    let build (metadata : 'M) (_object' : 'M Expression.t) (property' : 'M Expression.t) (right' : 'M Expression.t): 'M Statement.t =
      let assign_info = Statement.DynmicUpdate {
        id = get_id ();
        _object = _object';
        property = property';
        right = right';
      } in 
      (metadata, assign_info)
  end

  module StaticLookup = struct
    type 'M t = {
      id : int;
      left : 'M Identifier.t;
      (* -- right -- *)
      _object : 'M Expression.t;
      property : string;
      is_literal : bool;
    }

    let build (metadata : 'M) (left': 'M Identifier.t) (_object' : 'M Expression.t) (property' : string) (is_literal' : bool) : 'M Statement.t =
      let assign_info = Statement.StaticLookup {
        id = get_id ();
        left = left';
        _object = _object';
        property = property';
        is_literal = is_literal'
      } in
      (metadata, assign_info)

  end

  module DynmicLookup = struct
    type 'M t = {
      id : int;
      left : 'M Identifier.t;
      (* -- right -- *)
      _object : 'M Expression.t;
      property : 'M Expression.t;
    }

    let build (metadata : 'M) (left': 'M Identifier.t) (_object' : 'M Expression.t) (property' : 'M Expression.t) : 'M Statement.t =
      let assign_info = Statement.DynmicLookup {
        id = get_id ();
        left = left';
        _object = _object';
        property = property'
      } in
      (metadata, assign_info)
  end

  module AssignFunCall = struct
    type 'M t = {
      id_call : int;
      id_retn : int;
      left : 'M Identifier.t;
      (* -- right -- *)
      callee : 'M Identifier.t;
      arguments : 'M Expression.t list;
    }

    let build (metadata : 'M) (left' : 'M Identifier.t) (callee' : 'M Identifier.t) (arguments' : 'M Expression.t list) : 'M Statement.t =
      let assign_info = Statement.AssignFunCall {
        id_call = get_id ();
        id_retn = get_id ();
        left = left';
        callee = callee';
        arguments = arguments';
      } in 
      (metadata, assign_info)
  end

  module AssignMetCallStatic = struct
    type 'M t = {
      id_call : int;
      id_retn : int;
      left : 'M Identifier.t;
      (* -- right -- *)
      _object : 'M Expression.t;
      property : string;
      is_literal : bool;

      arguments : 'M Expression.t list;
    }

    let build (metadata : 'M) (left' : 'M Identifier.t) (_object' : 'M Expression.t) (property' : string) (is_literal' : bool) (arguments' : 'M Expression.t list) : 'M Statement.t =
      let assign_info = Statement.AssignMetCallStatic {
        id_call = get_id ();
        id_retn = get_id ();
        left = left';
        _object = _object';
        property = property';
        is_literal = is_literal';

        arguments = arguments';
      } in 
      (metadata, assign_info)
  end

  module AssignMetCallDynmic = struct
    type 'M t = {
      id_call : int;
      id_retn : int;
      left : 'M Identifier.t;
      (* -- right -- *)
      _object : 'M Expression.t;
      property : 'M Expression.t;
      arguments : 'M Expression.t list;
    }

    let build (metadata : 'M) (left' : 'M Identifier.t) (_object' : 'M Expression.t) (property' : 'M Expression.t) (arguments' : 'M Expression.t list) : 'M Statement.t =
      let assign_info = Statement.AssignMetCallDynmic {
        id_call = get_id ();
        id_retn = get_id ();
        left = left';
        _object = _object';
        property = property';
        arguments = arguments';
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
      id : int;
      left : 'M Identifier.t;
      (* -- right -- *)
      params : 'M Param.t list;
      body : 'M Statement.t list;
    } 

    let build (metadata : 'M) (left' : 'M Identifier.t) (params' : 'M Param.t list) (body' : 'M Statement.t list) : 'M Statement.t =
      let assign_info = Statement.AssignFunction {
        id = get_id ();
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
    | With     of 'M With.t
    | Labeled  of 'M Labeled.t
    | VarDecl  of 'M VarDecl.t
    | Return   of 'M Return.t
    | Throw    of 'M Throw.t
    | Break    of 'M Break.t
    | Continue of 'M Continue.t
    | Debugger of    Debugger.t

    (* ----- imports // exports ------ *)
    | ExportDefaultDecl of 'M ExportDefaultDecl.t
    | ExportNamedDecl   of 'M ExportNamedDecl.t
    | ImportDecl        of 'M ImportDecl.t

    (* ---- assignment statements ---- *)
    | AssignSimple        of 'M AssignSimple.t
    | AssignBinary        of 'M AssignBinary.t
    | AssignUnary         of 'M AssignUnary.t
    | AssignYield         of 'M AssignYield.t
    | AssignArray         of 'M AssignArray.t
    | AssignObject        of 'M AssignObject.t
    | StaticUpdate        of 'M StaticUpdate.t
    | DynmicUpdate        of 'M DynmicUpdate.t
    | StaticLookup        of 'M StaticLookup.t
    | DynmicLookup        of 'M DynmicLookup.t
    | AssignNewCall       of 'M AssignNewCall.t
    | AssignFunCall       of 'M AssignFunCall.t
    | AssignMetCallStatic of 'M AssignMetCallStatic.t
    | AssignMetCallDynmic of 'M AssignMetCallDynmic.t
    | AssignFunction      of 'M AssignFunction.t
  
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

  module This : sig
    type t = unit
    val build : 'M -> 'M Expression.t
  end

  val get_id_opt : 'M Expression.t -> string option

  type 'M t' = 
    | Literal         of    Literal.t 
    | TemplateLiteral of 'M TemplateLiteral.t
    | Identifier      of    Identifier.t' 
    | This            of    This.t


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

  module This = struct
    type t = unit

    let build (metadata: 'M) : 'M Expression.t =
      (metadata, Expression.This ())
  end
  
  let get_id_opt (expr : 'M Expression.t) : string option = 
    match expr with 
    | _, Identifier {name; _} -> Some name
    | _, This _ -> Some "this"
    | _ -> None

  type 'M t' = 
    | Literal         of    Literal.t 
    | TemplateLiteral of 'M TemplateLiteral.t
    | Identifier      of    Identifier.t' 
    | This            of    This.t

  type 'M t = 'M * 'M t'
     
end

and Program : sig
  type 'M t' = {
    body : 'M Statement.t list;
    functions : Functions.Info.t;
    is_main : bool
  }

  type 'M t = 'M * 'M t'
  val set_main : 'M t -> 'M t
  val is_main  : 'M t -> bool
  val get_functions : 'M t -> Functions.Info.t
  val get_body : 'M t -> 'M Statement.t list
  val build :  'M -> 'M Statement.t list -> 'M t

end = struct
  type 'M t' = {
    body : 'M Statement.t list;
    functions : Functions.Info.t;
    is_main : bool
  }

  type 'M t = 'M * 'M t'

  let build_function_info (body : 'M Statement.t list) : Functions.Info.t =
    let rec traverse_body found_funcs parent_id body : unit =
      List.iter (search_functions found_funcs parent_id) body
    
    and search_functions found_funcs parent_id statement : unit =
      match statement with
        | _, Statement.AssignFunction {id; left; params; body; _} -> 
          (* add function information *)
          let func_id = Functions.Id.create id (Identifier.get_name left) in
          let params' = List.map (fun (_, {Statement.AssignFunction.Param.argument; _}) -> Identifier.get_name argument) params in
          

          Functions.Info.add found_funcs func_id parent_id params'; 
          traverse_body found_funcs (Some func_id) body;         
          
        (* --------- traverse ast --------- *)
        | _, Statement.If {consequent; alternate; _} -> 
          traverse_body found_funcs parent_id consequent;
          Option.iter (traverse_body found_funcs parent_id) alternate;

        | _, Statement.Switch {cases; _} -> 
          List.iter (fun (_, {Statement.Switch.Case.consequent; _}) -> 
            traverse_body found_funcs parent_id consequent;
          ) cases

        | _, Statement.While   {body; _} -> traverse_body found_funcs parent_id body
        | _, Statement.ForIn   {body; _} -> traverse_body found_funcs parent_id body
        | _, Statement.ForOf   {body; _} -> traverse_body found_funcs parent_id body
        | _, Statement.With    {body;_ } -> traverse_body found_funcs parent_id body
        | _, Statement.Labeled {body; _} -> traverse_body found_funcs parent_id body
        
        | _, Statement.Try {body; handler; finalizer} -> 
          traverse_body found_funcs parent_id body;
          Option.iter (fun (_, {Statement.Try.Catch.body; _}) -> traverse_body found_funcs parent_id body) handler;
          Option.iter (traverse_body found_funcs parent_id) finalizer;

        (* ------- ignore all other statements ------- *)
        | _ -> ()
      
    in

    let info = Functions.Info.create 20 in 
    traverse_body info None body;
    info

    let get_functions ((_, program) : 'M t) : Functions.Info.t = program.functions
    let get_body ((_, program) : 'M t) : 'M Statement.t list = program.body

  let set_main ((loc, prog) : 'M * 'M t') : 'M t = 
    (loc, {prog with is_main = true})

  let is_main ((_, program) : 'M t) : bool = program.is_main

  let build (metadata : 'M) (stmts : 'M Statement.t list) : 'M t = 
    (metadata, { body = stmts; functions = build_function_info stmts; is_main = false});; 

end