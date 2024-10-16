module Graph = Mdg.Graph'
module Node = Graph.Node
module ExportedObject = Mdg.ExportedObject
module Config = Setup.Config
module Funcs = Auxiliary.Functions
module Edge = Graph.Edge
module EdgeSet = Graph.EdgeSet
open Auxiliary.Structures

type location = Mdg.Structures.location

let pp_nodes (ppf : Format.formatter) (nodes : Node.t list) : unit =
  Format.fprintf ppf "{ %s }"
    (String.concat ", " (List.map Node.get_abs_loc nodes))

let rec is_reachable (graph : Graph.t) (node : Node.t)
  (exported_locs : location list) : bool =
  Format.printf "========================================@\n";
  Format.printf "target node:    %s@\n" (Node.get_abs_loc node);
  match node.func with
  | None -> false
  | Some f_node ->
    Format.printf "function node:  %s@\n@." (Node.get_abs_loc f_node);
    let f_name = Node.get_func_name f_node in
    let f_node_loc = Node.get_abs_loc f_node in
    let p_nodes = Graph.find_tainted_parameter graph f_node node in
    Format.printf "@\np_nodes:     %a@\n" pp_nodes p_nodes;
    if p_nodes = [] then false
    else if List.mem f_node_loc exported_locs then true
    else
      let f_callers = Graph.get_callers graph f_node_loc in
      Format.printf "f_callers:   %a@\n" pp_nodes f_callers;
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
  (exported_locs: location list) (config : Config.t) : unit =
  List.iter
    (fun (sink : Config.functionSink) ->
      List.iter
        (fun call_sink ->
          if is_reachable graph call_sink exported_locs then
            print_vuln ppf sink.vuln_t call_sink )
        (Graph.get_callers_old graph sink.sink) )
    config.functions

let run_prototype_polution_queries (ppf : Format.formatter) (graph : Graph.t) 
    (exported_locs: location list) : unit =
  let fold_edges_f (l: location) (edges: EdgeSet.t) = EdgeSet.fold (fun edge acc -> (l, edge) :: acc) edges [] in
  let is_dynamic_prop_f (edge: Edge.t): bool = match edge._type with | Property None -> true | _ -> false in
  let is_dynamic_version_f (edge: Edge.t): bool = match edge._type with | Version None -> true | _ -> false in
  let all_nodes = graph.nodes |> HashTable.to_seq_keys |> List.of_seq in
  let all_edges = all_nodes |> List.map (fun l -> (l, Graph.find_edges graph l)) |> List.fold_left (fun acc (l, edges) ->  fold_edges_f l edges @ acc) [] in
  let dynamic_lookups = List.filter (fun (_ , edge) -> is_dynamic_prop_f edge) all_edges in
  let dynamic_versions = List.filter (fun (_ , edge) -> is_dynamic_version_f edge) all_edges in
  List.iter (fun (_, edge) -> 
    let loc_1 = Edge.get_to edge in
    Format.fprintf ppf ".......................................................................@\n";
    Format.fprintf ppf "%s@\n" loc_1;
    let edges_1 = List.filter (fun (l, _) -> String.equal loc_1 l) dynamic_versions in 
    List.iter (fun (_ , edge) ->
      let loc_2 = Edge.get_to edge in
      Format.fprintf ppf "  %s@\n" loc_2;
      let edges_2 = List.filter (fun (l, _) -> String.equal loc_2 l) dynamic_lookups in
      List.iter (fun (_, edge) -> 
        let loc_3 = Edge.get_to edge in
        Format.fprintf ppf "    %s@\n" loc_3;
        let tainted_1 = is_reachable graph (Graph.find_node graph loc_1) exported_locs in
        let tainted_2 = is_reachable graph (Graph.find_node graph loc_2) exported_locs in
        let tainted_3 = is_reachable graph (Graph.find_node graph loc_3) exported_locs in
        Format.fprintf ppf "========================================@\n";
        Format.fprintf ppf "%s:%b | %s:%b | %s:%b@\n" loc_1 tainted_1 loc_2 tainted_2 loc_3 tainted_3;
        if (tainted_1 && tainted_2 && tainted_3) 
          then Format.fprintf ppf "found prototype polution on line %d@\n" (Graph.find_node graph loc_2).code_loc._start.line
      ) edges_2
    ) edges_1
  ) dynamic_lookups



let run_queries (_ppf : Format.formatter) (_graph : Graph.t)
  (_exportedObject : ExportedObject.t) (_config : Config.t) : unit =
  let _exported_locs = ExportedObject.get_all_values _exportedObject in
  (* run_tainted_queries _ppf _graph _exported_locs _config; *)
  run_prototype_polution_queries _ppf _graph _exported_locs;
  ()
