open Graphjs_base
open Fpath

module Parser = struct
  type conv =
    [ `Ok of t
    | `Error of string
    ]

  let valid (valid_f : t -> bool) (kind : string) (fpath : t) : conv =
    if valid_f fpath then `Ok fpath
    else `Error (Fmt.str "Path '%a' is not a valid %s." pp fpath kind)

  let valid_file (fpath : t) : (bool, [< `Msg of string ]) Result.t =
    if Fpath.is_file_path fpath then Bos.OS.File.exists fpath
    else Error (`Msg (Fmt.str "Path '%a' is not a valid file." pp fpath))

  let valid_dir (fpath : t) : (bool, [< `Msg of string ]) Result.t =
    if Fpath.is_dir_path fpath then Bos.OS.Dir.exists fpath
    else Error (`Msg (Fmt.str "Path '%a' is not a valid directory." pp fpath))

  let valid_path (fpath : t) : (bool, [< `Msg of string ]) Result.t =
    Bos.OS.Path.exists fpath

  let parse (parse_f : t -> (bool, [< `Msg of string ]) Result.t)
      (kind : string) (fpath : t) : conv =
    match parse_f fpath with
    | Ok true -> `Ok fpath
    | Ok false -> `Error (Fmt.str "%s '%a' not found." kind pp fpath)
    | Error (`Msg err) -> `Error err

  let fix_dir (fpath : t) : t =
    if Fpath.exists_ext fpath then fpath else Fpath.to_dir_path fpath

  let file = Fun.(valid is_file_path "filename" << v, pp)
  let dir = Fun.(valid is_dir_path "directory" << fix_dir << v, pp)
  let fpath = Fun.(valid (fun _ -> true) "path" << fix_dir << v, pp)
  let valid_file = Fun.(parse valid_file "File" << v, pp)
  let valid_dir = Fun.(parse valid_dir "Directory" << fix_dir << v, pp)
  let valid_fpath = Fun.(parse valid_path "Path" << fix_dir << v, pp)
end

let handle_error ~(default : 'a) (f : t -> 'a Exec.result) (path : t) : 'a =
  match f path with
  | Ok v -> v
  | Error err ->
    Log.warn "Unable to output to \"%a\".@\n%a" pp path Exec.pp_err err;
    default

let exists (path : t) : bool Exec.result =
  if is_dir_path path then Exec.bos (Bos.OS.Dir.exists path)
  else Exec.bos (Bos.OS.File.exists path)

let mkdir (path : t) : unit Exec.result =
  let path' = if is_dir_path path then path else parent path in
  Result.map (fun _ -> ()) (Exec.bos (Bos.OS.Dir.create path'))

let delete ?(recurse : bool = false) (path : t) : unit Exec.result =
  if is_dir_path path then
    Result.map (fun _ -> ()) (Exec.bos (Bos.OS.Dir.delete ~recurse path))
  else Result.map (fun _ -> ()) (Exec.bos (Bos.OS.File.delete path))

let copy (path : t) (src : t) : unit Exec.result =
  let open Result in
  let* data = Exec.bos (Bos.OS.File.read src) in
  Exec.bos (Bos.OS.File.write path data)

let output (path : t) (pp_v : Fmt.t -> 'a -> unit) (v : 'a) : unit Exec.result =
  Exec.bos (Bos.OS.File.writef path "%a" pp_v v)

let write (path : t) (fmt : ('b, Fmt.t, unit, 'a) format4) : 'b =
  let write_f acc = Exec.bos (Bos.OS.File.writef path "%t" acc) in
  Fmt.kdly (fun acc -> write_f acc) fmt

let exists_noerr (path : t) : bool = handle_error ~default:false exists path
let mkdir_noerr (path : t) : unit = handle_error ~default:() mkdir path

let delete_noerr ?(recurse : bool = false) (path : t) : unit =
  handle_error ~default:() (delete ~recurse) path

let copy_noerr (path : t) (src : t) : unit =
  handle_error ~default:() (Fun.flip copy src) path

let output_noerr (path : t) (pp_v : Fmt.t -> 'a -> unit) (v : 'a) : unit =
  handle_error ~default:() (Fun.flip2 output pp_v v) path

let write_noerr (path : t) (fmt : ('b, Fmt.t, unit, 'a) format4) : 'b =
  let write_f acc path = write path "%t" acc in
  Fmt.kdly (fun acc -> handle_error ~default:() (write_f acc) path) fmt
