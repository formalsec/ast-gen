module Graph = Mdg.Graph'
module Node = Graph.Node
module ExportedObject = Mdg.ExportedObject
module Config = Setup.Config

type location = Mdg.Structures.location

let rec is_reachable (graph : Graph.t) (node : Node.t)
  (exported_locs : location list) : bool =
  let f_node = Option.get node.func in
  let f_node_loc = Node.get_abs_loc f_node in
  let p_nodes = Graph.find_tainted_parameter graph f_node node in
  if p_nodes = [] then false
  else if List.mem f_node_loc exported_locs then true
  else
    let f_callers =
      Option.value
        (Option.map (Graph.get_callers graph) (Node.get_func_name f_node))
        ~default:[]
    in
    List.exists
      (fun caller -> is_reachable graph caller exported_locs)
      f_callers

let print_vuln (call_sink : Graph.Node.t) : unit =
  Format.printf "{@\n  file: \"%s\"@\n  sink: %s@\n  sink_lineno: %d@\n}@\n@."
    call_sink.code_loc._file
    (Graph.Node.label call_sink)
    call_sink.code_loc._start.line

let run_tainted_queries (graph : Graph.t) (exportedObject : ExportedObject.t)
  (config : Config.t) : unit =
  let exported_locs = ExportedObject.get_all_values exportedObject in
  List.iter
    (fun (sink : Config.functionSink) ->
      List.iter
        (fun call_sink ->
          if is_reachable graph call_sink exported_locs then
            print_vuln call_sink )
        (Graph.get_callers graph sink.sink) )
    config.functions

let run_prototype_polution_queries (graph : Graph.t)
  (exportedObject : ExportedObject.t) (config : Config.t) : unit =
  ()

let run_queries (graph : Graph.t) (exportedObject : ExportedObject.t)
  (config : Config.t) : unit =
  run_tainted_queries graph exportedObject config
