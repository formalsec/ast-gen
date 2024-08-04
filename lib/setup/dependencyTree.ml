module Mode = Auxiliary.Mode

type t = {
  main : string;
  structure : Yojson.Basic.t;
}

let generate_dt (script : string ) (filename : string) : string = 
  "node " ^ script ^ " " ^ filename

let single_file_dt (filename : string) : string = 
  "{ \"" ^ filename ^ "\" : {} }"

let generate (script : string) (filename : string) (mode : string) : t =
  let filename = File_system.real_path filename in 
  let output = if Mode.is_multi_file mode 
    then File_system.run_command (generate_dt script filename) 
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

  let visit_order = visit dep_tree.structure []  in
  (* remove duplicated from visit *)
  List.rev (List.fold_left (fun final_order curr -> if List.mem curr final_order then final_order else curr :: final_order)  [] visit_order)


  
