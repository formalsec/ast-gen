open Structures
open Normalizer.Structures
open Auxiliary.Structures
open Auxiliary.Functions


type t = LocationSet.t HashTable.t

let empty : t = HashTable.create 100
let literal_loc = LocationSet.singleton (loc_prefix ^ "literal") 
let this_loc = LocationSet.singleton "this"

(* =============== F U N C T I O N S =============== *)

(* ------- S T R U C T U R E   F U N C T I O N S ------- *)
let iter : (string -> LocationSet.t -> unit) -> t -> unit  = HashTable.iter
let replace : t -> string -> LocationSet.t -> unit = HashTable.replace
let copy : t -> t = HashTable.copy

let rec print (store : t) : unit =
  iter (fun id locs -> 
    print_endline (id ^ " : " ^ (locs_to_string locs));
  ) store;
  print_string "\n";

and locs_to_string (locs : LocationSet.t) : string =
  let elems = String.concat ", " (LocationSet.elements locs) in 
  "[" ^ elems ^ "]"

let get_locations (store : t) (id : location) : LocationSet.t =
  map_default identity LocationSet.empty (HashTable.find_opt store id)

  
(* ------- S T O R E   M A N I P U L A T I O N ------- *)
let get (store : t) ((_, {name; _}) : m Identifier.t) : LocationSet.t =
  get_locations store name

let update' (register : unit -> unit) (store : t) (id : string) (locs : LocationSet.t) : unit =
  let old_value = get_locations store id in 
  if not (LocationSet.equal locs old_value) then register ();
  replace store id locs

let update (register : unit -> unit) (store : t) ((_, {name; _}) : m Identifier.t) (locs : LocationSet.t) : unit  = 
  update' register store name locs

let strong_update (register : unit -> unit) (store : t) (old : location) (_new : location) : unit =
  iter (fun id locations -> 
    if (LocationSet.mem old locations) then register();
    let new_locations = LocationSet.map (fun loc -> if loc = old then _new else loc) locations in 
    replace store id new_locations
  ) store

let weak_update (register : unit -> unit) (store : t) (old : location) (_new : LocationSet.t) : unit =
  iter (fun id locations -> 
    if not (LocationSet.subset _new locations) && (LocationSet.mem old locations) then register();
    let new_locations = LocationSet.fold (fun loc acc -> if loc = old 
                                            then LocationSet.union acc _new 
                                            else LocationSet.add loc acc
                                          ) locations LocationSet.empty in 
    replace store id new_locations
  ) store

let lub (register : unit -> unit) (store : t) (store' : t) : unit =
  (* least upper bound *)
  iter ( fun id locs' ->
    let locs = get_locations store id in 
    if not (LocationSet.subset locs' locs) then register ();
    replace store id (LocationSet.union locs locs')
  ) store'