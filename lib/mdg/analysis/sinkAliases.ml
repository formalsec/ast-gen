open Ast.Grammar
open Setup

module type InitConfig = sig
  val filename : string
end

module Analysis (Init : InitConfig) : AbstractAnalysis.T = struct
  include Init

  type t = Config.t
  let analyse (analysis : t) (statement : m Statement.t) : t = 
    match statement with
      | _, AssignSimple _ -> analysis
      | _, StaticLookup _ -> analysis
      
      (* dont do anything on other statements *)
      | _ -> analysis

  let init () : t = Config.read filename
end
