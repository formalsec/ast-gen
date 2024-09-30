module Graph = Mdg.Graph'
module Node = Graph.Node
module ExportedObject = Mdg.ExportedObject
module Config = Setup.Config

type location = Mdg.Structures.location

let cache : (location, Node.t list) Hashtbl.t = Hashtbl.create 100

let rec is_reachable (graph : Graph.t) (node : Node.t)
  (exported_locs : location list) : bool =
  match Hashtbl.find_opt cache node.abs_loc with
  | None -> is_reachable' graph node exported_locs
  | Some f_args ->
    List.exists (fun arg -> is_reachable graph arg exported_locs) f_args

and is_reachable' (graph : Graph.t) (node : Node.t)
  (exported_locs : location list) : bool =
  print_endline ("Processing: " ^ Node.label node);
  match node.func with
  | None ->
    print_endline "Node has no parent";
    false
  | Some f_node ->
    let f_node_loc = Node.get_abs_loc f_node in
    let p_nodes = Graph.find_tainted_parameter graph f_node node in
    if List.mem f_node_loc exported_locs then
      let _ = print_endline ("Exported: " ^ Node.label f_node) in
      true
    else if p_nodes = [] then false
    else
      let _ = print_endline ("Finding calls to: " ^ Node.label f_node) in
      let f_callers =
        Option.value ~default:[]
          (Option.map (Graph.get_callers graph) (Node.get_func_name f_node))
      in
      let f_arg_locs =
        List.map
          (fun (f_caller : Node.t) ->
            let args = Graph.get_arg_locations graph f_caller.abs_loc in
            snd (List.split args) )
          f_callers
      in
      let f_args =
        List.flatten
          (List.map
             (fun f_arg_loc -> List.map (Graph.find_node graph) f_arg_loc)
             f_arg_locs )
      in
      let f_args' =
        List.filter
          (fun (f : Node.t) ->
            List.exists
              (fun p -> String.equal (Node.get_id_name f) (Node.get_id_name p))
              p_nodes )
          f_args
      in
      print_endline
        ("Taited arguments: " ^ String.concat ", " (List.map Node.label f_args'));
      List.exists (fun arg -> is_reachable graph arg exported_locs) f_args'

let print_vuln (call_sink : Node.t) : unit =
  Format.printf "{@\n  file: \"%s\"@\n  sink: %s@\n  sink_lineno: %d@\n}@\n@."
    call_sink.code_loc._file (Node.label call_sink)
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

let run_prototype_polution_queries (_graph : Graph.t)
  (_exportedObject : ExportedObject.t) (_config : Config.t) : unit =
  ()

let run_queries (graph : Graph.t) (exportedObject : ExportedObject.t)
  (config : Config.t) : unit =
  run_tainted_queries graph exportedObject config
