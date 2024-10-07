open Graphjs_base
type t = { main : string; structure : Yojson.Basic.t }

(* let generate_dt (filename : string) : Bos.Cmd.t = Bos.Cmd.(v "dt" % filename) *)
let single_file_dt filename = Format.sprintf "{ %S : {} }" filename

let find_module_main (module_path : string) : string =
  (* https://docs.npmjs.com/cli/v10/configuring-npm/package-json#main *)
  let main_file : string option ref = ref None in
  let module_path = ref module_path in

  (* check package.json *)
  let package_path = Filename.concat !module_path "package.json" in
  (if Sys.file_exists package_path then
     let package_info = Yojson.Basic.from_file package_path in
     match Yojson.Basic.Util.member "main" package_info with
     | `String main ->
         let main_path = Filename.concat !module_path main in
         if not (Sys.file_exists main_path) then
           failwith "[ERROR] Main file described in package.json doesn't exist"
         else if Sys.is_directory main_path then module_path := main_path
         else main_file := Some main_path
     | _ -> ());

  (* check if index.js exists in the root folder *)
  let index_path = Filename.concat !module_path "index.js" in
  if Sys.file_exists index_path && Option.is_none !main_file then
    main_file := Some index_path;

  if Option.is_some !main_file then Option.get !main_file
  else failwith ("[ERROR] Unable to find main file of module : " ^ !module_path)

let get_main_file (filename : string) (mode : Mode.t) : string =
  let filename = File_system.real_path filename in
  match mode with
  (* in single file analysis, the filename should already be the main file*)
  | mode when Mode.is_basic mode || Mode.is_single_file mode ->
      if not (Sys.is_directory filename) then filename
      else failwith "[ERROR] A folder was provided for single file analysis"
  (* in multifile analysis, the filename can be the main file or a module
     directory if it is a directory we need to find the main file of the module *)
  | mode when Mode.is_multi_file mode ->
      if not (Sys.is_directory filename) then filename
      else find_module_main filename
  | _ ->
      Format.kasprintf failwith "[ERROR] No implementation for mode %a" Mode.pp
        mode

let generate (filename : string) (mode : Mode.t) =
  let open Result in
  let main_file = get_main_file filename mode in
  let* output =
    match mode with
    | Multi_file -> Error "abc"(*File_system.run_command' (generate_dt main_file)*)
    | _ -> Ok (single_file_dt main_file)
  in
  Ok { main = main_file; structure = Yojson.Basic.from_string output }

let get_main (dep_tree : t) : string = dep_tree.main

let bottom_up_visit (dep_tree : t) : string list =
  let rec visit (dep_tree : Yojson.Basic.t) (acc : string list) =
    match dep_tree with
    | `Assoc list ->
        List.fold_left
          (fun acc (file, child_deps) -> visit child_deps acc @ [ file ])
          acc list
    | _ ->
        failwith "[ERROR] Error visiting dependency tree in bottom up approach"
  in

  let visit_order = visit dep_tree.structure [] in
  (* remove duplicated from visit *)
  List.rev
    (List.fold_left
       (fun final_order curr ->
         if List.mem curr final_order then final_order else curr :: final_order)
       [] visit_order)
