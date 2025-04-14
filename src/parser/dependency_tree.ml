open Graphjs_base
open Graphjs_share

exception Exn of (Fmt.t -> unit)

let raise (fmt : ('b, Fmt.t, unit, 'a) format4) : 'b =
  let raise_f acc = raise (Exn acc) in
  Fmt.kdly (fun acc -> raise_f (fun ppf -> Log.fmt_error ppf "%t" acc)) fmt

let find_package_config (package_path : string) : (bool * string) option =
  let config_path = Filename.concat package_path "package.json" in
  if not (Sys.file_exists config_path) then None
  else
    let package_config = Json.from_file config_path in
    match Json.member "main" package_config with
    | `String main -> (
      let main_path = Filename.concat package_path main in
      try Some (Sys.is_directory main_path, main_path)
      with Sys_error _ ->
        raise "Unable to find %S described in %S." main_path config_path )
    | _ -> None

let find_package_main_file (package_path : string) : string =
  match find_package_config package_path with
  | Some (false, main_path) -> Unix.realpath main_path
  | Some (true, root_path) ->
    let index_path = Filename.concat root_path "index.js" in
    if Sys.file_exists index_path then Unix.realpath index_path
    else raise "Unable to find 'index.js' in directory %S." root_path
  | None -> raise "Unable to find main module of directory %S." package_path

let find_main_file (mode : Analysis_mode.t) (path : string) : string =
  match (Sys.is_directory path, mode) with
  | (false, _) -> Unix.realpath path
  | (true, MultiFile) -> find_package_main_file path
  | (true, (Basic | SingleFile)) ->
    raise "Unable to perform basic/singlefile analysis in directory %S." path
  | exception Sys_error _ -> raise "Unable to find the provided path %S." path

module rec M : sig
  type t =
    { path : Fpath.t
    ; mrel : Fpath.t
    ; deps : DepSet.t
    ; cyclic : bool
    }

  val compare : t -> t -> int
end = struct
  type t =
    { path : Fpath.t
    ; mrel : Fpath.t
    ; deps : DepSet.t
    ; cyclic : bool
    }

  let compare (dt1 : t) (dt2 : t) : int =
    let path_cmp = Fpath.compare dt1.mrel dt2.mrel in
    if path_cmp != 0 then path_cmp else DepSet.compare dt1.deps dt2.deps
end

and DepSet : (Set.S with type elt = M.t) = Set.Make (struct
  type elt = M.t

  let compare = M.compare
end)

include M

let rec create_deps (visited : Fpath.Set.t) (root : Fpath.t) (structure : Json.t)
    : DepSet.t =
  match structure with
  | `Assoc structure ->
    Fun.flip2 List.fold_left DepSet.empty structure (fun acc (abs, deps) ->
        let path = Fpath.v abs in
        let mrel = Option.get (Fpath.relativize ~root path) in
        let visited' = Fpath.Set.add mrel visited in
        let deps = create_deps visited' root deps in
        let cyclic = Fpath.Set.mem mrel visited in
        DepSet.add { path; mrel; deps; cyclic } acc )
  | structure -> Log.fail "unexpected dependency tree:@\n%a" Json.pp structure

let create (structure : Json.t) : t =
  match structure with
  | `Assoc [ (abs, deps) ] ->
    let path = Fpath.v abs in
    let (root, mrel) = Fpath.split_base path in
    let visited = Fpath.Set.singleton mrel in
    let deps = create_deps visited root deps in
    { path; mrel; deps; cyclic = false }
  | structure -> Log.fail "unexpected dependency tree:@\n%a" Json.pp structure

let generate_structure (mode : Analysis_mode.t) (main_file : string) : string =
  match mode with
  | Basic | SingleFile -> Fmt.str "{ %S : {} }" main_file
  | MultiFile -> Console.execute (Fmt.str "dt %s" main_file)

let generate (mode : Analysis_mode.t) (path : Fpath.t) : t =
  let path' = Fpath.to_string path in
  let main_path = find_main_file mode path' in
  let structure = generate_structure mode main_path in
  create (Json.from_string structure)

let equal (dt1 : t) (dt2 : t) : bool = compare dt1 dt2 == 0

let rec pp (abs : bool) (ppf : Fmt.t) (dt : t) : unit =
  let get_path dt = if abs then dt.path else dt.mrel in
  let pp_path ppf dt = Fmt.fmt ppf "\"%a\"" Fpath.pp (get_path dt) in
  let pp_deps ppf deps = Fmt.(pp_iter DepSet.iter !>",@\n" (pp abs)) ppf deps in
  let pp_indent ppf deps = Fmt.fmt ppf "@\n@[<v 2>  %a@]@\n" pp_deps deps in
  if DepSet.cardinal dt.deps == 0 then Fmt.fmt ppf "%a: {}" pp_path dt
  else Fmt.fmt ppf "%a: {%a}" pp_path dt pp_indent dt.deps

let pp (abs : bool) (ppf : Fmt.t) (dt : t) : unit =
  Fmt.fmt ppf "{@\n@[<v 2>  %a@]@\n}" (pp abs) dt

let str ?(abs : bool = false) (dt : t) : string = Fmt.str "%a" (pp abs) dt

let visit (f : Fpath.t * Fpath.t -> 'a -> 'a) (dt : t) (acc : 'a) : 'a =
  let visited = Hashtbl.create Config.(!dflt_htbl_sz) in
  let rec visit' { path; mrel; deps; _ } acc =
    if not (Hashtbl.mem visited mrel) then
      let _ = Hashtbl.add visited mrel () in
      let acc' = DepSet.fold visit' deps acc in
      f (path, mrel) acc'
    else acc in
  visit' dt acc

let visit_list (f : Fpath.t * Fpath.t -> 'a) (dt : t) : 'a list =
  let visited = Hashtbl.create Config.(!dflt_htbl_sz) in
  let rec visit' { path; mrel; deps; _ } acc =
    if not (Hashtbl.mem visited mrel) then
      let _ = Hashtbl.add visited mrel () in
      let deps_acc = DepSet.fold visit' deps [] in
      acc @ deps_acc @ [ f (path, mrel) ]
    else acc in
  visit' dt []
