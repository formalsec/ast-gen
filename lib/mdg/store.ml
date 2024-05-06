open Structures
open Auxiliary.GraphJS
open Auxiliary.Functions


type t = LocationSet.t HashTable.t
let empty : t = HashTable.create 100
let literal_loc = LocationSet.singleton (loc_prefix ^ "literal") 
let this_loc = LocationSet.singleton "this"

(* =============== F U N C T I O N S =============== *)

let get_locations (store : t) (id : location) : LocationSet.t =
  map_default identity LocationSet.empty (HashTable.find_opt store id)

(* ------- M A I N   F U N C T I O N S -------*)
let lub (store : t) (store' : t) : unit =
  (* least upper bound *)
  HashTable.iter ( fun id locs' ->
    let locs = get_locations store id in 
    HashTable.replace store id (LocationSet.union locs locs')
  ) store'

let copy (store : t) : t = HashTable.copy store

let is_equal (store : t) (store' : t) : bool = 
  let result = ref true in
  if HashTable.length store = HashTable.length store'
    then (
        HashTable.iter ( fun key value -> 
        if !result then
          let value' = HashTable.find_opt store' key in 
          if Option.is_some value'
            then result := LocationSet.equal value (Option.get value')
            else result := false
        ) store;
        !result
      )
    else false

let rec print (store : t) : unit =
  HashTable.iter (fun id locs -> 
    print_endline (id ^ " : " ^ (locs_to_string locs));
  ) store;
  print_string "\n";

and locs_to_string (locs : LocationSet.t) : string =
  let elems = String.concat ", " (LocationSet.elements locs) in 
  "[" ^ elems ^ "]"
  

(* ------- S T O R E   M A N I P U L A T I O N ------- *)
let get (store : t) ((_, {name; _}) : m Identifier.t) : LocationSet.t =
  get_locations store name


let update' (store : t) (id : string) (locs : LocationSet.t) : unit =
  HashTable.replace store id locs

let update (store : t) ((_, {name; _}) : m Identifier.t) (locs : LocationSet.t) : unit  = 
  update' store name locs

let strong_update (store : t) (old : location) (_new : location) : unit =
  HashTable.iter (fun id locations -> 
    let new_locations = LocationSet.map (fun loc -> if loc = old then _new else loc) locations in 
    HashTable.replace store id new_locations
  ) store

let weak_update (store : t) (old : location) (_new : LocationSet.t) : unit =
  HashTable.iter (fun id locations -> 
    let new_locations = LocationSet.fold (fun loc acc -> if loc = old 
                                            then LocationSet.union acc _new 
                                            else LocationSet.add loc acc
                                          ) locations LocationSet.empty in 
    HashTable.replace store id new_locations
  ) store

