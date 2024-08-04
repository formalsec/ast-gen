open Structures

module T = Hashtbl.Make (LocationSet)


type t' = {
  _module : string;
  properties : property list
} 

type t = t' T.t


let get_opt (ext_refs : t) (location : location) : t' option = 
  let locs = LocationSet.singleton location in 
  T.find_opt ext_refs locs

let iter : (LocationSet.t -> t' -> unit) -> t -> unit = T.iter 
let print (refs : t) : unit =
  print_endline "=======" ;
  iter (fun loc value ->
    print_endline "key : ";
    LocationSet.print loc;
    print_endline "value : ";
    print_endline ("{ module : " ^ value._module ^ ", \n properties : " ^ String.concat "." value.properties ^ " }");
    print_endline "----------";
  ) refs;
  print_endline "=======" ;
