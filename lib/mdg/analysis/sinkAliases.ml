open Grammar
open Config

module type InitConfig = sig
  val filename : string
end

module Analysis (Init : InitConfig) : AbstractAnalysis.T = struct
  type t = AnalysisType.sinkAliases

  let analyse (config : t) (_ : State.t) (statement : m Statement.t) : t =
    match statement with
    | (_, AssignSimple { left; right }) ->
      let right = Expression.id_opt right in
      Option.apply ~default:config
        (fun right ->
          let sink = Config.get_function_sink config right in
          Option.apply ~default:config
            (fun (sink : function_sink) ->
              let alias = Identifier.name left in
              Config.add_function_sink config { sink = alias; args = sink.args }
              )
            sink )
        right
    | (_, StaticLookup { left; obj; property; _ }) ->
      let obj = Expression.id_opt obj in
      Option.apply ~default:config
        (fun obj ->
          let package = Config.get_package_sink config obj property in
          Option.apply ~default:config
            (fun (package : package) ->
              let alias = Identifier.name left in
              Config.add_function_sink config
                { sink = alias; args = package.args } )
            package )
        obj
    (* dont do anything on other statements *)
    | _ -> config

  let init () : t = Config.read Init.filename
  let finish (state : t) : AnalysisType.t = AnalysisType.SinkAliases state
end
