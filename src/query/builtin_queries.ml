open Graphjs_base
open Graphjs_mdg

module InjectionUnfold = struct
  let run (engine : Query_engine.t) : Vulnerability.Set.t =
    let vulns = Vulnerability.Set.empty in
    let l_sink_calls = Query_engine.tainted_sink_calls engine in
    Fun.flip2 List.fold_left vulns l_sink_calls (fun vulns (l_call, l_sink) ->
        let sink = Node.sink l_sink in
        let ls_args = Query_engine.tainted_sink_args engine l_call sink in
        if Node.Set.exists (Query_engine.is_tainted engine) ls_args then
          let vuln = Vulnerability.tainted l_call sink in
          Vulnerability.Set.add vuln vulns
        else vulns )
end

let run (engine : Query_engine.t) : Vulnerability.Set.t =
  let injection_vulns = InjectionUnfold.run engine in
  injection_vulns
