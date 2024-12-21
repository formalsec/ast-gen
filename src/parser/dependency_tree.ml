open Graphjs_base
open Graphjs_share

exception Exn of (Fmt.t -> unit)

open struct
  let raise (fmt : ('b, Fmt.t, unit, 'a) format4) : 'b =
    let raise_f acc = raise (Exn acc) in
    Fmt.kdly (fun acc -> raise_f (fun ppf -> Log.fmt_error ppf "%t" acc)) fmt
end

module rec M : sig
  type t =
    { path : Fpath.t
    ; mrel : Fpath.t
    ; deps : DepSet.t
    }

  val compare : t -> t -> int
end = struct
  type t =
    { path : Fpath.t
    ; mrel : Fpath.t
    ; deps : DepSet.t
    }

  let compare (dt1 : t) (dt2 : t) : int =
    let path_cmp = Fpath.compare dt1.path dt2.path in
    if path_cmp != 0 then path_cmp else DepSet.compare dt1.deps dt2.deps
end

and DepSet : (Set.S with type elt = M.t) = Set.Make (struct
  type elt = M.t

  let compare : elt -> elt -> int = M.compare
end)

include M

let rec create_deps (root : Fpath.t) : Json.t -> DepSet.t = function
  | `Assoc structure ->
    Fun.flip2 List.fold_left DepSet.empty structure (fun acc (abs, deps) ->
        let path = Fpath.v abs in
        let mrel = Option.get (Fpath.relativize ~root path) in
        DepSet.add { path; mrel; deps = create_deps root deps } acc )
  | structure -> Log.fail "unexpected dependency tree: %a" Json.pp structure

let create : Json.t -> t = function
  | `Assoc [ (abs, deps) ] ->
    let path = Fpath.v abs in
    let root = Fpath.parent path in
    let mrel = Option.get (Fpath.relativize ~root path) in
    { path; mrel; deps = create_deps root deps }
  | structure -> Log.fail "unexpected dependency tree: %a" Json.pp structure

let equal (dt1 : t) (dt2 : t) : bool = compare dt1 dt2 == 0 [@@inline]

let rec map (f : Fpath.t -> Fpath.t) (dt : t) : t =
  { dt with path = f dt.path; deps = DepSet.map (map f) dt.deps }

let rec pp_binds (ppf : Fmt.t) (dt : t) : unit =
  let pp_path ppf path = Fmt.fmt ppf "\"%a\"" Fpath.pp path in
  let pp_deps ppf deps = Fmt.(pp_iter DepSet.iter !>",@\n" pp_binds) ppf deps in
  let pp_indent ppf deps = Fmt.fmt ppf "@\n@[<v 2>  %a@]@\n" pp_deps deps in
  if DepSet.cardinal dt.deps == 0 then Fmt.fmt ppf "%a: {}" pp_path dt.path
  else Fmt.fmt ppf "%a: {%a}" pp_path dt.path pp_indent dt.deps

let pp (ppf : Fmt.t) (dt : t) : unit =
  Fmt.fmt ppf "{@\n@[<v 2>  %a@]@\n}" pp_binds dt

let str (dt : t) : string = Fmt.str "%a" pp dt

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

  let find_main_file (mode : Mode.t) (path : string) : string =
    match (Sys.is_directory path, mode) with
    | (false, _) -> Unix.realpath path
    | (true, MultiFile) -> find_main_of_module path
    | (true, (Basic | SingleFile)) ->
      raise "Unable to perform Single-file analysis in directory %S." path
    | exception Sys_error _ -> raise "Unable to find the provided path %S." path

  let generate_structure (mode : Mode.t) (main_file : string) : string =
    match mode with
    | Basic | SingleFile -> Fmt.str "{ %S : {} }" main_file
    | MultiFile -> Console.execute (Fmt.str "dt %s" main_file)
end

let generate_with_mode (mode : Mode.t) (path : string) : t =
  let main_path = find_main_file mode path in
  let structure = generate_structure mode main_path in
  create (Json.from_string structure)

let generate (path : Fpath.t) : t =
  let mode = Share_config.(!mode) in
  generate_with_mode mode (Fpath.to_string path)

let multi_file (dt : t) : bool = DepSet.cardinal dt.deps > 0

let bottom_up_visit (f : Fpath.t * Fpath.t -> 'a) (dt : t) : 'a list =
  let visited = Hashtbl.create Config.(!dflt_htbl_sz) in
  let rec bottom_up_visit' { path; mrel; deps } acc =
    if Hashtbl.mem visited path then acc
    else
      let _ = Hashtbl.add visited path () in
      let deps_acc = DepSet.fold bottom_up_visit' deps [] in
      acc @ deps_acc @ [ f (path, mrel) ] in
  bottom_up_visit' dt []
