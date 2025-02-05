open Graphjs_base
open Graphjs_mdg
module Worklist = Analysis_engine.Worklist

let run_injection_param (engine : Analysis_engine.t) (l_param : Node.t)
    (_props : string option list) : Analysis_engine.t =
  let callers = Analysis_engine.callers engine l_param in
  Log.debug "%a" Node.Set.pp callers;
  engine

let run_injection_return (engine : Analysis_engine.t) (_l_retn : Node.t) :
    Analysis_engine.t =
  engine

let run_injection_sink (engine : Analysis_engine.t) (l_sink : Node.t) :
    Analysis_engine.t =
  match l_sink.kind with
  | TaintSink sink ->
    let args = Tainted.args sink in
    let callers = Analysis_engine.callers engine l_sink in
    Fun.flip2 Node.Set.fold callers engine (fun l_call acc ->
        Fun.flip2 List.fold_left acc args (fun acc idx ->
            let ls_arg = Mdg.get_argument engine.mdg l_call idx in
            Fun.flip2 List.fold_left acc ls_arg (fun acc l_arg ->
                Analysis_engine.enqueue acc l_arg ) ) )
  | _ -> Log.fail "unexpected node kind in injection sink"

let run_injection_source (engine : Analysis_engine.t) :
    Reachability.Source.t -> Analysis_engine.t = function
  | Param (l_param, props) -> run_injection_param engine l_param props
  | Ret l_retn -> run_injection_return engine l_retn
  | TaintSink l_sink -> run_injection_sink engine l_sink
  | TaintSource -> Log.fail "unexpected taint_source information source"

let run_injection_node (engine : Analysis_engine.t) : Node.t option =
  Fun.flip Analysis_engine.run engine (fun node ->
      let sources = Analysis_engine.sources engine node in
      if Analysis_engine.is_attacker_controlled sources then
        Analysis_engine.result engine node
      else
        Reachability.Sources.fold (Fun.flip run_injection_source) sources engine )

let run_injection (engine : Analysis_engine.t) : Vulnerability.t list =
  let l_sinks = Analysis_engine.get_sinks engine in
  Fun.flip2 Node.Set.fold l_sinks [] (fun l_sink vulns ->
      let engine' = Analysis_engine.enqueue engine l_sink in
      let sink = Node.sink l_sink in
      match run_injection_node engine' with
      | None -> vulns
      | Some node -> Analysis_engine.vulnerability engine' sink node :: vulns )

let run_prototype (_engine : Analysis_engine.t) : Vulnerability.t list = []

let run (engine : Analysis_engine.t) : Vulnerability.t list =
  Log.debug "Graph:@\n%a@\n" Mdg.pp engine.mdg;
  Log.debug "Interactability:@\n%a@\n" Interactability.pp engine.interactability;
  let injection_vulns = run_injection engine in
  let prototype_vulns = run_prototype engine in
  injection_vulns @ prototype_vulns
