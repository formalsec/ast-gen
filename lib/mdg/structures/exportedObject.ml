open Auxiliary.Structures

type t = 
  | Object of t HashTable.t
  | Function of Structures.location

let empty () : t = Object (HashTable.create 0)

let create (dim : int) : t = Object (HashTable.create dim)

let add_property (exportedObject : t) (property : string) (value : t) : t = 
  match exportedObject with 
    | Object exportedObject -> 
      HashTable.replace exportedObject property value;
      Object exportedObject 
    
      | _ -> exportedObject

let print (exportedObject : t) : unit = 
  let identation_spacing = 3 in
  let rec print' (exportedObject : t) (identation : int) : unit =
    let identation_str = String.make identation ' ' in
    match exportedObject with
      | Object exportedObject -> 
        print_endline (identation_str ^ "{");
        HashTable.iter (fun prop value -> 
          print_string (identation_str ^ "\"" ^ prop ^ "\" : ");
          print' value (identation + identation_spacing);
        ) exportedObject;
        print_endline (identation_str ^ "}")


      | Function func -> print_endline func;
  in

  print' exportedObject 0