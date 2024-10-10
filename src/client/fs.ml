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
