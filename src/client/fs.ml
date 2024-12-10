open Graphjs_base
open Fpath

module Config = struct
  include Config

  let override : bool t = static false
end

module Parser = struct
  type conv =
    [ `Ok of t
    | `Error of string
    ]

  open struct
    let check (check_f : Fpath.t -> bool) (kind : string) (fpath : t) : conv =
      if check_f fpath then `Ok fpath
      else `Error (Fmt.str "Path '%a' is not a valid %s!" pp fpath kind)

    let parse (parse_f : t -> (bool, [< `Msg of string ]) Result.t)
        (kind : string) (fpath : t) : conv =
      match parse_f fpath with
      | Ok true -> `Ok fpath
      | Ok false -> `Error (Fmt.str "%s '%a' not found!" kind pp fpath)
      | Error (`Msg err) -> `Error err

    let fix_dir (fpath : t) : t =
      if Fpath.exists_ext fpath then fpath else Fpath.to_dir_path fpath
  end

  let fpath = Fun.((fun fpath -> `Ok fpath) << fix_dir << v, pp)
  let dir = Fun.(check is_dir_path "directory" << fix_dir << v, pp)
  let file = Fun.(check is_file_path "filename" << v, pp)
  let valid_fpath = Fun.(parse Bos.OS.Path.exists "Path" << fix_dir << v, pp)
  let valid_dir = Fun.(parse Bos.OS.Dir.exists "Directory" << fix_dir << v, pp)
  let valid_file = Fun.(parse Bos.OS.File.exists "File" << v, pp)
end

module OptPath = struct
  type path_type =
    | Main
    | File
    | Dir

  let create (path_type : path_type) (root : t option) : t option =
    match (root, path_type) with
    | (Some root', Main) -> Some root'
    | (Some root', File) when is_file_path root' -> Some root'
    | (Some root', Dir) when is_dir_path root' -> Some root'
    | _ -> None

  let ( // ) (root : t option) (relative : t) : t option =
    Option.map (fun root' -> root' // relative) root

  let ( / ) (root : t option) (relative : string) : t option =
    Option.map (fun root' -> root' / relative) root

  let ( + ) (root : t option) (ext : string) : t option =
    Option.map (fun root' -> root' + ext) root

  let ( -+ ) (root : t option) (ext : string) : t option =
    Option.map (fun root' -> root' -+ ext) root
end

open struct
  let handle_err (f : t option -> 'a Exec.status) (path : t option) : unit =
    match f path with
    | Ok _ -> ()
    | Error exn ->
      Log.warn "Unable to output to file \"%a\".@\n%a" (Fmt.pp_opt pp) path
        Exec.pp_exn exn

  let prepare' (path : t) : unit Exec.status =
    let open Result in
    let create_dir_template manifest_path =
      let* _ = Exec.bos (Bos.OS.Dir.create path) in
      Exec.bos (Bos.OS.File.write manifest_path "") in
    let override_dir manifest_path warn =
      if warn then Log.warn "Overriding \"%a\" directory." pp path;
      let* _ = Exec.bos (Bos.OS.Dir.delete ~recurse:true path) in
      create_dir_template manifest_path in
    let override_file () =
      Log.warn "Overriding \"%a\" file." pp path;
      Exec.bos (Bos.OS.File.delete path) in
    let error_dir () =
      Exec.generic_exn "Unable to override \"%a\" directory." pp path in
    let error_file () =
      Exec.generic_exn "Unable to override \"%a\" file." pp path in
    let manifest_path = path / ".graphjs" in
    let* exists_path = Exec.bos (Bos.OS.Path.exists path) in
    match (exists_path, is_dir_path path) with
    | (false, false) -> Ok ()
    | (false, true) -> create_dir_template manifest_path
    | (true, false) ->
      if Config.(!override) then override_file () else error_file ()
    | (true, true) ->
      let* exists_graphjs = Exec.bos (Bos.OS.File.exists manifest_path) in
      if exists_graphjs then override_dir manifest_path false
      else if Config.(!override) then override_dir manifest_path true
      else error_dir ()

  let output' (output_f : t -> unit Exec.status) (path : t) : unit Exec.status =
    let open Result in
    let* _ = Exec.bos (Bos.OS.Dir.create (parent path)) in
    output_f path

  let copy' (src_path : t) (path : t) : unit Exec.status =
    let open Result in
    let* data = Exec.bos (Bos.OS.File.read src_path) in
    Exec.bos (Bos.OS.File.write path data)

  let write' (fmt : Fmt.t -> unit) (path : t) : unit Exec.status =
    Exec.bos (Bos.OS.File.writef path "%t" fmt)
end

let prepare (path : t option) : unit Exec.status =
  Option.fold ~none:(Ok ()) ~some:prepare' path

let prepare_noerr (path : t option) : unit = handle_err prepare path

let output (path : t option) (output_f : t -> unit Exec.status) :
    unit Exec.status =
  Option.fold ~none:(Ok ()) ~some:(output' output_f) path

let output_noerr (path : t option) (output_f : t -> unit Exec.status) : unit =
  handle_err (Fun.flip output output_f) path

let copy (path : t option) (src_path : t) : unit Exec.status =
  output path (copy' src_path)

let copy_noerr (path : t option) (src_path : t) : unit =
  handle_err (Fun.flip output (copy' src_path)) path

let write (path : t option) (fmt : Fmt.t -> unit) : unit Exec.status =
  output path (write' fmt)

let write_noerr (path : t option) (fmt : Fmt.t -> unit) : unit =
  handle_err (Fun.flip output (write' fmt)) path
