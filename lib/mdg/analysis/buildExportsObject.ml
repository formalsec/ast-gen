open Ast.Grammar
open Structures
open Auxiliary.Structures
open Auxiliary.Functions


module Analysis : AbstractAnalysis.T = struct
  type t = {
    (* module.exports *)
    _moduleExportsObject  : location;
    moduleExportsAssigns : string HashTable.t;
    moduleExportsAliases : AliasSet.t;

    (* export *)
    exportsAssigns : string HashTable.t;
    exportsAliases : AliasSet.t;

    exportsIsModuleExports : bool
  }

  let init () : t = {
    _moduleExportsObject = "";
    moduleExportsAssigns = HashTable.create 10;
    moduleExportsAliases = AliasSet.empty;

    exportsAssigns = HashTable.create 10;
    exportsAliases = AliasSet.empty;

    exportsIsModuleExports = true;
  }
  let analyse (analysis : t) (statement : m Statement.t) : t = 
    match statement with
      | _, AssignSimple {left; right} -> 
        let right = Expression.get_id_opt right in 
        if right = Some "exports" then
          let alias = Identifier.get_name left in
          let aliases = AliasSet.add alias analysis.exportsAliases in 
          {analysis with exportsAliases = aliases}
        else analysis

      | _, StaticLookup {left; _object; property; _} -> 
        let _object = Expression.get_id_opt _object in 
        if _object = Some "module" && property = "exports" then
          let alias = Identifier.get_name left in 
          let aliases = AliasSet.add alias analysis.moduleExportsAliases in 
          {analysis with moduleExportsAliases = aliases}
        else analysis

      | _, StaticUpdate {_object; property; right; _} -> 
        let _object = Expression.get_id_opt _object in 
        map_default (fun _object ->
          (* update of a property of exports *)
          if analysis.exportsIsModuleExports && (_object = "exports" || AliasSet.mem _object analysis.exportsAliases) then
            (* TODO : maybe instead of name we stor the location of the associated object *)
            let right = Expression.get_id_opt right in 
            option_may (HashTable.replace analysis.exportsAssigns property) right;
            analysis
          (* update of the module.exports value *)
          
          else if _object = "module" && property = "exports" then 
            (* TODO : maybe instead of name we stor the location of the associated object *)
            let right = Expression.get_id_opt right in 
            HashTable.clear analysis.moduleExportsAssigns;
            HashTable.clear analysis.exportsAssigns;
            { analysis with 
               _moduleExportsObject = Option.get(right);
               exportsIsModuleExports = false;
               moduleExportsAliases = AliasSet.empty;
               exportsAliases = AliasSet.empty;
            }
          
          (* update of a property of module.exports *)
          else if AliasSet.mem _object analysis.moduleExportsAliases then
            let right = Expression.get_id_opt right in 
            option_may (HashTable.replace analysis.moduleExportsAssigns property) right;
            analysis
          
          else analysis

        ) analysis _object

      (* dont do anything on other statements *)
      | _ -> analysis

end