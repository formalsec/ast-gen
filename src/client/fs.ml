open Graphjs_base
open Fpath

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

let handle_error (f : t -> 'a Exec.status) (w : t) : unit =
  match f w with
  | Ok _ -> ()
  | Error exn ->
    Log.warn "Unable to interact with \"%a\".@\n%a" pp w Exec.pp_exn exn

let mkdir (path : t) : unit Exec.status =
  let open Result in
  let path' = if is_dir_path path then path else parent path in
  let* _ = Exec.bos (Bos.OS.Dir.create path') in
  Ok ()

let copy (path : t) (src : t) : unit Exec.status =
  let open Result in
  let* data = Exec.bos (Bos.OS.File.read src) in
  Exec.bos (Bos.OS.File.write path data)

let output (path : t) (output_f : t -> unit Exec.status) : unit Exec.status =
  output_f path

let write (path : t) (fmt : Fmt.t -> unit) : unit Exec.status =
  output path @@ fun path -> Exec.bos (Bos.OS.File.writef path "%t" fmt)

let mkdir_noerr (path : t) : unit = handle_error mkdir path

let copy_noerr (path : t) (src : t) : unit =
  handle_error (Fun.flip copy src) path

let output_noerr (path : t) (output_f : t -> unit Exec.status) : unit =
  handle_error (Fun.flip output output_f) path

let write_noerr (path : t) (fmt : Fmt.t -> unit) : unit =
  handle_error (Fun.flip write fmt) path
