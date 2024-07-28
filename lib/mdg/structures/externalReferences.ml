open Structures

module T = Hashtbl.Make (LocationSet)


type t' = {
  _module : string;
  properties : property list
} 

type t = t' T.t

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
