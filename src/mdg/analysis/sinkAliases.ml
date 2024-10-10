open Graphjs_base
open Graphjs_config
open Graphjs_ast
open Grammar
open Tainted

module type InitConfig = sig
  val filename : string
end

module Analysis (Init : InitConfig) : AbstractAnalysis.T = struct

  type t = AnalysisType.sinkAliases
  
  let analyse (config : t) (_ : State.t) (statement : m Statement.t) : t = 
    match statement with
      | _, AssignSimple {left; right} -> 
        let right = Expression.get_id_opt right in
        Option.apply (fun right ->
          let sink = Tainted.get_function_sink_info config right in 
          Option.apply (fun (sink : functionSink) ->
            let alias = Identifier.get_name left in 
            Tainted.add_function_sink config {sink = alias; args = sink.args}
          ) ~default:config sink;

        ) ~default:config right
        
      | _, StaticLookup {left; _object; property; _} -> 
        let _object = Expression.get_id_opt _object in
        Option.apply (fun obj ->
          let package = Tainted.get_package_sink_info config obj property in 
          Option.apply (fun (package : package) ->
            let alias = Identifier.get_name left in 
            Tainted.add_function_sink config {sink = alias; args = package.args}
          ) ~default:config package
        ) ~default:config _object;
      
      (* dont do anything on other statements *)
      | _ -> config

  let init () : t = Tainted.read Init.filename
  
  let finish (state : t) : AnalysisType.t =
    AnalysisType.SinkAliases state

end
