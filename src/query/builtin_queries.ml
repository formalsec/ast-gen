open Graphjs_mdg

module TaintedUnfold = struct
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

module PrototypeUnfold = struct
  let find_polluted_updates (engine : Query_engine.t) : Node.Set.t =
    let ls_update = Query_engine.dynamic_updates engine in
    Fun.flip Node.Set.filter ls_update (fun l_update ->
        let ls_dep = Mdg.get_dependents engine.mdg l_update in
        if List.exists (Query_engine.is_tainted engine) ls_dep then
          let ls_prop = Mdg.get_property engine.mdg l_update Dynamic in
          List.exists (Query_engine.is_tainted engine) ls_prop
        else false )

  let find_polluted_lookup (engine : Query_engine.t) (l_update : Node.t) :
      Node.Set.t =
    let ls_orig = Mdg.object_orig_versions engine.mdg l_update in
    Fun.flip Node.Set.filter ls_orig (fun l_orig ->
        let ls_owner = Mdg.get_object_of_property engine.mdg l_orig Dynamic in
        if not (List.is_empty ls_owner) then
          let ls_dep = Mdg.get_dependents engine.mdg l_orig in
          List.exists (Query_engine.is_tainted engine) ls_dep
        else false )

  let run (engine : Query_engine.t) : Vulnerability.Set.t =
    let vulns = Vulnerability.Set.empty in
    let ls_update = find_polluted_updates engine in
    Fun.flip2 Node.Set.fold ls_update vulns (fun l_upd vulns ->
        let ls_lookup = find_polluted_lookup engine l_upd in
        if not (Node.Set.is_empty ls_lookup) then
          let vuln = Vulnerability.pollution l_upd in
          Vulnerability.Set.add vuln vulns
        else vulns )
end

let run (engine : Query_engine.t) : Vulnerability.Set.t =
  let tainted_vulns = TaintedUnfold.run engine in
  let prototype_vulns = PrototypeUnfold.run engine in
  Vulnerability.Set.union tainted_vulns prototype_vulns
