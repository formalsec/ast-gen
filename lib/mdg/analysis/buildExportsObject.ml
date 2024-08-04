open Ast.Grammar
open Structures
open Auxiliary.Structures
open Auxiliary.Functions
module Functions = Ast.Functions
module Graph = Graph'



module Analysis : AbstractAnalysis.T = struct
  type t = AnalysisType.buildExportsObject

  let analyse (exportsObjectInfo : t) (state : State.t) (statement : m Statement.t) : t = 
    match statement with
      | _, AssignSimple {left; right} -> 
        let right = Expression.get_id_opt right in 
        if right = Some "exports" then
          let alias = Identifier.get_name left in
          let aliases = AliasSet.add alias exportsObjectInfo.exportsAliases in 
          {exportsObjectInfo with exportsAliases = aliases}
        else exportsObjectInfo

      | _, StaticLookup {left; _object; property; _} -> 
        let _object = Expression.get_id_opt _object in 
        if _object = Some "module" && property = "exports" then
          let alias = Identifier.get_name left in 
          let aliases = AliasSet.add alias exportsObjectInfo.moduleExportsAliases in 
          {exportsObjectInfo with moduleExportsAliases = aliases}
        else exportsObjectInfo

      | _, StaticUpdate {_object; property; right; _} -> 
        let _object = Expression.get_id_opt _object in 
        map_default (fun _object ->
          (* update of a property of exports *)
          if exportsObjectInfo.exportsIsModuleExports && (_object = "exports" || AliasSet.mem _object exportsObjectInfo.exportsAliases) then
            let l_right = Store.eval_expr state.store state.this right in
            HashTable.replace exportsObjectInfo.exportsAssigns property l_right;
            exportsObjectInfo

          (* update of the module.exports value *)
          else if _object = "module" && property = "exports" then 
            let l_right = Store.eval_expr state.store state.this right in 

            HashTable.clear exportsObjectInfo.moduleExportsAssigns;
            HashTable.clear exportsObjectInfo.exportsAssigns;
            { exportsObjectInfo with 
               moduleExportsObject = Some l_right;
               exportsIsModuleExports = false;
               moduleExportsAliases = AliasSet.empty;
               exportsAliases = AliasSet.empty;
            }
          
          (* update of a property of module.exports *)
          else if AliasSet.mem _object exportsObjectInfo.moduleExportsAliases then
            let l_right = Store.eval_expr state.store state.this right in 
            HashTable.replace exportsObjectInfo.moduleExportsAssigns property l_right;
            exportsObjectInfo
          
          else exportsObjectInfo

        ) exportsObjectInfo _object

      (* dont do anything on other statements *)
      | _ -> exportsObjectInfo

  
  let init () : t = {
    moduleExportsObject = None;
    moduleExportsAssigns = HashTable.create 10;
    moduleExportsAliases = AliasSet.empty;

    exportsAssigns = HashTable.create 10;
    exportsAliases = AliasSet.empty;

    exportsIsModuleExports = true;
  }

  let finish (exportsObjectInfo : t) : AnalysisType.t =
    AnalysisType.BuildExportsObject exportsObjectInfo

end