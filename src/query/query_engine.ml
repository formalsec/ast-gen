open Graphjs_base
open Graphjs_mdg

type t = { mdg : Mdg.t }

let initialize (mdg : Mdg.t) : t = { mdg }

let tainted_sinks (engine : t) : Node.t list =
  Fun.flip2 Hashtbl.fold engine.mdg.nodes [] (fun _ l_node acc ->
      if Node.is_taint_sink l_node then l_node :: acc else acc )

let tainted_sink_calls (engine : t) : (Node.t * Node.t) list =
  let l_sinks = tainted_sinks engine in
  Fun.flip2 List.fold_left [] l_sinks (fun acc l_sink ->
      let l_calls = Mdg.get_function_callers engine.mdg l_sink in
      List.map (fun l_call -> (l_call, l_sink)) l_calls @ acc )

let tainted_sink_args (engine : t) (l_call : Node.t) (sink : Tainted.sink) :
    Node.Set.t =
  Mdg.get_arguments engine.mdg l_call
  |> List.filter (fun (idx, _) -> List.mem idx sink.args)
  |> List.map (fun (_, l_arg) -> l_arg)
  |> Node.Set.of_list

let is_tainted (_engine : t) (_l_node : Node.t) : bool = false
