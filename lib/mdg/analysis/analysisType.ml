open Setup
open Structures
open Auxiliary.Structures

type buildExportsObject = {
    (* module.exports *)
    moduleExportsObject  : LocationSet.t option;
    moduleExportsAssigns : LocationSet.t HashTable.t;
    moduleExportsAliases : AliasSet.t;

    (* export *)
    exportsAssigns : LocationSet.t HashTable.t;
    exportsAliases : AliasSet.t;

    exportsIsModuleExports : bool
}

type collectExternalCalls = ExternalReferences.t
type generateMDG = State.t
type sinkAliases = Config.t

type t =
  | BuildExportsObject   of buildExportsObject
  | CollectExternalCalls of collectExternalCalls 
  | GenerateMDG of generateMDG
  | SinkAliases of sinkAliases
  | Combined of t * t
  | None 