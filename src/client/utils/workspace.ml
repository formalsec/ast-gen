open Graphjs_base

module Config = struct
  include Config

  let dflt_output_path = constant (Fpath.v ".out/")
  let dflt_manifest_path = constant (Fpath.v "manifest.graphjs")
  let override = static false
end

type path =
  | None
  | Single of Fpath.t
  | Bundle of Fpath.t

type perm =
  | None
  | Main
  | Side

type t =
  { path : path
  ; perm : perm
  ; ext : string option
  }

let none = { path = None; perm = Main; ext = None }
let single ?(w = none) (path : Fpath.t) : t = { w with path = Single path }
let bundle ?(w = none) (path : Fpath.t) : t = { w with path = Bundle path }

let single_ext ?(w = none) (ext : string) (path : Fpath.t) : t =
  { w with path = Single path; ext = Some ext }

let main_perm (w : t) : t = { w with perm = Main }
let side_perm (w : t) : t = { w with perm = Side }

let create ~(default : [ `None | `Single of string option | `Bundle ])
    (inputs : Fpath.t list) (output : Fpath.t option) : t =
  match (output, default) with
  | (None, _) when List.length inputs == 1 -> none
  | (None, `None) -> none
  | (None, `Single None) -> single Config.(!dflt_output_path)
  | (None, `Single (Some ext)) -> single_ext ext Config.(!dflt_output_path)
  | (None, `Bundle) -> bundle Config.(!dflt_output_path)
  | (Some path, _) when Fpath.is_dir_path path -> bundle path
  | (Some path, _) when List.length inputs == 1 -> single path
  | (Some path, `None) -> single path
  | (Some path, `Single None) -> single path
  | (Some path, `Single (Some ext)) -> single_ext ext path
  | (Some path, `Bundle) -> bundle path

let path (w : t) : Fpath.t =
  match w with
  | { path = None; _ } -> Log.fail "unexpected 'none' workspace"
  | { path = Single path; _ } | { path = Bundle path; _ } -> path

let pp_path (ppf : Fmt.t) (w : t) : unit =
  match w with
  | { path = None; _ } -> ()
  | { path = Single path; _ } | { path = Bundle path; _ } -> Fpath.pp ppf path

let map (f : Fpath.t -> Fpath.t) (w : t) : t =
  match w with
  | { path = None; _ } as w -> w
  | { path = Single path'; _ } as w -> { w with path = Single (f path') }
  | { path = Bundle path'; _ } as w -> { w with path = Bundle (f path') }

let ( / ) (w : t) (rel : string) : t = map Fpath.(fun path -> path / rel) w
let ( // ) (w : t) (rel : Fpath.t) : t = map Fpath.(fun path -> path // rel) w
let ( + ) (w : t) (ext : string) : t = map Fpath.(fun path -> path + ext) w
let ( -+ ) (w : t) (ext : string) : t = map Fpath.(fun path -> path -+ ext) w

let execute (p : perm) (w : t) (f : Fpath.t -> 'a Exec.result) :
    unit Exec.result =
  match (p, w.path) with
  | (Main, Single path) | (Main, Bundle path) | (Side, Bundle path) ->
    Result.map ignore (f path)
  | _ -> Ok ()

let execute_noerr (p : perm) (w : t) (f : Fpath.t -> 'a) : unit =
  match (p, w.path) with
  | (Main, Single path) | (Main, Bundle path) | (Side, Bundle path) ->
    ignore (f path)
  | _ -> ()

let log (w : t) (fmt : ('a, Fmt.t, unit, unit) format4) : 'a =
  match w.perm with
  | Main when not Log.Config.(!log_verbose) -> Log.stdout fmt
  | _ -> Log.ignore fmt

let print (w : t) (fmt : ('a, Fmt.t, unit, unit) format4) : 'a =
  match w.perm with Main -> Log.stdout fmt | _ -> Log.ignore fmt

let mkdir (p : perm) (w : t) : unit Exec.result = execute p w Fs.mkdir
let mkdir_noerr (p : perm) (w : t) : unit = execute_noerr p w Fs.mkdir_noerr

let copy (p : perm) (w : t) (src : Fpath.t) : unit Exec.result =
  execute p w (Fun.flip Fs.copy src)

let copy_noerr (p : perm) (w : t) (src : Fpath.t) : unit =
  execute_noerr p w (Fun.flip Fs.copy_noerr src)

let output (p : perm) (w : t) (pp : Fmt.t -> 'a -> unit) (v : 'a) :
    unit Exec.result =
  execute p w (Fun.flip2 Fs.output pp v)

let output_noerr (p : perm) (w : t) (pp : Fmt.t -> 'a -> unit) (v : 'a) : unit =
  execute_noerr p w (Fun.flip2 Fs.output_noerr pp v)

let write (p : perm) (w : t) (fmt : ('b, Fmt.t, unit, 'a) format4) : 'b =
  let write_f acc path = Fs.write path "%t" acc in
  Fmt.kdly (fun acc -> execute p w (write_f acc)) fmt

let write_noerr (p : perm) (w : t) (fmt : ('b, Fmt.t, unit, 'a) format4) : 'b =
  let write_f acc path = Fs.write_noerr path "%t" acc in
  Fmt.kdly (fun acc -> execute_noerr p w (write_f acc)) fmt

let clean (w : t) : unit Exec.result =
  let open Result in
  let create_dir_template dir_path manifest_path =
    let* _ = Fs.mkdir dir_path in
    Fs.write manifest_path "" in
  let override_dir dir_path manifest_path warn =
    if warn then Log.warn "Overriding \"%a\" directory." Fpath.pp dir_path;
    let* _ = Fs.delete ~recurse:true dir_path in
    create_dir_template dir_path manifest_path in
  let override_file file_path =
    Log.warn "Overriding \"%a\" file." Fpath.pp file_path;
    Fs.delete file_path in
  let error_dir dir_path =
    Exec.error "Cannot override \"%a\" directory." Fpath.pp dir_path in
  let error_file file_path =
    Exec.error "Cannot override \"%a\" file." Fpath.pp file_path in
  match w.path with
  | None -> Ok ()
  | (Single path | Bundle path) when not (Fpath.is_dir_path path) ->
    let* exists_file = Fs.exists path in
    if exists_file && Config.(!override) then override_file path
    else if exists_file then error_file path
    else Ok ()
  | Single dir_path | Bundle dir_path ->
    let manifest_path = Fpath.append dir_path Config.(!dflt_manifest_path) in
    let* exists_dir = Fs.exists dir_path in
    if exists_dir then
      let* exists_manifest = Fs.exists manifest_path in
      if exists_manifest then override_dir dir_path manifest_path false
      else if Config.(!override) then override_dir dir_path manifest_path true
      else error_dir dir_path
    else create_dir_template dir_path manifest_path

let prepare (w : t) : unit Exec.result =
  Fun.flip Result.map (clean w) (fun res ->
      Log.info "Workspace \"%a\" generated successfully." pp_path w;
      res )

let extend (w : t) (name : string) : t =
  match (w.path, name) with
  | (None, _) -> w
  | (Single path, _) -> single ~w Fpath.(path // v name)
  | (Bundle path, _) -> bundle ~w Fpath.(to_dir_path (path // v name))

let set_ext (w : t) : t =
  match (w.path, w.ext) with
  | (Single path, Some ext) -> { w with path = Single Fpath.(path -+ ext) }
  | _ -> w
