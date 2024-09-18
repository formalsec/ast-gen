module Graph = Mdg.Graph'
module ExportedObject= Mdg.ExportedObject
module Config = Setup.Config


let is_reachable (_exportedLocations) (_graph: Graph.t) (node: Graph.Node.t): bool = 
  let _f_node = Option.get node.currFunc in
  (*if (List.mem exportedLocations f_node.loc) then *)
    true
  

let run_queries (graph: Graph.t) (exportedObject) (config: Config.t): bool = 
  let exportedLocations = ExportedObject.get_all_values exportedObject in
  List.exists (fun (sink: Config.functionSink) -> 
    List.exists (fun call_sink -> 
      is_reachable exportedLocations graph call_sink
    ) (Graph.get_callers graph sink.sink)
  ) config.functions




(* foreach sink in sinks {
  foreach call_sink.name in call_nodes[sink] {
    is_reachable graph call_sink 
  } 
}

is_reachable graph node : bool = 
  let f_node = node.function in 
  if is_exported f_node 
  	then true
  	else (
  	  let f_callers = Hashtbl.find f_node.name in 
  	  List.exists (fun caller -> 
  	  	is_reachable graph caller 
  	  ) f_callers 
  	) *)