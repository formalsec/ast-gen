open Setup
open Structures
open Auxiliary.Structures

type buildExportsObject = {
    (* module.exports *)
    _moduleExportsObject  : location;
    moduleExportsAssigns : string HashTable.t;
    moduleExportsAliases : AliasSet.t;

    (* export *)
    exportsAssigns : string HashTable.t;
    exportsAliases : AliasSet.t;

    exportsIsModuleExports : bool
}

type generateMDG = State.t
type sinkAliases = Config.t

type t =
  | BuildExportsObject of buildExportsObject
  | GenerateMDG of generateMDG
  | SinkAliases of sinkAliases
  | Combined of t * t
  | None 