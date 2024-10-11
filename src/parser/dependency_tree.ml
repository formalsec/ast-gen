open Graphjs_base
open Graphjs_config

type t =
  { main_path : string
  ; structure : Json.t
  }

let pp (ppf : Fmt.t) (dt : t) : unit = Yojson.Basic.pp ppf dt.structure
let str : t -> string = Fmt.str "%a" pp

exception Error of (Fmt.t -> unit)

open struct
  let get_result (ic : in_channel) : string =
    let res = Buffer.create Config.(!dflt_buf_sz) in
    let rec get_result' () =
      match input_line ic with
      | line ->
        Buffer.add_string res line;
        Buffer.add_char res '\n';
        get_result' ()
      | exception End_of_file -> Buffer.contents res in
    get_result' ()

  let dependency_tree_cmd (main_file : string) : string =
    let cmd = Fmt.str "dt %s" main_file in
    let ic = Unix.open_process_in cmd in
    let execute () = get_result ic in
    let finally () = ignore (Unix.close_process_in ic) in
    Fun.protect ~finally execute
end

open struct
  let raise (format : ('a, Fmt.t, unit, 'b) format4) : 'a =
    Fmt.kdly (fun raise_f -> raise (Error raise_f)) format

  let find_main_of_package (module_path : string) : (bool * string) option =
    let package_path = Filename.concat module_path "package.json" in
    if not (Sys.file_exists package_path) then None
    else
      let package = Json.from_file package_path in
      match Json.member "main" package with
      | `String main ->
        let main_path = Filename.concat module_path main in
        if not (Sys.file_exists main_path) then
          raise "Unable to find the main file %S described in package.json."
            main_path
        else if Sys.is_directory main_path then Some (false, main_path)
        else Some (true, main_path)
      | _ -> None

  let find_main_of_module (module_path : string) : string =
    (* https://docs.npmjs.com/cli/v10/configuring-npm/package-json#main *)
    match find_main_of_package module_path with
    | Some (true, main_path) -> main_path
    | Some (false, root_path) ->
      let index_path = Filename.concat root_path "index.js" in
      if Sys.file_exists index_path then index_path
      else raise "Unable to find index.js in directory %S." root_path
    | None -> raise "Unable to find main file of module '%s'." module_path

  let find_main_file (path : string) (mode : Mode.t) : string =
    match (Sys.is_directory path, mode) with
    | (false, _) -> path
    | (true, MultiFile) -> find_main_of_module path
    | (true, Basic) | (true, SingleFile) ->
      raise "Unable to perform Single-file analysis in directory %S." path

  let generate_structure (main_file : string) : Mode.t -> string = function
    | Basic | SingleFile -> Fmt.str "{%S:{}}" main_file
    | MultiFile -> dependency_tree_cmd main_file
end

let generate (path : string) (mode : Mode.t) : t =
  let main_path = find_main_file path mode in
  let structure = generate_structure main_path mode in
  { main_path; structure = Json.from_string structure }

(* let get_main (dep_tree : t) : string = dep_tree.main *)
(*  *)
(* let bottom_up_visit (dep_tree : t) : string list = *)
(* let rec visit (dep_tree : Yojson.Basic.t) (acc : string list) = *)
(* match dep_tree with *)
(* | `Assoc list -> *)
(* List.fold_left *)
(* (fun acc (file, child_deps) -> visit child_deps acc @ [ file ]) *)
(* acc list *)
(* | _ -> *)
(* failwith "[ERROR] Error visiting dependency tree in bottom up approach" *)
(* in *)
(*  *)
(* let visit_order = visit dep_tree.structure [] in *)
(* remove duplicated from visit *)
(* List.rev *)
(* (List.fold_left *)
(* (fun final_order curr -> *)
(* if List.mem curr final_order then final_order else curr :: final_order *)
(* ) *)
(* [] visit_order ) *)
