open Ast.Grammar
open Setup

module type InitConfig = sig
  val filename : string
end

module Analysis (Init : InitConfig) : AbstractAnalysis.T = struct

  type t = AnalysisType.sinkAliases
  let analyse (analysis : t) (_statement : m Statement.t) : t = 
    (* match statement with
      | _, AssignSimple {left; right} -> analysis
      | _, StaticLookup {left; _object; property}-> analysis
      
      (* dont do anything on other statements *)
      | _ -> analysis *)
      analysis

  let init () : t = Config.read Init.filename
  
  let finish (state : t) : AnalysisType.t =
    AnalysisType.SinkAliases state

end
