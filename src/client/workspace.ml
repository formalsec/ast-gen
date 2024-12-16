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

let execute (p : perm) (w : t) (f : Fpath.t -> unit Exec.status) :
    unit Exec.status =
  match (p, w.out) with
  | (Main, Single path) | (Main, Bundle path) | (Side, Bundle path) -> f path
  | _ -> Ok ()

let execute_noerr (p : perm) (w : t) (f : Fpath.t -> unit) : unit =
  match (p, w.out) with
  | (Main, Single path) | (Main, Bundle path) | (Side, Bundle path) -> f path
  | _ -> ()

let mkdir (p : perm) (w : t) : unit Exec.status = execute p w Fs.mkdir
let mkdir_noerr (p : perm) (w : t) : unit = execute_noerr p w Fs.mkdir_noerr

let copy (p : perm) (w : t) (src : Fpath.t) : unit Exec.status =
  execute p w (Fun.flip Fs.copy src)

let copy_noerr (p : perm) (w : t) (src : Fpath.t) : unit =
  execute_noerr p w (Fun.flip Fs.copy_noerr src)

let output (p : perm) (w : t) (f : Fpath.t -> unit Exec.status) :
    unit Exec.status =
  execute p w (Fun.flip Fs.output f)

let output_noerr (p : perm) (w : t) (f : Fpath.t -> unit Exec.status) : unit =
  execute_noerr p w (Fun.flip Fs.output_noerr f)

let write (p : perm) (w : t) (fmt : Fmt.t -> unit) : unit Exec.status =
  execute p w (Fun.flip Fs.write fmt)

let write_noerr (p : perm) (w : t) (fmt : Fmt.t -> unit) : unit =
  execute_noerr p w (Fun.flip Fs.write_noerr fmt)

let clean (w : t) : unit Exec.status =
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
    Exec.generic_exn "Cannot override \"%a\" directory." Fpath.pp path in
  let error_file path =
    Exec.generic_exn "Cannot override \"%a\" file." Fpath.pp path in
  match w.out with
  | None -> Ok ()
  | (Single path | Bundle path) when not (Fpath.is_dir_path path) ->
    let* exists_file = Exec.bos (Bos.OS.File.exists path) in
    if exists_file && Config.(!override) then override_file path
    else if exists_file then error_file path
    else Ok ()
  | Single path | Bundle path ->
    let manifest = Fpath.add_seg path ".graphjs" in
    let* exists_dir = Exec.bos (Bos.OS.Dir.exists path) in
    if exists_dir then
      let* exists_manifest = Exec.bos (Bos.OS.File.exists manifest) in
      if exists_manifest then override_dir manifest path false
      else if Config.(!override) then override_dir manifest path true
      else error_dir path
    else create_dir_template manifest path

module WorkpairTree = struct
  type t' =
    | File of Fpath.t
    | Directory of t

  and t = (string, t') Hashtbl.t

  let create () : t = Hashtbl.create Config.(!dflt_htbl_sz)

  let add (tree : t) (abs : Fpath.t) (rel : Fpath.t) : unit =
    let rec add' tree = function
      | [] -> Log.fail "unexpected path in workpair tree"
      | [ filename ] -> Hashtbl.add tree filename (File rel)
      | dirname :: sections -> (
        match Hashtbl.find_opt tree dirname with
        | Some (File _) -> Log.fail "unexpected path in workspace tree"
        | Some (Directory dir) -> add' dir sections
        | None ->
          let dir = Hashtbl.create Config.(!dflt_htbl_sz) in
          Hashtbl.add tree dirname (Directory dir);
          add' dir sections ) in
    add' tree (Fpath.to_string abs |> String.split_on_char '/' |> List.tl)

  let generate (inputs : Fpath.t list) : t =
    let tree = create () in
    let pwd = Fpath.v (Console.pwd ()) in
    ( Fun.flip List.iter inputs @@ fun rel ->
      let abs = Fpath.normalize Fpath.(pwd // rel) in
      add tree abs rel );
    tree

  let process (tree : t) : (string * Fpath.t) list =
    let rec process' curr dir acc =
      let single = Hashtbl.length dir <= 1 in
      Fun.flip2 Hashtbl.fold dir acc @@ fun section tree acc ->
      match (tree, single) with
      | (File rel, _) -> (curr ^ section, rel) :: acc
      | (Directory dir', true) -> process' curr dir' acc
      | (Directory dir', false) -> process' (curr ^ section ^ "/") dir' acc
    in
    process' "" tree []
end

let extend_workspace (workpairs : (string * Fpath.t) list) (w : t) (ext : string)
    : (t * Fpath.t) list =
  let f w = Fs.mkdir_noerr (Fpath.parent (path w)) |> fun () -> w in
  Fun.flip List.map workpairs @@ fun (wp, input) ->
  match (w.out, wp) with
  | (None, _) | (Single _, "") | (Bundle _, "") -> (w, input)
  | (Single path, _) -> (f (single ~w Fpath.((path // v wp) -+ ext)), input)
  | (Bundle path, _) -> (f (bundle ~w Fpath.(to_dir_path (path // v wp))), input)

let prepare ?(ext : string = "") (w : t) (inputs : Fpath.t list) :
    (t * Fpath.t) list Exec.status =
  let tree = WorkpairTree.generate inputs in
  let workpairs = WorkpairTree.process tree in
  let workpairs' = extend_workspace workpairs w ext in
  Log.info "Workspace \"%a\" prepared successfully." pp w;
  Ok workpairs'

let run (run_f : t * Fpath.t -> 'a Exec.status) (workpairs : (t * Fpath.t) list)
    : unit Exec.status =
  let run_f' (w, input) =
    try run_f (w, input)
    with _ -> Exec.generic_exn "(FIXME)Error on \"%a\"" Fpath.pp input in
  ignore (List.map run_f' workpairs);
  Ok ()
