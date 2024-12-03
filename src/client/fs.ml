open Graphjs_base
open Fpath

module Parser = struct
  type conv =
    [ `Ok of t
    | `Error of string
    ]

  let check (check_f : Fpath.t -> bool) (kind : string) (fpath : t) : conv =
    if check_f fpath then `Ok fpath
    else `Error (Fmt.str "Path '%a' is not a valid %s!" pp fpath kind)

  let parse (parse_f : t -> (bool, [< `Msg of string ]) Result.t)
      (kind : string) (fpath : t) : conv =
    match parse_f fpath with
    | Ok true -> `Ok fpath
    | Ok false -> `Error (Format.asprintf "%s '%a' not found!" kind pp fpath)
    | Error (`Msg err) -> `Error err

  let fix_dir : conv -> conv = function
    | `Ok fpath' -> (
      match Bos.OS.Dir.exists fpath' with
      | Ok true -> `Ok (to_dir_path fpath')
      | Ok false -> `Ok fpath'
      | Error (`Msg err) -> `Error err )
    | `Error _ as err -> err

  let fpath = ((fun str -> `Ok (v str)), pp)
  let file = Fun.(check is_file_path "filename" << v, pp)
  let dir = Fun.(check is_dir_path "directory" << v, pp)
  let valid_fpath = Fun.(fix_dir << parse Bos.OS.Path.exists "Path" << v, pp)
  let valid_file = Fun.(parse Bos.OS.File.exists "File" << v, pp)
  let valid_dir = Fun.(parse Bos.OS.Dir.exists "Directory" << v, pp)
end

let prepare' (path : t) : unit Exec.status =
  let open Result in
  (* TODO: add a flag/mechanism to prevent overriding directories by default *)
  let* exists = Exec.bos (Bos.OS.Path.exists path) in
  if exists then Log.warn "Overriding \"%a\" path." pp path;
  Exec.bos (Bos.OS.Path.delete ~recurse:true path)

let prepare (path : t option) : unit Exec.status =
  match path with None -> Ok () | Some path' -> prepare' path'

let write (path : t) (fmt : Fmt.t -> unit) : unit =
  let write_f () =
    let open Result in
    let* _ = Exec.bos (Bos.OS.Dir.create (parent path)) in
    Exec.bos (Bos.OS.File.writef path "%t" fmt) in
  match write_f () with
  | Ok () -> ()
  | Error exn ->
    Log.warn "Unable to write to file \"%a\".@\n%a" pp path Exec.pp_exn exn

let output' ?(main : bool = false) (root : t) (relative : t)
    (fmt : Fmt.t -> unit) : unit =
  if is_dir_path root then write (root // relative) fmt
  else if main then write root fmt

let output ?(main : bool = false) (root : t option) (relative : t)
    (fmt : Fmt.t -> unit) : unit =
  Option.iter (fun root' -> output' ~main root' relative fmt) root
