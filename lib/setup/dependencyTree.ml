type t = {
  main : string;
  structure : Yojson.Basic.t;
}

let generate_dt (filename : string) : string = 
  "node resources/js/generate_cg.js " ^ filename

let single_file_dt (filename : string) : string = 
  "{ \"" ^ filename ^ "\" : {} }"

let generate (filename : string) (multifile : bool) : t =
  let filename = File_system.real_path filename in 
  let output = if multifile 
    then File_system.run_command (generate_dt filename) 
    else single_file_dt filename
  in
  { main      = filename;
    structure = Yojson.Basic.from_string output }
  
let get_main (dep_tree : t) : string = dep_tree.main

let bottom_up_visit (dep_tree : t) : string list =
  let rec visit (dep_tree : Yojson.Basic.t) (acc : string list) =
    match dep_tree with
    | `Assoc list -> List.fold_left (
                      fun acc (file, child_deps) -> visit child_deps acc @ [file]
                    ) acc list
    | _ -> failwith "error visiting dependency tree in bottom up approach"
  in
  visit dep_tree.structure []
  
