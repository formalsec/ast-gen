open Structures
open Auxiliary.GraphJS
open Auxiliary.Functions


type t = LocationSet.t HashTable.t
let empty : t = HashTable.create 100
let literal_loc = LocationSet.singleton (loc_prefix ^ "literal") 
let this_loc = LocationSet.singleton "this"

(* =============== F U N C T I O N S =============== *)
let lub (store : t) (store' : t) : unit =
  (* least upper bound *)
  HashTable.iter ( fun id locs' ->
    let locs = map_default identity LocationSet.empty (HashTable.find_opt store id) in 
    HashTable.replace store id (LocationSet.union locs locs')
  ) store'

let copy (store : t) : t = HashTable.copy store


let rec print (store : t) : unit =
  HashTable.iter (fun id locs -> 
    print_endline (id ^ " : " ^ (locs_to_string locs));
  ) store;
  print_string "\n";

and locs_to_string (locs : LocationSet.t) : string =
  let elems = String.concat ", " (locset_to_list locs) in 
  "[" ^ elems ^ "]"
  

(* ------- S T O R E   M A N I P U L A T I O N ------- *)
let get (store : t) ((_, {name; _}) : m Identifier.t) : LocationSet.t =
  let locations = HashTable.find_opt store name in
  map_default identity LocationSet.empty locations

let update (store : t) ((_, {name; _}) : m Identifier.t) (locs : LocationSet.t) : unit  = 
  HashTable.replace store name locs

