open Graphjs_base
(* open Graphjs_mdg *)

let run_injection (_engine : Analysis_engine.t) : Vulnerability.t list = []
let run_prototype (_engine : Analysis_engine.t) : Vulnerability.t list = []

let run (engine : Analysis_engine.t) : Vulnerability.t list =
  Log.debug "Callers:@\n%a" Callers.pp engine.callers;
  let injection_vulns = run_injection engine in
  let prototype_vulns = run_injection engine in
  injection_vulns @ prototype_vulns
