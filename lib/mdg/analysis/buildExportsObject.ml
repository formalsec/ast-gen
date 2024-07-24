open Ast.Grammar
open Structures
open Auxiliary.Structures
open Auxiliary.Functions


module Analysis : AbstractAnalysis.T = struct
  type t = AnalysisType.buildExportsObject

  let analyse (state : t) (statement : m Statement.t) : t = 
    match statement with
      | _, AssignSimple {left; right} -> 
        let right = Expression.get_id_opt right in 
        if right = Some "exports" then
          let alias = Identifier.get_name left in
          let aliases = AliasSet.add alias state.exportsAliases in 
          {state with exportsAliases = aliases}
        else state

      | _, StaticLookup {left; _object; property; _} -> 
        let _object = Expression.get_id_opt _object in 
        if _object = Some "module" && property = "exports" then
          let alias = Identifier.get_name left in 
          let aliases = AliasSet.add alias state.moduleExportsAliases in 
          {state with moduleExportsAliases = aliases}
        else state

      | _, StaticUpdate {_object; property; right; _} -> 
        let _object = Expression.get_id_opt _object in 
        map_default (fun _object ->
          (* update of a property of exports *)
          if state.exportsIsModuleExports && (_object = "exports" || AliasSet.mem _object state.exportsAliases) then
            (* TODO : maybe instead of name we stor the location of the associated object *)
            let right = Expression.get_id_opt right in 
            option_may (HashTable.replace state.exportsAssigns property) right;
            state
          (* update of the module.exports value *)
          
          else if _object = "module" && property = "exports" then 
            (* TODO : maybe instead of name we stor the location of the associated object *)
            let right = Expression.get_id_opt right in 
            HashTable.clear state.moduleExportsAssigns;
            HashTable.clear state.exportsAssigns;
            { state with 
               _moduleExportsObject = Option.get(right);
               exportsIsModuleExports = false;
               moduleExportsAliases = AliasSet.empty;
               exportsAliases = AliasSet.empty;
            }
          
          (* update of a property of module.exports *)
          else if AliasSet.mem _object state.moduleExportsAliases then
            let right = Expression.get_id_opt right in 
            option_may (HashTable.replace state.moduleExportsAssigns property) right;
            state
          
          else state

        ) state _object

      (* dont do anything on other statements *)
      | _ -> state

  
  let init () : t = {
    _moduleExportsObject = "";
    moduleExportsAssigns = HashTable.create 10;
    moduleExportsAliases = AliasSet.empty;

    exportsAssigns = HashTable.create 10;
    exportsAliases = AliasSet.empty;

    exportsIsModuleExports = true;
  }

  let finish (state : t) : AnalysisType.t =
    AnalysisType.BuildExportsObject state

end