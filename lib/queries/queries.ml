module Graph = Mdg.Graph'
module Node = Graph.Node
module ExportedObject= Mdg.ExportedObject
module Config = Setup.Config
type location = Mdg.Structures.location

let rec is_reachable (graph: Graph.t) (node: Node.t) (exported_locs : location list): bool = 
  let f_node     = Option.get node.func in
  let f_node_loc = Node.get_abs_loc f_node in
  let p_nodes    = Graph.find_tainted_parameter graph f_node node in 

  List.iter (fun node -> print_endline (Node.get_abs_loc node)) p_nodes;
  
  if p_nodes = [] (* check if any of the arguments of the function call is tainted *)
    then false
  else if (List.mem f_node_loc exported_locs) (* check if the function where the call is called is exported *)
    then true
  else (
    let f_callers = Option.value (Option.map (Graph.get_callers graph) (Node.get_func_name f_node)) ~default:[] in
     List.exists (fun caller -> 
      is_reachable graph caller exported_locs
     ) f_callers
  ) 
  

let run_queries (graph: Graph.t) (exportedObject : ExportedObject.t) (config: Config.t): bool = 
  let exported_locs = ExportedObject.get_all_values exportedObject in

  List.exists (fun (sink: Config.functionSink) -> 
    List.exists (fun call_sink -> 
      is_reachable graph call_sink exported_locs
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