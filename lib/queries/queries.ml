module Graph = Mdg.Graph'
module Node = Graph.Node
module ExportedObject = Mdg.ExportedObject
module Config = Setup.Config
module Funcs = Auxiliary.Functions

type location = Mdg.Structures.location

let pp_nodes (ppf : Format.formatter) (nodes : Node.t list) : unit =
  Format.fprintf ppf "{ %s }"
    (String.concat ", " (List.map Node.get_abs_loc nodes))

let rec is_reachable (graph : Graph.t) (node : Node.t)
  (exported_locs : location list) : bool =
  Format.printf "========================================@.";
  Format.printf "target node:    %s@." (Node.get_abs_loc node);
  match node.func with
  | None -> false
  | Some f_node ->
    Format.printf "function node:  %s@\n@." (Node.get_abs_loc f_node);
    let f_name = Node.get_func_name f_node in
    let f_node_loc = Node.get_abs_loc f_node in
    let p_nodes = Graph.find_tainted_parameter graph f_node node in
    Format.printf "@\np_nodes:     %a@." pp_nodes p_nodes;
    if p_nodes = [] then false
    else if List.mem f_node_loc exported_locs then true
    else
      let f_callers = Graph.get_callers graph f_node_loc in
      Format.printf "f_callers:   %a@." pp_nodes f_callers;
      let f_args =
        List.flatten
        @@ List.map
             Funcs.(
               List.map (Graph.find_node graph)
               << snd << List.split
               << Graph.get_arg_locations graph
               << Node.get_abs_loc )
             f_callers
      in
      Format.printf "f_args:      %a@." pp_nodes f_args;
      let f_returners =
        Option.bind f_name (Hashtbl.find_opt graph.returners)
        |> Option.value ~default:[]
      in
      Format.printf "f_returners: %a@." pp_nodes f_returners;
      List.exists
        (fun arg -> is_reachable graph arg exported_locs)
        (f_args @ f_returners)

let print_vuln (ppf : Format.formatter) (vuln_t : string) (call_sink : Node.t) :
  unit =
  Format.fprintf ppf "========================================@\n@\n";
  Format.fprintf ppf
    "{@\n\
    \  \"vuln_type\": %S@\n\
    \  \"file\": %S@\n\
    \  \"sink\": %S@\n\
    \  \"sink_lineno\": %d@\n\
     }@\n"
    vuln_t call_sink.code_loc._file (Node.label call_sink)
    call_sink.code_loc._start.line

let run_tainted_queries (ppf : Format.formatter) (graph : Graph.t)
  (exportedObject : ExportedObject.t) (config : Config.t) : unit =
  let exported_locs = ExportedObject.get_all_values exportedObject in
  List.iter
    (fun (sink : Config.functionSink) ->
      List.iter
        (fun call_sink ->
          if is_reachable graph call_sink exported_locs then
            print_vuln ppf sink.vuln_t call_sink )
        (Graph.get_callers_old graph sink.sink) )
    config.functions

let run_prototype_polution_queries (_graph : Graph.t)
  (_exportedObject : ExportedObject.t) (_config : Config.t) : unit =
  ()

let run_queries (ppf : Format.formatter) (graph : Graph.t)
  (exportedObject : ExportedObject.t) (config : Config.t) : unit =
  run_tainted_queries ppf graph exportedObject config
