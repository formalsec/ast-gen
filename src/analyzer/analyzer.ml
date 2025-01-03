open Graphjs_base
open Graphjs_mdg

let run_injection_returners (_engine : Analysis_engine.t) (_l_return : Node.t) :
    Node.Set.t =
  Node.Set.empty
(* 
  let return_reachability = Reachability.compute l_return
  forall reachable in return_reachability:
    if is_param reachable then return reachable
    if is_return reachable then run_injection_returners reachable
*)

let run_injection_sink (_engine : Analysis_engine.t) (_l_sink : Node.t) :
    Vulnerability.t option =
  None
(* 
  let sink_reachability = Reachability.compute l_sink
  if List.mem TaintSource sink_reachability then Some vulnerability
  else
    foreach reachable in sink_reachability:
      if is_call reachable then
        let callers = Callers.compute reachable in
        forall callers: run_injection_sink caller
      if is_return reachable then
        let returns_reachability = run_injection_returners reachable in
        forall returns_reachability = run_injection_sink returns_reachability    
*)

let run_injection (_engine : Analysis_engine.t) : Vulnerability.t list = []
(* 
  foreach sink in mdg:
    run_injection_sink
*)

let run_prototype (_engine : Analysis_engine.t) : Vulnerability.t list = []

let run (engine : Analysis_engine.t) : Vulnerability.t list =
  Log.debug "Interactability:@\n%a@." Interactability.pp engine.interactability;
  Log.debug "Tainted:@\n%a" Mdg.pp engine.mdg;
  let injection_vulns = run_injection engine in
  let prototype_vulns = run_injection engine in
  injection_vulns @ prototype_vulns
