open Graphjs_mdg

module TaintedUnfold = struct
  let run (engine : Query_engine.t) : Vulnerability.Set.t =
    let vulns = Vulnerability.Set.empty in
    let l_sink_calls = Query_engine.tainted_sink_calls engine in
    Fun.flip2 List.fold_left vulns l_sink_calls (fun vulns (l_call, l_sink) ->
        Time.timeout_check engine.curr_time;
        let sink = Node.sink l_sink in
        let ls_args = Query_engine.tainted_sink_args engine l_call sink in
        if Node.Set.exists (Query_engine.is_tainted engine) ls_args then
          let vuln = Vulnerability.tainted l_call sink in
          Vulnerability.Set.add vuln vulns
        else vulns )
end

module PrototypeUnfold = struct
  let find_polluted_lookups (engine : Query_engine.t) : Node.Set.t =
    let ls_lookup = Query_engine.dynamic_lookups engine in
    Fun.flip Node.Set.filter ls_lookup (fun l_lookup ->
        let ls_dep = Mdg.get_dependencies engine.mdg l_lookup in
        List.exists (Query_engine.is_tainted engine) ls_dep )

  let find_polluted_lookup_versions (engine : Query_engine.t)
      (ls_lookup : Node.Set.t) : Node.Set.t =
    Fun.flip2 Node.Set.fold ls_lookup Node.Set.empty (fun l_lookup acc ->
        let ls_versions = Query_engine.object_versions engine l_lookup in
        Node.Set.union ls_versions acc )

  let is_polluted_update_value (engine : Query_engine.t) (l_update : Node.t)
      (ls_props : Node.Set.t) : bool =
    let mdg = engine.mdg in
    let rec_f l_rec = Option.equal Node.equal (Some l_rec) l_update.parent in
    let cs_f l_cs = Mdg.get_called_functions mdg l_cs |> Node.Set.of_list in
    let ls_retn = Node.Set.filter Node.is_return ls_props in
    let ls_cs = Node.Set.map (Mdg.get_call_of_return mdg) ls_retn in
    let ls_rec = Node.Set.map_flat cs_f ls_cs in
    not (Node.Set.exists rec_f ls_rec)

  let has_polluted_update (engine : Query_engine.t) (l_update : Node.t) : bool =
    let ls_dep = Mdg.get_dependencies engine.mdg l_update in
    if List.exists (Query_engine.is_tainted engine) ls_dep then
      let ls_props = Mdg.get_property engine.mdg l_update Dynamic in
      if is_polluted_update_value engine l_update (Node.Set.of_list ls_props)
      then List.exists (Query_engine.is_tainted engine) ls_props
      else false
    else false

  let run (engine : Query_engine.t) : Vulnerability.Set.t =
    let vulns = Vulnerability.Set.empty in
    let ls_lookup = Query_engine.dynamic_lookups engine in
    let ls_update = find_polluted_lookup_versions engine ls_lookup in
    Fun.flip2 Node.Set.fold ls_update vulns (fun l_update vulns ->
        Time.timeout_check engine.curr_time;
        if has_polluted_update engine l_update then
          let vuln = Vulnerability.pollution l_update in
          Vulnerability.Set.add vuln vulns
        else vulns )
end

let run (engine : Query_engine.t) : Vulnerability.Set.t =
  Log.debug "tainted";
  let tainted_vulns = TaintedUnfold.run engine in
  Log.debug "proto";
  let prototype_vulns = PrototypeUnfold.run engine in
  Vulnerability.Set.union tainted_vulns prototype_vulns
