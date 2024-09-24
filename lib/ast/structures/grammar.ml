module Ast = Flow_ast

module Location = struct
  type pos =
    { line : int
    ; column : int
    }

  type t =
    { file : string
    ; lpos : pos
    ; rpos : pos
    }

  let empty : unit -> t =
    let pos = { line = 0; column = 0 } in
    let empty = { file = ""; lpos = pos; rpos = pos } in
    fun () -> empty

  let rec convert_flow_loc (file : string) ({ start; _end; _ } : Loc.t) : t =
    let lpos = convert_flow_pos start in
    let rpos = convert_flow_pos _end in
    { lpos; rpos; file }

  and convert_flow_pos ({ line; column } : Loc.position) : pos =
    { line; column }

  let pp_loc (ppf : Format.formatter) (pos : pos) : unit =
    Format.fprintf ppf "{ \"line\": %d, \"column\": %d }" pos.line pos.column

  let pp (ppf : Format.formatter) (loc : t) : unit =
    Format.fprintf ppf "{ \"file\": %s, \"start\": %a, \"end\": %a }" loc.file
      pp_loc loc.lpos pp_loc loc.rpos

  let str (loc : t) : string = Format.asprintf "%a" pp loc [@@inline]
end

type m = Location.t

module Operator = struct
  module Assignment = struct
    type t =
      | PlusAssign
      | MinusAssign
      | MultAssign
      | ExpAssign
      | DivAssign
      | ModAssign
      | LShiftAssign
      | RShiftAssign
      | RShift3Assign
      | BitOrAssign
      | BitXorAssign
      | BitAndAssign
      | NullishAssign
      | AndAssign
      | OrAssign

    let translate : Ast.Expression.Assignment.operator -> t = function
      | PlusAssign -> PlusAssign
      | MinusAssign -> MinusAssign
      | MultAssign -> MultAssign
      | ExpAssign -> ExpAssign
      | DivAssign -> DivAssign
      | ModAssign -> ModAssign
      | LShiftAssign -> LShiftAssign
      | RShiftAssign -> RShiftAssign
      | RShift3Assign -> RShift3Assign
      | BitOrAssign -> BitOrAssign
      | BitXorAssign -> BitXorAssign
      | BitAndAssign -> BitAndAssign
      | NullishAssign -> NullishAssign
      | AndAssign -> AndAssign
      | OrAssign -> OrAssign
  end

  module Binary = struct
    type t =
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
      | Or
      | And
      | NullishCoalesce

    let translate_binary : Ast.Expression.Binary.operator -> t = function
      | Equal -> Equal
      | NotEqual -> NotEqual
      | StrictEqual -> StrictEqual
      | StrictNotEqual -> StrictNotEqual
      | LessThan -> LessThan
      | LessThanEqual -> LessThanEqual
      | GreaterThan -> GreaterThan
      | GreaterThanEqual -> GreaterThanEqual
      | LShift -> LShift
      | RShift -> RShift
      | RShift3 -> RShift3
      | Plus -> Plus
      | Minus -> Minus
      | Mult -> Mult
      | Exp -> Exp
      | Div -> Div
      | Mod -> Mod
      | BitOr -> BitOr
      | Xor -> Xor
      | BitAnd -> BitAnd
      | In -> In
      | Instanceof -> Instanceof

    let translate_logical : Ast.Expression.Logical.operator -> t = function
      | Or -> Or
      | And -> And
      | NullishCoalesce -> NullishCoalesce

    let translate_update : Ast.Expression.Update.operator -> t = function
      | Increment -> Plus
      | Decrement -> Minus
  end

  module Unary = struct
    type t =
      | Minus
      | Plus
      | Not
      | BitNot
      | Typeof
      | Void
      | Delete
      | Await

    let translate : Ast.Expression.Unary.operator -> t = function
      | Minus -> Minus
      | Plus -> Plus
      | Not -> Not
      | BitNot -> BitNot
      | Typeof -> Typeof
      | Void -> Void
      | Delete -> Delete
      | Await -> Await
  end
end

module rec Identifier : sig
  type t' =
    { name : string
    ; is_generated : bool
    }

  type 'M t = 'M * t'

  val name : 'M t -> string
  val is_generated : 'M t -> bool
  val build : 'M -> string -> 'M t
  val build_random : 'M -> 'M t
  val to_expr : 'M t -> 'M Expression.t
  val from_expr : 'M Expression.t -> 'M t
end = struct
  type t' =
    { name : string
    ; is_generated : bool
    }

  type 'M t = 'M * t'

  let id_counter : int ref = ref 1
  let name ((_, id) : 'M t) : string = id.name [@@inline]
  let is_generated ((_, id) : 'M t) : bool = id.is_generated [@@inline]

  let build (metadata : 'M) (name : string) : 'M t =
    let id = { name; is_generated = false } in
    (metadata, id)

  let build_random (metadata : 'M) : 'M t =
    let name = "v" ^ string_of_int !id_counter in
    let id = { name; is_generated = true } in
    id_counter := !id_counter + 1;
    (metadata, id)

  let to_expr ((metadata, id) : 'M t) : 'M Expression.t =
    (metadata, Expression.Identifier id)

  let from_expr ((metadata, expr) : 'M Expression.t) : 'M t =
    match expr with
    | Expression.Identifier { name; _ } -> build metadata name
    | _ ->
      failwith
        "[ERROR] Attempted to convert an expression into an identifier, but \
         the expression provided does not correspond to a valid identifier."
end

and Expression : sig
  module Literal : sig
    type regex =
      { pattern : string
      ; flags : string
      }

    type value =
      | String of string
      | Number of float
      | BigInt of int64 option
      | Boolean of bool
      | Regex of regex
      | Null of unit

    type t =
      { value : value
      ; raw : string
      }

    val build : 'M -> value -> string -> 'M Expression.t
  end

  module TemplateLiteral : sig
    module Element : sig
      type value =
        { raw : string
        ; cooked : string
        }

      type t' =
        { value : value
        ; tail : bool
        }

      type 'M t = 'M * t'

      val build : 'M -> string -> string -> bool -> 'M t
    end

    type 'M t =
      { quasis : 'M Element.t list
      ; exprs : 'M Expression.t list
      }

    val build :
      'M -> 'M Element.t list -> 'M Expression.t list -> 'M Expression.t
  end

  module This : sig
    type t = unit

    val build : 'M -> 'M Expression.t
  end

  val id_opt : 'M Expression.t -> string option

  type 'M t' =
    | Literal of Literal.t
    | TemplateLiteral of 'M TemplateLiteral.t
    | Identifier of Identifier.t'
    | This of This.t

  type 'M t = 'M * 'M t'
end = struct
  module Literal = struct
    type regex =
      { pattern : string
      ; flags : string
      }

    type value =
      | String of string
      | Number of float
      | BigInt of int64 option
      | Boolean of bool
      | Regex of regex
      | Null of unit

    type t =
      { value : value
      ; raw : string
      }

    let build (metadata : 'M) (value : value) (raw : string) : 'M Expression.t =
      let literal = Expression.Literal { value; raw } in
      (metadata, literal)
  end

  module TemplateLiteral = struct
    module Element = struct
      type value =
        { raw : string
        ; cooked : string
        }

      type t' =
        { value : value
        ; tail : bool
        }

      type 'M t = 'M * t'

      let build (metadata : 'M) (raw : string) (cooked : string) (tail : bool) :
          'M t =
        let value = { raw; cooked } in
        let template_element = { value; tail } in
        (metadata, template_element)
    end

    type 'M t =
      { quasis : 'M Element.t list
      ; exprs : 'M Expression.t list
      }

    let build (metadata : 'M) (quasis : 'M Element.t list)
        (exprs : 'M Expression.t list) : 'M Expression.t =
      let template = Expression.TemplateLiteral { quasis; exprs } in
      (metadata, template)
  end

  module This = struct
    type t = unit

    let build (metadata : 'M) : 'M Expression.t = (metadata, Expression.This ())
  end

  let id_opt : 'M Expression.t -> string option = function
    | (_, Identifier { name; _ }) -> Some name
    | (_, This _) -> Some "this"
    | _ -> None

  type 'M t' =
    | Literal of Literal.t
    | TemplateLiteral of 'M TemplateLiteral.t
    | Identifier of Identifier.t'
    | This of This.t

  type 'M t = 'M * 'M t'
end

and Statement : sig
  module VarDecl : sig
    type kind =
      | Var
      | Let
      | Const

    type 'M t =
      { kind : kind
      ; id : 'M Identifier.t
      }

    val build : 'M -> kind -> 'M Identifier.t -> 'M Statement.t
  end

  module If : sig
    type 'M t =
      { test : 'M Expression.t
      ; consequent : 'M Statement.t list
      ; alternate : 'M Statement.t list option
      }

    val build :
         'M
      -> 'M Expression.t
      -> 'M Statement.t list
      -> 'M Statement.t list option
      -> 'M Statement.t
  end

  module Switch : sig
    module Case : sig
      type 'M t = 'M * 'M t'

      and 'M t' =
        { test : 'M Expression.t option
        ; consequent : 'M Statement.t list
        }

      val build :
           'M
        -> 'M Expression.t option
        -> 'M Statement.t list
        -> 'M Statement.Switch.Case.t
    end

    type 'M t =
      { discriminant : 'M Expression.t
      ; cases : 'M Case.t list
      }

    val build : 'M -> 'M Expression.t -> 'M Case.t list -> 'M Statement.t
  end

  module While : sig
    type 'M t =
      { test : 'M Expression.t
      ; body : 'M Statement.t list
      }

    val build : 'M -> 'M Expression.t -> 'M Statement.t list -> 'M Statement.t
  end

  module ForIn : sig
    type 'M t =
      { left : 'M VarDecl.t
      ; right : 'M Expression.t
      ; body : 'M Statement.t list
      ; each : bool
      }

    val build :
         'M
      -> 'M VarDecl.t
      -> 'M Expression.t
      -> 'M Statement.t list
      -> bool
      -> 'M Statement.t
  end

  module ForOf : sig
    type 'M t =
      { left : 'M VarDecl.t
      ; right : 'M Expression.t
      ; body : 'M Statement.t list
      ; await : bool
      }

    val build :
         'M
      -> 'M VarDecl.t
      -> 'M Expression.t
      -> 'M Statement.t list
      -> bool
      -> 'M Statement.t
  end

  module Try : sig
    module Catch : sig
      type 'M t' =
        { param : 'M Identifier.t option
        ; body : 'M Statement.t list
        }

      type 'M t = 'M * 'M t'

      val build : 'M -> 'M Identifier.t option -> 'M Statement.t list -> 'M t
    end

    type 'M t =
      { body : 'M Statement.t list
      ; handler : 'M Catch.t option
      ; finalizer : 'M Statement.t list option
      }

    val build :
         'M
      -> 'M Statement.t list
      -> 'M Catch.t option
      -> 'M Statement.t list option
      -> 'M Statement.t
  end

  module With : sig
    type 'M t =
      { obj : 'M Expression.t
      ; body : 'M Statement.t list
      }

    val build : 'M -> 'M Expression.t -> 'M Statement.t list -> 'M Statement.t
  end

  module Labeled : sig
    type 'M t =
      { label : 'M Identifier.t
      ; body : 'M Statement.t list
      }

    val build : 'M -> 'M Identifier.t -> 'M Statement.t list -> 'M Statement.t
  end

  module Return : sig
    type 'M t =
      { id : int
      ; argument : 'M Expression.t option
      }

    val build : 'M -> 'M Expression.t option -> 'M Statement.t
  end

  module Throw : sig
    type 'M t = { argument : 'M Expression.t option }

    val build : 'M -> 'M Expression.t option -> 'M Statement.t
  end

  module Break : sig
    type 'M t = { label : 'M Identifier.t option }

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

  module ExportDefaultDecl : sig
    type 'M t = { declaration : 'M Expression.t }

    val build : 'M -> 'M Expression.t -> 'M Statement.t
  end

  module ExportNamedDecl : sig
    type 'M t =
      { local : 'M Identifier.t option
      ; exported : 'M Identifier.t option
      ; all : bool
      ; source : string option
      }

    val build :
         'M
      -> 'M Identifier.t option
      -> 'M Identifier.t option
      -> bool
      -> string option
      -> 'M Statement.t
  end

  module ImportDecl : sig
    type 'M t =
      | Default of
          { source : string
          ; identifier : 'M Identifier.t
          }
      | Specifier of
          { source : string
          ; local : 'M Identifier.t option
          ; remote : 'M Identifier.t option
          ; namespace : bool
          }

    val build_default : 'M -> string -> 'M Identifier.t -> 'M Statement.t

    val build_specifier :
         'M
      -> string
      -> 'M Identifier.t option
      -> 'M Identifier.t option
      -> bool
      -> 'M Statement.t
  end

  module AssignSimple : sig
    type 'M t =
      { left : 'M Identifier.t
      ; right : 'M Expression.t
      }

    val build : 'M -> 'M Identifier.t -> 'M Expression.t -> 'M Statement.t
  end

  module AssignBinary : sig
    type 'M t =
      { id : int
      ; left : 'M Identifier.t
      ; operator : Operator.Binary.t
      ; opLeft : 'M Expression.t
      ; opRight : 'M Expression.t
      }

    val build :
         'M
      -> 'M Identifier.t
      -> Operator.Binary.t
      -> 'M Expression.t
      -> 'M Expression.t
      -> 'M Statement.t
  end

  module AssignUnary : sig
    type 'M t =
      { id : int
      ; left : 'M Identifier.t
      ; operator : Operator.Unary.t
      ; argument : 'M Expression.t
      }

    val build :
         'M
      -> 'M Identifier.t
      -> Operator.Unary.t
      -> 'M Expression.t
      -> 'M Statement.t
  end

  module Yield : sig
    type 'M t =
      { id : int
      ; left : 'M Identifier.t
      ; argument : 'M Expression.t option
      ; delegate : bool
      }

    val build :
      'M -> 'M Identifier.t -> 'M Expression.t option -> bool -> 'M Statement.t
  end

  module AssignArray : sig
    type 'M t =
      { id : int
      ; left : 'M Identifier.t
      }

    val build : 'M -> 'M Identifier.t -> 'M Statement.t
  end

  module AssignObject : sig
    type 'M t =
      { id : int
      ; left : 'M Identifier.t
      }

    val build : 'M -> 'M Identifier.t -> 'M Statement.t
  end

  module StaticUpdate : sig
    type 'M t =
      { id : int
      ; obj : 'M Expression.t
      ; property : string
      ; is_literal : bool
      ; right : 'M Expression.t
      }

    val build :
         'M
      -> 'M Expression.t
      -> string
      -> bool
      -> 'M Expression.t
      -> 'M Statement.t
  end

  module DynmicUpdate : sig
    type 'M t =
      { id : int
      ; obj : 'M Expression.t
      ; property : 'M Expression.t
      ; right : 'M Expression.t
      }

    val build :
         'M
      -> 'M Expression.t
      -> 'M Expression.t
      -> 'M Expression.t
      -> 'M Statement.t
  end

  module StaticLookup : sig
    type 'M t =
      { id : int
      ; left : 'M Identifier.t
      ; obj : 'M Expression.t
      ; property : string
      ; is_literal : bool
      }

    val build :
         'M
      -> 'M Identifier.t
      -> 'M Expression.t
      -> string
      -> bool
      -> 'M Statement.t
  end

  module DynmicLookup : sig
    type 'M t =
      { id : int
      ; left : 'M Identifier.t
      ; obj : 'M Expression.t
      ; property : 'M Expression.t
      }

    val build :
         'M
      -> 'M Identifier.t
      -> 'M Expression.t
      -> 'M Expression.t
      -> 'M Statement.t
  end

  module StaticDelete : sig
    type 'M t =
      { id : int
      ; left : 'M Identifier.t
      ; obj : 'M Expression.t
      ; property : string
      ; is_literal : bool
      }

    val build :
         'M
      -> 'M Identifier.t
      -> 'M Expression.t
      -> string
      -> bool
      -> 'M Statement.t
  end

  module DynamicDelete : sig
    type 'M t =
      { id : int
      ; left : 'M Identifier.t
      ; obj : 'M Expression.t
      ; property : 'M Expression.t
      }

    val build :
         'M
      -> 'M Identifier.t
      -> 'M Expression.t
      -> 'M Expression.t
      -> 'M Statement.t
  end

  module AssignNewCall : sig
    type 'M t =
      { id_call : int
      ; id_retn : int
      ; left : 'M Identifier.t
      ; callee : 'M Identifier.t
      ; arguments : 'M Expression.t list
      }

    val build :
         'M
      -> 'M Identifier.t
      -> 'M Identifier.t
      -> 'M Expression.t list
      -> 'M Statement.t
  end

  module AssignFunCall : sig
    type 'M t =
      { id_call : int
      ; id_retn : int
      ; left : 'M Identifier.t
      ; callee : 'M Identifier.t
      ; arguments : 'M Expression.t list
      }

    val build :
         'M
      -> 'M Identifier.t
      -> 'M Identifier.t
      -> 'M Expression.t list
      -> 'M Statement.t
  end

  module AssignMetCallStatic : sig
    type 'M t =
      { id_call : int
      ; id_retn : int
      ; left : 'M Identifier.t
      ; obj : 'M Expression.t
      ; property : string
      ; is_literal : bool
      ; arguments : 'M Expression.t list
      }

    val build :
         'M
      -> 'M Identifier.t
      -> 'M Expression.t
      -> string
      -> bool
      -> 'M Expression.t list
      -> 'M Statement.t
  end

  module AssignMetCallDynmic : sig
    type 'M t =
      { id_call : int
      ; id_retn : int
      ; left : 'M Identifier.t
      ; obj : 'M Expression.t
      ; property : 'M Expression.t
      ; arguments : 'M Expression.t list
      }

    val build :
         'M
      -> 'M Identifier.t
      -> 'M Expression.t
      -> 'M Expression.t
      -> 'M Expression.t list
      -> 'M Statement.t
  end

  module AssignFunction : sig
    module Param : sig
      type 'M t' =
        { argument : 'M Identifier.t
        ; default : 'M Expression.t option
        }

      type 'M t = 'M * 'M t'

      val build : 'M -> 'M Identifier.t -> 'M Expression.t option -> 'M t
    end

    type 'M t =
      { id : int
      ; left : 'M Identifier.t
      ; params : 'M Param.t list
      ; body : 'M Statement.t list
      }

    val build :
         'M
      -> 'M Identifier.t
      -> 'M Param.t list
      -> 'M Statement.t list
      -> 'M Statement.t
  end

  module UseStrict : sig
    type t = unit

    val build : 'M -> 'M Statement.t
  end

  type 'M t' =
    | If of 'M If.t
    | Switch of 'M Switch.t
    | While of 'M While.t
    | ForIn of 'M ForIn.t
    | ForOf of 'M ForOf.t
    | Try of 'M Try.t
    | With of 'M With.t
    | Labeled of 'M Labeled.t
    | VarDecl of 'M VarDecl.t
    | Return of 'M Return.t
    | Throw of 'M Throw.t
    | Break of 'M Break.t
    | Continue of 'M Continue.t
    | Debugger of Debugger.t
    | Yield of 'M Yield.t
    | ExportDefaultDecl of 'M ExportDefaultDecl.t
    | ExportNamedDecl of 'M ExportNamedDecl.t
    | ImportDecl of 'M ImportDecl.t
    | AssignSimple of 'M AssignSimple.t
    | AssignBinary of 'M AssignBinary.t
    | AssignUnary of 'M AssignUnary.t
    | AssignArray of 'M AssignArray.t
    | AssignObject of 'M AssignObject.t
    | StaticUpdate of 'M StaticUpdate.t
    | DynmicUpdate of 'M DynmicUpdate.t
    | StaticLookup of 'M StaticLookup.t
    | DynmicLookup of 'M DynmicLookup.t
    | StaticDelete of 'M StaticDelete.t
    | DynamicDelete of 'M DynamicDelete.t
    | AssignNewCall of 'M AssignNewCall.t
    | AssignFunCall of 'M AssignFunCall.t
    | AssignMetCallStatic of 'M AssignMetCallStatic.t
    | AssignMetCallDynmic of 'M AssignMetCallDynmic.t
    | AssignFunction of 'M AssignFunction.t
    | UseStrict of UseStrict.t

  type 'M t = 'M * 'M t'
end = struct
  let id_counter : int ref = ref (-1)

  let make_id () : int =
    id_counter := !id_counter + 1;
    !id_counter

  module VarDecl = struct
    type kind =
      | Var
      | Let
      | Const

    type 'M t =
      { kind : kind
      ; id : 'M Identifier.t
      }

    let build (metadata : 'M) (kind : kind) (id : 'M Identifier.t) :
        'M Statement.t =
      let vardecl = Statement.VarDecl { kind; id } in
      (metadata, vardecl)
  end

  module If = struct
    type 'M t =
      { test : 'M Expression.t
      ; consequent : 'M Statement.t list
      ; alternate : 'M Statement.t list option
      }

    let build (metadata : 'M) (test : 'M Expression.t)
        (consequent : 'M Statement.t list)
        (alternate : 'M Statement.t list option) : 'M Statement.t =
      let if' = Statement.If { test; consequent; alternate } in
      (metadata, if')
  end

  module Switch = struct
    module Case = struct
      type 'M t = 'M * 'M t'

      and 'M t' =
        { test : 'M Expression.t option
        ; consequent : 'M Statement.t list
        }

      let build (metadata : 'M) (test : 'M Expression.t option)
          (consequent : 'M Statement.t list) : 'M Statement.Switch.Case.t =
        let case = { test; consequent } in
        (metadata, case)
    end

    type 'M t =
      { discriminant : 'M Expression.t
      ; cases : 'M Case.t list
      }

    let build (metadata : 'M) (discriminant : 'M Expression.t)
        (cases : 'M Case.t list) : 'M Statement.t =
      let switch = Statement.Switch { discriminant; cases } in
      (metadata, switch)
  end

  module While = struct
    type 'M t =
      { test : 'M Expression.t
      ; body : 'M Statement.t list
      }

    (* val build : 'M -> 'M Expression.t -> 'M Statement.t list -> 'M Statement.t *)
    let build (metadata : 'M) (test : 'M Expression.t)
        (body : 'M Statement.t list) : 'M Statement.t =
      let while' = Statement.While { test; body } in
      (metadata, while')
  end

  module ForIn = struct
    type 'M t =
      { left : 'M VarDecl.t
      ; right : 'M Expression.t
      ; body : 'M Statement.t list
      ; each : bool
      }

    let build (metadata : 'M) (left : 'M VarDecl.t) (right : 'M Expression.t)
        (body : 'M Statement.t list) (each : bool) : 'M Statement.t =
      let for' = Statement.ForIn { left; right; body; each } in
      (metadata, for')
  end

  module ForOf = struct
    type 'M t =
      { left : 'M VarDecl.t
      ; right : 'M Expression.t
      ; body : 'M Statement.t list
      ; await : bool
      }

    let build (metadata : 'M) (left : 'M VarDecl.t) (right : 'M Expression.t)
        (body : 'M Statement.t list) (await : bool) : 'M Statement.t =
      let for' = Statement.ForOf { left; right; body; await } in
      (metadata, for')
  end

  module Try = struct
    module Catch = struct
      type 'M t' =
        { param : 'M Identifier.t option
        ; body : 'M Statement.t list
        }

      type 'M t = 'M * 'M t'

      let build (metadata : 'M) (param : 'M Identifier.t option)
          (body : 'M Statement.t list) : 'M t =
        let catch = { param; body } in
        (metadata, catch)
    end

    type 'M t =
      { body : 'M Statement.t list
      ; handler : 'M Catch.t option
      ; finalizer : 'M Statement.t list option
      }

    let build (metadata : 'M) (body : 'M Statement.t list)
        (handler : 'M Catch.t option) (finalizer : 'M Statement.t list option) :
        'M Statement.t =
      let try' = Statement.Try { body; handler; finalizer } in
      (metadata, try')
  end

  module With = struct
    type 'M t =
      { obj : 'M Expression.t
      ; body : 'M Statement.t list
      }

    let build (metadata : 'M) (obj : 'M Expression.t)
        (body : 'M Statement.t list) : 'M Statement.t =
      let with' = Statement.With { obj; body } in
      (metadata, with')
  end

  module Labeled = struct
    type 'M t =
      { label : 'M Identifier.t
      ; body : 'M Statement.t list
      }

    let build (metadata : 'M) (label : 'M Identifier.t)
        (body : 'M Statement.t list) : 'M Statement.t =
      let labeled = Statement.Labeled { label; body } in
      (metadata, labeled)
  end

  module Return = struct
    type 'M t =
      { id : int
      ; argument : 'M Expression.t option
      }

    let build (metadata : 'M) (argument : 'M Expression.t option) :
        'M Statement.t =
      let id = make_id () in
      let return = Statement.Return { id; argument } in
      (metadata, return)
  end

  module Throw = struct
    type 'M t = { argument : 'M Expression.t option }

    let build (metadata : 'M) (argument : 'M Expression.t option) :
        'M Statement.t =
      let throw = Statement.Throw { argument } in
      (metadata, throw)
  end

  module Break = struct
    type 'M t = { label : 'M Identifier.t option }

    let build (metadata : 'M) (label : 'M Identifier.t option) : 'M Statement.t
        =
      let break = Statement.Break { label } in
      (metadata, break)
  end

  module Continue = struct
    type 'M t = { label : 'M Identifier.t option }

    let build (metadata : 'M) (label : 'M Identifier.t option) : 'M Statement.t
        =
      let continue = Statement.Continue { label } in
      (metadata, continue)
  end

  module Debugger = struct
    type t = unit

    let build (metadata : 'M) : 'M Statement.t =
      (metadata, Statement.Debugger ())
  end

  module ExportDefaultDecl = struct
    type 'M t = { declaration : 'M Expression.t }

    let build (metadata : 'M) (declaration : 'M Expression.t) : 'M Statement.t =
      let export = Statement.ExportDefaultDecl { declaration } in
      (metadata, export)
  end

  module ExportNamedDecl = struct
    type 'M t =
      { local : 'M Identifier.t option
      ; exported : 'M Identifier.t option
      ; all : bool
      ; source : string option
      }

    let build (metadata : 'M) (local : 'M Identifier.t option)
        (exported : 'M Identifier.t option) (all : bool) (source : string option)
        : 'M Statement.t =
      let export = Statement.ExportNamedDecl { local; exported; all; source } in
      (metadata, export)
  end

  module ImportDecl = struct
    type 'M t =
      | Default of
          { source : string
          ; identifier : 'M Identifier.t
          }
      | Specifier of
          { source : string
          ; local : 'M Identifier.t option
          ; remote : 'M Identifier.t option
          ; namespace : bool
          }

    let build_default (metadata : 'M) (source : string)
        (identifier : 'M Identifier.t) : 'M Statement.t =
      let import = Statement.ImportDecl.Default { source; identifier } in
      (metadata, Statement.ImportDecl import)

    let build_specifier (metadata : 'M) (source : string)
        (local : 'M Identifier.t option) (remote : 'M Identifier.t option)
        (namespace : bool) : 'M Statement.t =
      let import =
        Statement.ImportDecl.Specifier { source; local; remote; namespace }
      in
      (metadata, Statement.ImportDecl import)
  end

  module AssignSimple = struct
    type 'M t =
      { left : 'M Identifier.t
      ; right : 'M Expression.t
      }

    let build (metadata : 'M) (left : 'M Identifier.t) (right : 'M Expression.t)
        : 'M Statement.t =
      let assign = Statement.AssignSimple { left; right } in
      (metadata, assign)
  end

  module AssignBinary = struct
    type 'M t =
      { id : int
      ; left : 'M Identifier.t
      ; operator : Operator.Binary.t
      ; opLeft : 'M Expression.t
      ; opRight : 'M Expression.t
      }

    let build (metadata : 'M) (left : 'M Identifier.t)
        (operator : Operator.Binary.t) (opLeft : 'M Expression.t)
        (opRight : 'M Expression.t) : 'M Statement.t =
      let id = make_id () in
      let assign =
        Statement.AssignBinary { id; left; operator; opLeft; opRight } in
      (metadata, assign)
  end

  module AssignUnary = struct
    type 'M t =
      { id : int
      ; left : 'M Identifier.t
      ; operator : Operator.Unary.t
      ; argument : 'M Expression.t
      }

    let build (metadata : 'M) (left : 'M Identifier.t)
        (operator : Operator.Unary.t) (argument : 'M Expression.t) :
        'M Statement.t =
      let id = make_id () in
      let unary = Statement.AssignUnary { id; left; operator; argument } in
      (metadata, unary)
  end

  module AssignArray = struct
    type 'M t =
      { id : int
      ; left : 'M Identifier.t
      }

    let build (metadata : 'M) (left : 'M Identifier.t) : 'M Statement.t =
      let id = make_id () in
      let assign = Statement.AssignArray { id; left } in
      (metadata, assign)
  end

  module Yield = struct
    type 'M t =
      { id : int
      ; left : 'M Identifier.t
      ; argument : 'M Expression.t option
      ; delegate : bool
      }

    let build (metadata : 'M) (left : 'M Identifier.t)
        (argument : 'M Expression.t option) (delegate : bool) : 'M Statement.t =
      let id = make_id () in
      let yield = Statement.Yield { id; left; argument; delegate } in
      (metadata, yield)
  end

  module AssignObject = struct
    type 'M t =
      { id : int
      ; left : 'M Identifier.t
      }

    let build (metadata : 'M) (left : 'M Identifier.t) : 'M Statement.t =
      let id = make_id () in
      let assign = Statement.AssignObject { id; left } in
      (metadata, assign)
  end

  module AssignNewCall = struct
    type 'M t =
      { id_call : int
      ; id_retn : int
      ; left : 'M Identifier.t
      ; callee : 'M Identifier.t
      ; arguments : 'M Expression.t list
      }

    let build (metadata : 'M) (left : 'M Identifier.t)
        (callee : 'M Identifier.t) (arguments : 'M Expression.t list) :
        'M Statement.t =
      let id_call = make_id () in
      let id_retn = make_id () in
      let assign =
        Statement.AssignNewCall { id_call; id_retn; left; callee; arguments }
      in
      (metadata, assign)
  end

  module StaticUpdate = struct
    type 'M t =
      { id : int
      ; obj : 'M Expression.t
      ; property : string
      ; is_literal : bool
      ; right : 'M Expression.t
      }

    let build (metadata : 'M) (obj : 'M Expression.t) (property : string)
        (is_literal : bool) (right : 'M Expression.t) : 'M Statement.t =
      let id = make_id () in
      let assign =
        Statement.StaticUpdate { id; obj; property; is_literal; right } in
      (metadata, assign)
  end

  module DynmicUpdate = struct
    type 'M t =
      { id : int
      ; obj : 'M Expression.t
      ; property : 'M Expression.t
      ; right : 'M Expression.t
      }

    let build (metadata : 'M) (obj : 'M Expression.t)
        (property : 'M Expression.t) (right : 'M Expression.t) : 'M Statement.t
        =
      let id = make_id () in
      let assign = Statement.DynmicUpdate { id; obj; property; right } in
      (metadata, assign)
  end

  module StaticLookup = struct
    type 'M t =
      { id : int
      ; left : 'M Identifier.t
      ; obj : 'M Expression.t
      ; property : string
      ; is_literal : bool
      }

    let build (metadata : 'M) (left : 'M Identifier.t) (obj : 'M Expression.t)
        (property : string) (is_literal : bool) : 'M Statement.t =
      let id = make_id () in
      let assign =
        Statement.StaticLookup { id; left; obj; property; is_literal } in
      (metadata, assign)
  end

  module DynmicLookup = struct
    type 'M t =
      { id : int
      ; left : 'M Identifier.t
      ; obj : 'M Expression.t
      ; property : 'M Expression.t
      }

    let build (metadata : 'M) (left : 'M Identifier.t) (obj : 'M Expression.t)
        (property : 'M Expression.t) : 'M Statement.t =
      let id = make_id () in
      let assign = Statement.DynmicLookup { id; left; obj; property } in
      (metadata, assign)
  end

  module StaticDelete = struct
    type 'M t =
      { id : int
      ; left : 'M Identifier.t
      ; (* -- right -- *)
        obj : 'M Expression.t
      ; property : string
      ; is_literal : bool
      }

    let build (metadata : 'M) (left : 'M Identifier.t) (obj : 'M Expression.t)
        (property : string) (is_literal : bool) : 'M Statement.t =
      let id = make_id () in
      let assign =
        Statement.StaticDelete { id; left; obj; property; is_literal } in
      (metadata, assign)
  end

  module DynamicDelete = struct
    type 'M t =
      { id : int
      ; left : 'M Identifier.t
      ; obj : 'M Expression.t
      ; property : 'M Expression.t
      }

    let build (metadata : 'M) (left : 'M Identifier.t) (obj : 'M Expression.t)
        (property : 'M Expression.t) : 'M Statement.t =
      let id = make_id () in
      let assign = Statement.DynamicDelete { id; left; obj; property } in
      (metadata, assign)
  end

  module AssignFunCall = struct
    type 'M t =
      { id_call : int
      ; id_retn : int
      ; left : 'M Identifier.t
      ; callee : 'M Identifier.t
      ; arguments : 'M Expression.t list
      }

    let build (metadata : 'M) (left : 'M Identifier.t)
        (callee : 'M Identifier.t) (arguments : 'M Expression.t list) :
        'M Statement.t =
      let id_call = make_id () in
      let id_retn = make_id () in
      let assign =
        Statement.AssignFunCall { id_call; id_retn; left; callee; arguments }
      in
      (metadata, assign)
  end

  module AssignMetCallStatic = struct
    type 'M t =
      { id_call : int
      ; id_retn : int
      ; left : 'M Identifier.t
      ; obj : 'M Expression.t
      ; property : string
      ; is_literal : bool
      ; arguments : 'M Expression.t list
      }

    let build (metadata : 'M) (left : 'M Identifier.t) (obj : 'M Expression.t)
        (property : string) (is_literal : bool)
        (arguments : 'M Expression.t list) : 'M Statement.t =
      let id_call = make_id () in
      let id_retn = make_id () in
      let assign =
        Statement.AssignMetCallStatic
          { id_call; id_retn; left; obj; property; is_literal; arguments } in
      (metadata, assign)
  end

  module AssignMetCallDynmic = struct
    type 'M t =
      { id_call : int
      ; id_retn : int
      ; left : 'M Identifier.t
      ; obj : 'M Expression.t
      ; property : 'M Expression.t
      ; arguments : 'M Expression.t list
      }

    let build (metadata : 'M) (left : 'M Identifier.t) (obj : 'M Expression.t)
        (property : 'M Expression.t) (arguments : 'M Expression.t list) :
        'M Statement.t =
      let id_call = make_id () in
      let id_retn = make_id () in
      let assign =
        Statement.AssignMetCallDynmic
          { id_call; id_retn; left; obj; property; arguments } in
      (metadata, assign)
  end

  module AssignFunction = struct
    module Param = struct
      type 'M t' =
        { argument : 'M Identifier.t
        ; default : 'M Expression.t option
        }

      type 'M t = 'M * 'M t'

      let build (metadata : 'M) (argument : 'M Identifier.t)
          (default : 'M Expression.t option) : 'M t =
        let param_info = { argument; default } in
        (metadata, param_info)
    end

    type 'M t =
      { id : int
      ; left : 'M Identifier.t
      ; params : 'M Param.t list
      ; body : 'M Statement.t list
      }

    let build (metadata : 'M) (left : 'M Identifier.t)
        (params : 'M Param.t list) (body : 'M Statement.t list) : 'M Statement.t
        =
      let id = make_id () in
      let assign = Statement.AssignFunction { id; left; params; body } in
      (metadata, assign)
  end

  module UseStrict = struct
    type t = unit

    let build (metadata : 'M) : 'M Statement.t =
      (metadata, Statement.UseStrict ())
  end

  type 'M t' =
    | If of 'M If.t
    | Switch of 'M Switch.t
    | While of 'M While.t
    | ForIn of 'M ForIn.t
    | ForOf of 'M ForOf.t
    | Try of 'M Try.t
    | With of 'M With.t
    | Labeled of 'M Labeled.t
    | VarDecl of 'M VarDecl.t
    | Return of 'M Return.t
    | Throw of 'M Throw.t
    | Break of 'M Break.t
    | Continue of 'M Continue.t
    | Debugger of Debugger.t
    | Yield of 'M Yield.t
    | ExportDefaultDecl of 'M ExportDefaultDecl.t
    | ExportNamedDecl of 'M ExportNamedDecl.t
    | ImportDecl of 'M ImportDecl.t
    | AssignSimple of 'M AssignSimple.t
    | AssignBinary of 'M AssignBinary.t
    | AssignUnary of 'M AssignUnary.t
    | AssignArray of 'M AssignArray.t
    | AssignObject of 'M AssignObject.t
    | StaticUpdate of 'M StaticUpdate.t
    | DynmicUpdate of 'M DynmicUpdate.t
    | StaticLookup of 'M StaticLookup.t
    | DynmicLookup of 'M DynmicLookup.t
    | StaticDelete of 'M StaticDelete.t
    | DynamicDelete of 'M DynamicDelete.t
    | AssignNewCall of 'M AssignNewCall.t
    | AssignFunCall of 'M AssignFunCall.t
    | AssignMetCallStatic of 'M AssignMetCallStatic.t
    | AssignMetCallDynmic of 'M AssignMetCallDynmic.t
    | AssignFunction of 'M AssignFunction.t
    | UseStrict of UseStrict.t

  type 'M t = 'M * 'M t'
end

and Program : sig
  type 'M t' =
    { body : 'M Statement.t list
    ; functions : Function.Info.t
    ; is_main : bool
    }

  type 'M t = 'M * 'M t'

  val body : 'M t -> 'M Statement.t list
  val functions : 'M t -> Function.Info.t
  val is_main : 'M t -> bool
  val set_main : 'M t -> 'M t
  val build : 'M -> 'M Statement.t list -> 'M t
end = struct
  type 'M t' =
    { body : 'M Statement.t list
    ; functions : Function.Info.t
    ; is_main : bool
    }

  type 'M t = 'M * 'M t'

  let body ((_, program) : 'M t) : 'M Statement.t list = program.body
  let functions ((_, program) : 'M t) : Function.Info.t = program.functions
  let is_main ((_, program) : 'M t) : bool = program.is_main

  let set_main ((loc, prog) : 'M * 'M t') : 'M t =
    (loc, { prog with is_main = true })

  let build_function_info (body : 'M Statement.t list) : Function.Info.t =
    let rec traverse_body found_funcs parent_id body =
      List.iter (search_functions found_funcs parent_id) body
    and search_functions found_funcs parent_id = function
      | (_, Statement.AssignFunction { id; left; params; body; _ }) ->
        let func_id = Function.Id.create id (Identifier.name left) in
        let params' =
          List.map
            (fun (_, { Statement.AssignFunction.Param.argument; _ }) ->
              Identifier.name argument )
            params in
        Function.Info.add found_funcs func_id parent_id params';
        traverse_body found_funcs (Some func_id) body
      | (_, Statement.If { consequent; alternate; _ }) ->
        traverse_body found_funcs parent_id consequent;
        Option.apply ~default:() (traverse_body found_funcs parent_id) alternate
      | (_, Statement.Switch { cases; _ }) ->
        List.iter
          (fun (_, { Statement.Switch.Case.consequent; _ }) ->
            traverse_body found_funcs parent_id consequent )
          cases
      | (_, Statement.While { body; _ }) ->
        traverse_body found_funcs parent_id body
      | (_, Statement.ForIn { body; _ }) ->
        traverse_body found_funcs parent_id body
      | (_, Statement.ForOf { body; _ }) ->
        traverse_body found_funcs parent_id body
      | (_, Statement.With { body; _ }) ->
        traverse_body found_funcs parent_id body
      | (_, Statement.Labeled { body; _ }) ->
        traverse_body found_funcs parent_id body
      | (_, Statement.Try { body; handler; finalizer }) ->
        traverse_body found_funcs parent_id body;
        Option.apply ~default:()
          (fun (_, { Statement.Try.Catch.body; _ }) ->
            traverse_body found_funcs parent_id body )
          handler;
        Option.apply ~default:() (traverse_body found_funcs parent_id) finalizer
      | _ -> () in
    let info = Function.Info.create 20 in
    traverse_body info None body;
    info

  let build (metadata : 'M) (body : 'M Statement.t list) : 'M t =
    (metadata, { body; functions = build_function_info body; is_main = false })
end
