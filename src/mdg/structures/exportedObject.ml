open Graphjs_base
open Structs

type t = 
  | Object of t HashTable.t
  | Value of Structures.location

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


      | Value loc -> print_endline loc;
  in

  print' exportedObject 0

let rec get_value_location (exportedObject : t) (properties : Structures.property list) : Structures.location =
  match properties with
    | [] -> get_location exportedObject
    | property::properties' -> get_value_location (get_property exportedObject property) properties'

and get_location (exportedObject : t) : Structures.location = 
  match exportedObject with 
    | Value loc -> loc
    | Object obj -> 
      (* module.exports = {f} and f = require(...) *)
      if HashTable.length obj = 1 
        then get_location (List.nth (List.of_seq (HashTable.to_seq_values obj)) 0)
        else failwith "[ERROR] Unable to get function location from exported object"

and get_property (exportedObject : t) (property : Structures.property) : t =
  match exportedObject with
    | Object obj -> HashTable.find obj property
    | _ -> failwith ("[ERROR] Unable to get property " ^ property ^  " from exported object")

let rec get_all_values (exportedObject : t) : Structures.location list = 
  match exportedObject with 
    | Object obj ->
      let values = List.of_seq (HashTable.to_seq_values obj) in 
      List.flatten (List.map get_all_values values)
      
    | Value loc -> [loc]
    