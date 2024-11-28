open Graphjs_base
open Graphjs_shared

module Options = struct
  type t =
    { input : Fpath.t
    ; output : Fpath.t option
    ; config : Fpath.t option
    }

  let set () : unit = ()

  let set_cmd (input : Fpath.t) (output : Fpath.t option)
      (config : Fpath.t option) : t =
    { input; output; config }
end

let parse_taint_config = function
  | Some config -> Fpath.to_string config
  | None -> Shared_config.default_taint_config ()

let tainted_config (path : string) () : Taint_config.t =
  let tconf = Taint_config.read path in
  Log.info "Tainted config %S parsed successfully." path;
  Log.verbose "%a" Taint_config.pp tconf;
  tconf

let run (opts : Options.t) () : unit Exec.status =
  let open Result in
  let config = parse_taint_config opts.config in
  let* _tconf = Exec.graphjs (tainted_config config) in
  (* let input = Fpath.to_string opts.input in *)
  Ok ()
