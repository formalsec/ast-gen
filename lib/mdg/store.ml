open Structures
open Normalizer.Structures
open Auxiliary.Structures
open Auxiliary.Functions


type t = {
  data : LocationSet.t HashTable.t;
  register : unit -> unit;
}

let empty (register : unit -> unit) : t = {data = HashTable.create 100; register = register}
let literal_loc = LocationSet.singleton (loc_obj_prefix ^ "literal") 
let this_loc = LocationSet.singleton "this"

(* =============== F U N C T I O N S =============== *)

(* ------- S T R U C T U R E   F U N C T I O N S ------- *)
let iter (f : location -> LocationSet.t -> unit) (store : t): unit  = HashTable.iter f store.data
let find_opt (store : t) : location -> LocationSet.t option = HashTable.find_opt store.data


let replace (store : t) (location : location) (locations : LocationSet.t) : unit = 
  let old_locs = find_opt store location in
  map_default (fun old_locs -> if not (LocationSet.subset locations old_locs) then store.register () ) (store.register ()) old_locs;
  HashTable.replace store.data location locations
let copy (store : t) : t = {store with data = HashTable.copy store.data}

let rec print (store : t) : unit =
  iter (print_locations) store;
  print_string "\n";

and print_locations (id : location) (locations : LocationSet.t) : unit = 
  print_endline (id ^ " : [" ^ String.concat ", " (LocationSet.elements locations) ^ "]")


(* ------- A U X I L I A R Y   F U N C T I O N S -------*)
let get_locations (store : t) (id : location) : LocationSet.t =
  map_default identity LocationSet.empty (find_opt store id)
  
(* ------- S T O R E   M A N I P U L A T I O N ------- *)
let get (store : t) ((_, {name; _}) : m Identifier.t) : LocationSet.t =
  get_locations store name

let update' (store : t) (id : string) (locs : LocationSet.t) : unit =
  replace store id locs

let update (store : t) ((_, {name; _}) : m Identifier.t) (locs : LocationSet.t) : unit  = 
  update' store name locs

let strong_update (store : t) (old : location) (_new : location) : unit =
  iter (fun id locations -> 
    let new_locations = LocationSet.map (fun loc -> if loc = old then _new else loc) locations in 
    replace store id new_locations
  ) store

let weak_update (store : t) (old : location) (_new : LocationSet.t) : unit =
  iter (fun id locations -> 
    let new_locations = LocationSet.fold (fun loc acc -> if loc = old 
                                            then LocationSet.union acc _new 
                                            else LocationSet.add loc acc
                                          ) locations LocationSet.empty in 
    replace store id new_locations
  ) store

let lub (store : t) (store' : t) : unit =
  (* least upper bound *)
  iter ( fun id locs' ->
    let locs = get_locations store id in 
    replace store id (LocationSet.union locs locs')
  ) store'