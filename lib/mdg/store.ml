open Structures
open Auxiliary.GraphJS
open Auxiliary.Functions


type t = LocationSet.t HashTable.t
let empty : t = HashTable.create 100
let literal_loc = LocationSet.singleton (loc_prefix ^ "literal") 
let this_loc = LocationSet.singleton "this"

(* ----------- F U N C T I O N S -----------*)
let get (store : t) ((_, {name; _}) : m Identifier.t) : LocationSet.t =
  let locations = HashTable.find_opt store name in
  map_default identity LocationSet.empty locations

let update (store : t) ((_, {name; _}) : m Identifier.t) (locs : LocationSet.t) : unit  = 
  HashTable.replace store name locs

