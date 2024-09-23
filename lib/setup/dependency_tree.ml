type t =
  { main_file : string
  ; structure : Yojson.Basic.t
  }

let find_main_module (module_path : string) : string =
  (* https://docs.npmjs.com/cli/v10/configuring-npm/package-json#main *)
  let main_file : string option ref = ref None in
  let module_path = ref module_path in
  let package_path = File_system.concat !module_path "package.json" in
  ( if Sys.file_exists package_path then
      let package = Yojson.Basic.from_file package_path in
      match Yojson.Basic.Util.member "main" package with
      | `String main ->
        let main_path = File_system.concat !module_path main in
        if not (Sys.file_exists main_path) then
          failwith "[ERROR] Main file described in package.json doesn't exist"
        else if Sys.is_directory main_path then module_path := main_path
        else main_file := Some main_path
      | _ -> () );
  match Option.get !main_file with
  | main_file' -> main_file'
  | exception Invalid_argument _ ->
    let index_path = File_system.concat !module_path "index.js" in
    if Sys.file_exists index_path then index_path
    else failwith ("[ERROR] Cannot find main file of module: " ^ !module_path)

let find_main_file (mode : Mode.t) (filename : string) : string =
  let filename' = File_system.realpath filename in
  match mode with
  | Basic | SingleFile ->
    (* in single file analysis, the filename should already be the main file*)
    if not (Sys.is_directory filename') then filename'
    else failwith "[ERROR] A folder was provided for single file analysis"
  | MultiFile ->
    (* in multifile analysis, the filename can be the main file or a module directory *)
    if not (Sys.is_directory filename') then filename'
    else find_main_module filename'

let generate (mode : Mode.t) (filename : string) =
  let open Result in
  let generate_dt_cmd filename = Bos.Cmd.(v "dt" % filename) in
  let single_file_dt filename = Format.sprintf "{ %S : {} }" filename in
  let main_file = find_main_file mode filename in
  let* output =
    match mode with
    | MultiFile -> File_system.run_command' (generate_dt_cmd main_file)
    | _ -> Ok (single_file_dt main_file) in
  Ok { main_file; structure = Yojson.Basic.from_string output }

(* ==================== To check ==================== *)

let bottom_up_visit (dt : t) : string list =
  let rec visit (dt' : Yojson.Basic.t) (acc : string list) =
    match dt' with
    | `Assoc list ->
      List.fold_left
        (fun acc (file, child_deps) -> visit child_deps acc @ [ file ])
        acc list
    | _ ->
      failwith "[ERROR] Error visiting dependency tree in bottom up approach"
  in

  let visit_order = visit dt.structure [] in
  List.rev
    (List.fold_left
       (fun final_order curr ->
         if List.mem curr final_order then final_order else curr :: final_order
         )
       [] visit_order )
