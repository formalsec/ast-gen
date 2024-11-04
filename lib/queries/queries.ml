module Graph = Mdg.Graph'
module Node = Graph.Node
module ExportedObject = Mdg.ExportedObject
module Config = Setup.Config
module Edge = Graph.Edge
module EdgeSet = Graph.EdgeSet
module NodeSet = Graph.NodeSet
open Auxiliary.Functions
open Auxiliary.Structures

type location = Mdg.Structures.location

let print_path (nodes : Node.t list) : unit = print_endline (String.concat " <- " (List.map Node.get_abs_loc nodes))


let rec is_reachable (graph : Graph.t) (sink_node : Node.t) : bool = 
  let sink_call_node = Graph.get_call_node graph sink_node in
  let sensitive_inputs = Graph.get_sensitive_inputs graph sink_node sink_call_node in
  is_reachable' graph sink_call_node sensitive_inputs

and is_reachable' (graph : Graph.t) (call_node : Node.t) (sensitive_inputs : int list) : bool =
  let func_defs = reachable_func_defs graph call_node in 
  (* get all possible paths between the function definition node and the call node *)
  let paths = List.map (fun func_def -> (func_def, Graph.reaches graph func_def call_node)) func_defs in
  (* perform two operations: 
      (1) filter the paths that dont reach sensitive inputs of the call node
      (2) get the source parameter 
  .*)
  let src_params = List.map (fun (func_def, paths') ->
    let filtered_paths = List.filter (fun path ->  
      if List.length path >= 3 
        then 
          let arg = List.nth path 1 in 
          let arg_index = Graph.get_argument_index graph arg call_node in 
          List.exists (flip List.mem sensitive_inputs) arg_index
        else false
    ) paths' in 

    (* (2) get the source parameter index *)
    let source_params = List.fold_left (fun acc path -> 
      let param_position = List.length path - 2 in 
      if param_position >= 0
        then 
          let param = List.nth path param_position in 
          let param_index = Graph.get_param_index graph param func_def in
          List.fold_left (flip IntSet.add) acc param_index
        else acc
    ) IntSet.empty filtered_paths in 
    
    let res = (func_def, IntSet.elements source_params) in 
    res
  ) paths in 

  (* check if the sensitive inputs reach a attacker controlled function *)
  List.exists (fun (func_def, sensitive_params) ->
    let f_loc = Node.get_abs_loc func_def in  
    List.length sensitive_params > 0 && (Node.is_source func_def || List.exists (fun caller -> is_reachable' graph caller sensitive_params) (Graph.get_callers graph f_loc))
  ) src_params

and reachable_func_defs (graph : Graph.t) (node : Node.t) : Node.t list =
  let rec aux (graph : Graph.t) (node : Node.t) (result : Node.t list) : Node.t list =
    match node.func with 
      | None -> result
      | Some l_func -> 
        let func_node = Graph.find_node graph l_func in
        aux graph func_node (func_node :: result)
  in

  aux graph node []

(* let rec is_reachable (graph : Graph.t) (node : Node.t) : bool =
  (* get function definition node where the node argument was defined *)
  let fun_defs = is_reachable_new graph node [] in 
  List.exists (fun f_node -> 
    let f_name = Node.get_func_name f_node in
    let f_node_loc = Node.get_abs_loc f_node in
    let p_nodes = Graph.find_tainted_parameter graph f_node node in

    if p_nodes = []         then false
    else if f_node.isSource then true
    else
      let f_callers = Graph.get_callers graph f_node_loc in
      let f_args =
        List.flatten
        @@ List.map
                (List.map (Graph.find_node graph)
                << snd << List.split
                << Graph.get_arg_locations graph
                << Node.get_abs_loc)
              f_callers
      in
      let f_returners =
        Option.bind f_name (Hashtbl.find_opt graph.returners)
        |> Option.value ~default:[]
      in
      List.exists
        (fun arg -> is_reachable graph arg)
        (f_args @ f_returners)
  ) fun_defs *)



let run_tainted_queries (graph : Graph.t) (_config : Config.t) : Vulnerability.t list =
  let vulns : Vulnerability.t list ref = ref [] in 

  NodeSet.iter (fun sink_node ->
    if is_reachable graph sink_node then (
      let vuln = Vulnerability.create' sink_node in 
      vulns := vuln :: !vulns
    )
  ) !(graph.sinks);
  
  !vulns
  

let run_queries (_ppf : Format.formatter) (graph : Graph.t) (config : Config.t) (output_dir : Fpath.t): unit =
  let taint_vulns = run_tainted_queries graph config in

  let summary_file  = Fpath.(to_string @@ (output_dir / "taint_summary_detection.json")) in
  let oc = open_out summary_file in
  output_string oc (Vulnerability.to_string' taint_vulns);
  close_out oc;

  if List.length taint_vulns > 0 then 
    print_endline ("[INFO] Detected " ^ string_of_int (List.length taint_vulns) ^ " vulnerabilities.")
  else
    print_endline ("[INFO] No vulnerabilities detected.")

