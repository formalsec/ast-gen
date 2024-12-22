open Graphjs_base

module Config = struct
  include Config

  let override : bool t = static false
end

type perm =
  | None
  | Main
  | Side

type out =
  | None
  | Single of Fpath.t
  | Bundle of Fpath.t

type t =
  { perm : perm
  ; out : out
  }

let none : t = { perm = Main; out = None }
let single ?(w : t = none) (path : Fpath.t) : t = { w with out = Single path }
let bundle ?(w : t = none) (path : Fpath.t) : t = { w with out = Bundle path }

let create ~(default : [ `None | `Single | `Bundle ]) (inputs : Fpath.t list)
    (output : Fpath.t option) : t =
  match (output, default) with
  | (None, _) when List.length inputs == 1 -> none
  | (None, `None) -> none
  | (None, `Single) -> single (Fpath.v ".out/")
  | (None, `Bundle) -> bundle (Fpath.v ".out/")
  | (Some path, _) when Fpath.is_dir_path path -> bundle path
  | (Some path, _) -> single path

let side (w : t) : t = { w with perm = Side }

let pp (ppf : Fmt.t) : t -> unit = function
  | { out = None; _ } -> ()
  | { out = Single path; _ } | { out = Bundle path; _ } -> Fpath.pp ppf path

let path : t -> Fpath.t = function
  | { out = None; _ } -> Log.fail "unexpected 'none' workspace"
  | { out = Single path; _ } | { out = Bundle path; _ } -> path

let map (f : Fpath.t -> Fpath.t) : t -> t = function
  | { out = None; _ } as w -> w
  | { out = Single path; _ } as w -> { w with out = Single (f path) }
  | { out = Bundle path; _ } as w -> { w with out = Bundle (f path) }

let ( / ) (w : t) (rel : string) : t = map Fpath.(fun w' -> w' / rel) w
let ( // ) (w : t) (rel : Fpath.t) : t = map Fpath.(fun w' -> w' // rel) w
let ( -+ ) (w : t) (ext : string) : t = map Fpath.(fun w' -> w' -+ ext) w
let ( + ) (w : t) (ext : string) : t = map Fpath.(fun w' -> w' + ext) w

let log (w : t) (fmt : Fmt.t -> unit) : unit =
  match w.perm with
  | Main when not Log.Config.(!log_verbose) -> Log.stdout "%t" fmt
  | _ -> ()

let execute (p : perm) (w : t) (f : Fpath.t -> 'a Exec.status) :
    unit Exec.status =
  match (p, w.out) with
  | (Main, Single path) | (Main, Bundle path) | (Side, Bundle path) ->
    Result.map ignore (f path)
  | _ -> Ok ()

let execute_noerr (p : perm) (w : t) (f : Fpath.t -> 'a) : unit =
  match (p, w.out) with
  | (Main, Single path) | (Main, Bundle path) | (Side, Bundle path) ->
    ignore (f path)
  | _ -> ()

let mkdir (p : perm) (w : t) : unit Exec.status = execute p w Fs.mkdir
let mkdir_noerr (p : perm) (w : t) : unit = execute_noerr p w Fs.mkdir_noerr

let copy (p : perm) (w : t) (src : Fpath.t) : unit Exec.status =
  execute p w (Fun.flip Fs.copy src)

let copy_noerr (p : perm) (w : t) (src : Fpath.t) : unit =
  execute_noerr p w (Fun.flip Fs.copy_noerr src)

let output (p : perm) (w : t) (pp : Fmt.t -> 'a -> unit) (v : 'a) :
    unit Exec.status =
  execute p w (Fun.flip2 Fs.output pp v)

let output_noerr (p : perm) (w : t) (pp : Fmt.t -> 'a -> unit) (v : 'a) : unit =
  execute_noerr p w (Fun.flip2 Fs.output_noerr pp v)

let write (p : perm) (w : t) (fmt : Fmt.t -> unit) : unit Exec.status =
  execute p w (Fun.flip Fs.write fmt)

let write_noerr (p : perm) (w : t) (fmt : Fmt.t -> unit) : unit =
  execute_noerr p w (Fun.flip Fs.write_noerr fmt)

let clean' (w : t) : unit Exec.status =
  let open Result in
  let create_dir_template manifest path =
    let* _ = Exec.bos (Bos.OS.Dir.create path) in
    Exec.bos (Bos.OS.File.write manifest "") in
  let override_dir manifest path warn =
    if warn then Log.warn "Overriding \"%a\" directory." Fpath.pp path;
    let* _ = Exec.bos (Bos.OS.Dir.delete ~recurse:true path) in
    create_dir_template manifest path in
  let override_file path =
    Log.warn "Overriding \"%a\" file." Fpath.pp path;
    Exec.bos (Bos.OS.File.delete path) in
  let error_dir path =
    Exec.error "Cannot override \"%a\" directory." Fpath.pp path in
  let error_file path =
    Exec.error "Cannot override \"%a\" file." Fpath.pp path in
  match w.out with
  | None -> Ok ()
  | (Single path | Bundle path) when not (Fpath.is_dir_path path) ->
    let* exists_file = Exec.bos (Bos.OS.File.exists path) in
    if exists_file && Config.(!override) then override_file path
    else if exists_file then error_file path
    else Ok ()
  | Single path | Bundle path ->
    let manifest = Fpath.add_seg path "manifest.graphjs" in
    let* exists_dir = Exec.bos (Bos.OS.Dir.exists path) in
    if exists_dir then
      let* exists_manifest = Exec.bos (Bos.OS.File.exists manifest) in
      if exists_manifest then override_dir manifest path false
      else if Config.(!override) then override_dir manifest path true
      else error_dir path
    else create_dir_template manifest path

let clean (w : t) : unit Exec.status =
  let res = clean' w in
  Log.info "Workspace \"%a\" generated successfully." pp w;
  res

let extend (w : t) (name : string) : t =
  match (w.out, name) with
  | (None, _) -> w
  | (Single path, _) -> single ~w Fpath.(path // v name)
  | (Bundle path, _) -> bundle ~w Fpath.(to_dir_path (path // v name))
