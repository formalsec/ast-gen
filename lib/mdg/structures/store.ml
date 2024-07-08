open Structures
open Ast.Grammar
open Auxiliary.Structures

type t = LocationSet.t HashTable.t


let empty () : t = HashTable.create 100
let loc_literal = LocationSet.singleton Structures.loc_literal 
let loc_this = LocationSet.singleton Structures.loc_literal

(* =============== F U N C T I O N S =============== *)

(* ------- S T R U C T U R E   F U N C T I O N S ------- *)
let iter : (location -> LocationSet.t -> unit) -> t -> unit  = HashTable.iter
let find_opt : t -> location -> LocationSet.t option = HashTable.find_opt

let replace : t -> location -> LocationSet.t -> unit = HashTable.replace 
let copy : t -> t = HashTable.copy

let rec print (store : t) : unit =
  iter (print_locations) store;
  print_string "\n";

and print_locations (id : location) (locations : LocationSet.t) : unit = 
  print_endline (id ^ " : [" ^ String.concat ", " (LocationSet.elements locations) ^ "]")

let equal (store : t) (store' : t) : bool = HashTable.equals (LocationSet.equal) store store'

(* ------- A U X I L I A R Y   F U N C T I O N S -------*)
let get_locations (store : t) (id : location) : LocationSet.t =
  Option.value (find_opt store id) ~default:LocationSet.empty
  
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