open Graphjs_base
open Graphjs_shared

exception Exn of (Fmt.t -> unit)

open struct
  let raise (fmt : ('b, Fmt.t, unit, 'a) format4) : 'b =
    let raise_f acc = raise (Exn acc) in
    Fmt.kdly (fun acc -> raise_f (fun ppf -> Log.fmt_error ppf "%t" acc)) fmt
end

module rec M : sig
  type t =
    { absolute : Fpath.t
    ; relative : Fpath.t
    ; deps : DepSet.t
    }

  val compare : t -> t -> int
end = struct
  type t =
    { absolute : Fpath.t
    ; relative : Fpath.t
    ; deps : DepSet.t
    }

  let compare (dt1 : t) (dt2 : t) : int =
    let path_cmp = Fpath.compare dt1.absolute dt2.absolute in
    if path_cmp != 0 then path_cmp else DepSet.compare dt1.deps dt2.deps
end

and DepSet : (Set.S with type elt = M.t) = Set.Make (struct
  type t = M.t

  let compare (dt1 : t) (dt2 : t) : int = M.compare dt1 dt2
end)

include M

let rec create_deps (root : Fpath.t) : Json.t -> DepSet.t = function
  | `Assoc structure ->
    List.fold_left
      (fun acc (path, deps) ->
        let absolute = Fpath.v path in
        let relative = Option.get (Fpath.relativize ~root absolute) in
        DepSet.add { absolute; relative; deps = create_deps root deps } acc )
      DepSet.empty structure
  | structure -> Log.fail "unexpected dependency tree: %a" Json.pp structure

let create : Json.t -> t = function
  | `Assoc [ (path, deps) ] ->
    let path' = Fpath.v path in
    let root = if Fpath.is_dir_path path' then path' else Fpath.parent path' in
    let relative = Option.get (Fpath.relativize ~root path') in
    { absolute = path'; relative; deps = create_deps root deps }
  | structure -> Log.fail "unexpected dependency tree: %a" Json.pp structure

let pp_path (ppf : Fmt.t) (path : Fpath.t) : unit =
  Fmt.fmt ppf "\"%a\"" Fpath.pp path

let rec pp (ppf : Fmt.t) (dt : t) : unit =
  let pp_deps = Fmt.(pp_iter DepSet.iter !>",@\n" pp) in
  let pp_indent ppf = Fmt.fmt ppf "@\n@[<v 2>  %a@]@\n" pp_deps in
  if DepSet.cardinal dt.deps == 0 then Fmt.fmt ppf "%a: {}" pp_path dt.absolute
  else Fmt.fmt ppf "%a: {%a}" pp_path dt.absolute pp_indent dt.deps

let str : t -> string = Fmt.str "%a" pp
let equal (dt1 : t) (dt2 : t) : bool = compare dt1 dt2 == 0 [@@inline]

let rec map (f : Fpath.t -> Fpath.t) (dt : t) : t =
  { absolute = f dt.absolute
  ; relative = dt.relative
  ; deps = DepSet.map (map f) dt.deps
  }

open struct
  let get_result (ic : in_channel) : string =
    let rec get_result' res =
      match input_line ic with
      | line ->
        Buffer.add_string res line;
        Buffer.add_char res '\n';
        get_result' res
      | exception End_of_file -> Buffer.contents res in
    get_result' (Buffer.create Config.(!dflt_buf_sz))

  let dependency_tree_cmd (main_file : string) : string =
    let cmd = Fmt.str "dt %s" main_file in
    let ic = Unix.open_process_in cmd in
    let execute () = get_result ic in
    let finally () = ignore (Unix.close_process_in ic) in
    Fun.protect ~finally execute
end

open struct
  let find_main_of_package (module_path : string) : (bool * string) option =
    let package_path = Filename.concat module_path "package.json" in
    if not (Sys.file_exists package_path) then None
    else
      let package = Json.from_file package_path in
      match Json.member "main" package with
      | `String main -> (
        let main_path = Filename.concat module_path main in
        try Some (Sys.is_directory main_path, main_path)
        with Sys_error _ ->
          raise "Unable to find main module %S of 'package.json'." main_path )
      | _ -> None

  let find_main_of_module (module_path : string) : string =
    match find_main_of_package module_path with
    | Some (false, main_path) -> Unix.realpath main_path
    | Some (true, root_path) ->
      let index_path = Filename.concat root_path "index.js" in
      if Sys.file_exists index_path then Unix.realpath index_path
      else raise "Unable to find 'index.js' in directory %S." root_path
    | None -> raise "Unable to find main module of directory %S." module_path

  let find_main_file (path : string) (mode : Mode.t) : string =
    match (Sys.is_directory path, mode) with
    | (false, _) -> Unix.realpath path
    | (true, MultiFile) -> find_main_of_module path
    | (true, (Basic | SingleFile)) ->
      raise "Unable to perform Single-file analysis in directory %S." path
    | exception Sys_error _ -> raise "Unable to find the provided path %S." path

  let generate_structure (main_file : string) : Mode.t -> string = function
    | Basic | SingleFile -> Fmt.str "{ %S : {} }" main_file
    | MultiFile -> dependency_tree_cmd main_file
end

let generate_with_mode (mode : Mode.t) (path : string) : t =
  let main_path = find_main_file path mode in
  let structure = generate_structure main_path mode in
  create (Json.from_string structure)

let generate (path : string) : t =
  let mode = Shared_config.(!mode) in
  generate_with_mode mode path

let bottom_up_visit (f : Fpath.t * Fpath.t -> 'a) (dep_tree : t) : 'a list =
  let visited = Hashtbl.create Config.(!dflt_htbl_sz) in
  let rec bottom_up_visit' visited { absolute; relative; deps } acc =
    if Hashtbl.mem visited absolute then acc
    else
      let _ = Hashtbl.add visited absolute () in
      let deps_acc = DepSet.fold (bottom_up_visit' visited) deps [] in
      acc @ deps_acc @ [ f (absolute, relative) ] in
  bottom_up_visit' visited dep_tree []
