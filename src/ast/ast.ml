module rec Identifier : sig
  type 'm t = ('m, t') Metadata.t

  and t' =
    { name : string
    ; generated : bool
    }
end =
  Identifier

and LeftValue : sig
  module Kind : sig
    type t =
      | Var
      | Let
      | Const
      | None
  end

  type 'm t = ('m, t') Metadata.t

  and t' =
    { id : Identifier.t'
    ; kind : Kind.t
    }
end =
  LeftValue

and Prop : sig
  type 'm t = ('m, t') Metadata.t

  and t' =
    | IProp of Identifier.t'
    | LProp of Expression.Literal.t
end =
  Prop

and Expression : sig
  module Literal : sig
    module Regex : sig
      type t =
        { pattern : string
        ; flags : string
        }
    end

    type t' =
      | Null
      | String of string
      | Number of float
      | Boolean of bool
      | BigInt of int64 option
      | Regex of Regex.t

    type t =
      { value : t'
      ; raw : string
      }
  end

  module TemplateLiteral : sig
    module Element : sig
      module Value : sig
        type t =
          { raw : string
          ; cooked : string
          }
      end

      type 'm t = ('m, t') Metadata.t

      and t' =
        { value : Value.t
        ; tail : bool
        }
    end

    type 'm t =
      { quasis : 'm Element.t list
      ; exprs : 'm Expression.t list
      }
  end

  module This : sig
    type t = unit
  end

  type 'm t = ('m, 'm t') Metadata.t

  and 'm t' =
    [ `Literal of Literal.t
    | `TemplateLiteral of 'm TemplateLiteral.t
    | `Identifier of Identifier.t'
    | `This of This.t
    ]
end =
  Expression

and Statement : sig
  module AssignSimple : sig
    type 'm t =
      { left : 'm LeftValue.t
      ; right : 'm Expression.t
      }
  end

  module AssignNewObject : sig
    type 'm t = { left : 'm LeftValue.t }
  end

  module AssignNewArray : sig
    type 'm t = { left : 'm LeftValue.t }
  end

  module AssignUnopt : sig
    type 'm t =
      { left : 'm LeftValue.t
      ; op : Operator.Unary.t
      ; arg : 'm Expression.t
      }
  end

  module AssignBinopt : sig
    type 'm t =
      { left : 'm LeftValue.t
      ; op : Operator.Binary.t
      ; arg1 : 'm Expression.t
      ; arg2 : 'm Expression.t
      }
  end

  module AssignYield : sig
    type 'm t =
      { left : 'm LeftValue.t
      ; arg : 'm Expression.t option
      ; delegate : bool
      }
  end

  module StaticLookup : sig
    type 'm t =
      { left : 'm LeftValue.t
      ; obj : 'm Expression.t
      ; prop : 'm Prop.t
      }
  end

  module DynamicLookup : sig
    type 'm t =
      { left : 'm LeftValue.t
      ; obj : 'm Expression.t
      ; prop : 'm Expression.t
      }
  end

  module StaticUpdate : sig
    type 'm t =
      { obj : 'm Expression.t
      ; prop : 'm Prop.t
      ; right : 'm Expression.t
      }
  end

  module DynamicUpdate : sig
    type 'm t =
      { obj : 'm Expression.t
      ; prop : 'm Expression.t
      ; right : 'm Expression.t
      }
  end

  module StaticDelete : sig
    type 'm t =
      { left : 'm LeftValue.t
      ; obj : 'm Expression.t
      ; prop : 'm Prop.t
      }
  end

  module DynamicDelete : sig
    type 'm t =
      { left : 'm LeftValue.t
      ; obj : 'm Expression.t
      ; prop : 'm Expression.t
      }
  end

  module AssignNewCall : sig
    type 'm t =
      { left : 'm LeftValue.t
      ; callee : 'm Identifier.t
      ; args : 'm Expression.t list
      }
  end

  module AssignFunctionCall : sig
    type 'm t =
      { left : 'm LeftValue.t
      ; callee : 'm Identifier.t
      ; args : 'm Expression.t list
      }
  end

  module AssignStaticMethodCall : sig
    type 'm t =
      { left : 'm LeftValue.t
      ; obj : 'm Expression.t
      ; prop : 'm Prop.t
      ; args : 'm Expression.t list
      }
  end

  module AssignDynamicMethodCall : sig
    type 'm t =
      { left : 'm LeftValue.t
      ; obj : 'm Expression.t
      ; prop : 'm Expression.t
      ; args : 'm Expression.t list
      }
  end

  module AssignFunctionDefinition : sig
    type 'm t =
      { left : 'm LeftValue.t
      ; params : 'm Identifier.t list
      ; body : 'm Statement.t list
      ; async : bool
      ; generator : bool
      ; hoisted : bool
      }
  end

  module AssignDynamicImport : sig
    type 'm t =
      { left : 'm LeftValue.t
      ; arg : 'm Expression.t
      }
  end

  module If : sig
    type 'm t =
      { test : 'm Expression.t
      ; consequent : 'm Statement.t list
      ; alternate : 'm Statement.t list option
      }
  end

  module Switch : sig
    module Case : sig
      type 'm t = ('m, 'm t') Metadata.t

      and 'm t' =
        { test : 'm Expression.t option
        ; body : 'm Statement.t list
        }
    end

    type 'm t =
      { discriminant : 'm Expression.t
      ; cases : 'm Case.t list
      }
  end

  module While : sig
    type 'm t =
      { test : 'm Expression.t
      ; body : 'm Statement.t list
      }
  end

  module ForIn : sig
    type 'm t =
      { left : 'm LeftValue.t
      ; right : 'm Expression.t
      ; body : 'm Statement.t list
      }
  end

  module ForOf : sig
    type 'm t =
      { left : 'm LeftValue.t
      ; right : 'm Expression.t
      ; body : 'm Statement.t list
      ; await : bool
      }
  end

  module Break : sig
    type 'm t = { label : 'm Identifier.t option }
  end

  module Continue : sig
    type 'm t = { label : 'm Identifier.t option }
  end

  module Return : sig
    type 'm t = { arg : 'm Expression.t option }
  end

  module Throw : sig
    type 'm t = { arg : 'm Expression.t }
  end

  module Try : sig
    module Catch : sig
      type 'm t = ('m, 'm t') Metadata.t

      and 'm t' =
        { param : 'm Identifier.t option
        ; body : 'm Statement.t list
        }
    end

    type 'm t =
      { body : 'm Statement.t list
      ; handler : 'm Catch.t option
      ; finalizer : 'm Statement.t list option
      }
  end

  module With : sig
    type 'm t =
      { expr : 'm Expression.t
      ; body : 'm Statement.t list
      }
  end

  module Labeled : sig
    type 'm t =
      { label : 'm Identifier.t
      ; body : 'm Statement.t list
      }
  end

  module Debugger : sig
    type t = unit
  end

  module ImportDecl : sig
    module Specifier : sig
      type 'm t =
        | None
        | Default of 'm Identifier.t
        | Property of 'm Identifier.t
        | Batch of 'm Identifier.t
        | Alias of 'm Identifier.t * 'm Identifier.t
    end

    type 'm t =
      { specifier : 'm Specifier.t
      ; source : string
      }
  end

  module ExportDecl : sig
    module Specifier : sig
      type 'm t =
        | Default of 'm Expression.t
        | Property of 'm Identifier.t
        | Batch of 'm Identifier.t option
        | Alias of 'm Identifier.t * 'm Identifier.t
    end

    type 'm t =
      { specifier : 'm Specifier.t
      ; source : string option
      }
  end

  type 'm t = ('m, 'm t') Metadata.t

  and 'm t' =
    [ `ExprStmt of 'm Expression.t'
    | `VarDecl of LeftValue.t'
    | `AssignSimple of 'm AssignSimple.t
    | `AssignNewObject of 'm AssignNewObject.t
    | `AssignNewArray of 'm AssignNewArray.t
    | `AssignUnopt of 'm AssignUnopt.t
    | `AssignBinopt of 'm AssignBinopt.t
    | `AssignYield of 'm AssignYield.t
    | `StaticLookup of 'm StaticLookup.t
    | `DynamicLookup of 'm DynamicLookup.t
    | `StaticUpdate of 'm StaticUpdate.t
    | `DynamicUpdate of 'm DynamicUpdate.t
    | `StaticDelete of 'm StaticDelete.t
    | `DynamicDelete of 'm DynamicDelete.t
    | `AssignNewCall of 'm AssignNewCall.t
    | `AssignFunctionCall of 'm AssignFunctionCall.t
    | `AssignStaticMethodCall of 'm AssignStaticMethodCall.t
    | `AssignDynamicMethodCall of 'm AssignDynamicMethodCall.t
    | `AssignFunctionDefinition of 'm AssignFunctionDefinition.t
    | `AssignDynamicImport of 'm AssignDynamicImport.t
    | `If of 'm If.t
    | `Switch of 'm Switch.t
    | `While of 'm While.t
    | `ForIn of 'm ForIn.t
    | `ForOf of 'm ForOf.t
    | `Break of 'm Break.t
    | `Continue of 'm Continue.t
    | `Return of 'm Return.t
    | `Throw of 'm Throw.t
    | `Try of 'm Try.t
    | `With of 'm With.t
    | `Labeled of 'm Labeled.t
    | `Debugger of Debugger.t
    | `ImportDecl of 'm ImportDecl.t
    | `ExportDecl of 'm ExportDecl.t
    ]
end =
  Statement

and Operator : sig
  module Unary : sig
    type t =
      | Plus
      | Minus
      | BitwiseNot
      | LogicalNot
      | Typeof
      | Void
      | Await
      | Delete
  end

  module Binary : sig
    type t =
      | Plus
      | Minus
      | Mult
      | Div
      | Mod
      | Exp
      | BitwiseAnd
      | BitwiseOr
      | BitwiseXor
      | ShiftLeft
      | ShiftRight
      | ShiftRightLogical
      | LogicalAnd
      | LogicalOr
      | NullishCoalesce
      | Equal
      | NotEqual
      | StrictEqual
      | StrictNotEqual
      | LessThan
      | LessThanEqual
      | GreaterThan
      | GreaterThanEqual
      | Instanceof
      | In
  end
end =
  Operator

and File : sig
  type 'm t = 'm Statement.t list
end =
  File

and Prog : sig
  type 'm t = (Fpath.t, 'm File.t) Hashtbl.t
end =
  Prog
