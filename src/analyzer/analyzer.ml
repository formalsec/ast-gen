open Graphjs_base
open Graphjs_mdg
module Worklist = Analysis_engine.Worklist

let run_injection_param (engine : Analysis_engine.t) (l_param : Node.t)
    (props : Property.t list) : Analysis_engine.t =
  let callers = Analysis_engine.callers engine l_param in
  Log.debug "callers = %a" Node.Set.pp callers;
  Fun.flip2 Node.Set.fold callers engine (fun l_arg engine ->
      let nodes = Analysis_engine.nested_lookup engine l_arg props in
      Log.debug "callers.props = %a" Node.Set.pp nodes;
      Analysis_engine.enqueue_all engine nodes )

let run_injection_return (engine : Analysis_engine.t) (l_call : Node.t)
    (props : Property.t list) : Analysis_engine.t =
  let returns = Analysis_engine.returns engine l_call in
  Log.debug "returns = %a" Node.Set.pp returns;
  Fun.flip2 Node.Set.fold returns engine (fun l_arg engine ->
      let nodes = Analysis_engine.nested_lookup engine l_arg props in
      Log.debug "returns.props = %a" Node.Set.pp nodes;
      Analysis_engine.enqueue_all engine nodes )

let run_injection_source (source : Sources.Source.t) (engine : Analysis_engine.t)
    : Analysis_engine.t =
  match source with
  | Param (l_param, props) -> run_injection_param engine l_param props
  | Retn (l_retn, props) -> run_injection_return engine l_retn props
  | TaintSource -> Log.fail "unexpected taint_source information source"

let run_injection_node (engine : Analysis_engine.t) : Node.t option =
  Fun.flip Analysis_engine.run engine (fun node ->
      Log.debug "processing: %a" Node.pp node;
      let sources = Analysis_engine.sources engine node in
      if Analysis_engine.is_attacker_controlled sources then
        Analysis_engine.result engine node
      else Sources.Set.fold run_injection_source sources engine )

let run_injection (engine : Analysis_engine.t) : Vulnerability.t list =
  let l_sinks = Analysis_engine.get_sinks engine in
  Fun.flip2 Node.Set.fold l_sinks [] (fun l_sink vulns ->
      let sink = Node.sink l_sink in
      let ls_args = Analysis_engine.get_sink_args engine l_sink in
      let engine' = Analysis_engine.enqueue_all engine ls_args in
      match run_injection_node engine' with
      | None -> vulns
      | Some node -> Analysis_engine.vulnerability engine' sink node :: vulns )

(* let run_injection (_engine : Analysis_engine.t) : Vulnerability.t list = [] *)
let run_prototype (_engine : Analysis_engine.t) : Vulnerability.t list = []

let run (engine : Analysis_engine.t) : Vulnerability.t list =
  (* Log.debug "Graph:@\n%a@\n" Mdg.pp engine.mdg; *)
  (* Log.debug "Callers:@\n%a@\n" Callers.pp engine.callers; *)
  Log.debug "Exported:@\n%a@\n" Exported.pp engine.exported;
  (* Log.debug "Sources:@\n%a@\n" Sources.pp engine.sources; *)
  let injection_vulns = run_injection engine in
  let prototype_vulns = run_prototype engine in
  injection_vulns @ prototype_vulns
