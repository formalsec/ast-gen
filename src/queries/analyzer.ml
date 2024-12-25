(* open Graphjs_base *)
(* open Graphjs_mdg *)

let run_injection (_engine : Query_engine.t) : Vulnerability.t list = []
let run_prototype (_engine : Query_engine.t) : Vulnerability.t list = []

let run (engine : Query_engine.t) : Vulnerability.t list =
  let injection_vulns = run_injection engine in
  let prototype_vulns = run_injection engine in
  injection_vulns @ prototype_vulns
