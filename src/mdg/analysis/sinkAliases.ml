open Graphjs_base
open Graphjs_setup
open Graphjs_ast
open Grammar
open Funcs
open Config

module type InitConfig = sig
  val filename : string
end

module Analysis (Init : InitConfig) : AbstractAnalysis.T = struct

  type t = AnalysisType.sinkAliases
  
  let analyse (config : t) (_ : State.t) (statement : m Statement.t) : t = 
    match statement with
      | _, AssignSimple {left; right} -> 
        let right = Expression.get_id_opt right in
        map_default (fun right ->
          let sink = Config.get_function_sink_info config right in 
          map_default (fun (sink : functionSink) ->
            let alias = Identifier.get_name left in 
            Config.add_function_sink config {sink = alias; args = sink.args}
          ) config sink;

        ) config right
        
      | _, StaticLookup {left; _object; property; _} -> 
        let _object = Expression.get_id_opt _object in
        map_default (fun obj ->
          let package = Config.get_package_sink_info config obj property in 
          map_default (fun (package : package) ->
            let alias = Identifier.get_name left in 
            Config.add_function_sink config {sink = alias; args = package.args}
          ) config package
        ) config _object;
      
      (* dont do anything on other statements *)
      | _ -> config

  let init () : t = Config.read Init.filename
  
  let finish (state : t) : AnalysisType.t =
    AnalysisType.SinkAliases state

end
