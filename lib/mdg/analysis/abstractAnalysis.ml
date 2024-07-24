open Ast.Grammar

module type T = sig
  type t
  val analyse : t -> m Statement.t -> t
  val init : unit -> t

  val finish : t -> AnalysisType.t
end

module Combine (A1 : T) (A2 : T) = struct
  type t = A1.t * A2.t
  let analyse ((a1, a2) : t) (statement : m Statement.t) : t =
    A1.analyse a1 statement, A2.analyse a2 statement 
  
  let init () : t = A1.init (), A2.init ()
  
  let finish ((a1, a2) : t) : AnalysisType.t =
    AnalysisType.Combined (A1.finish a1, A2.finish a2)

end

