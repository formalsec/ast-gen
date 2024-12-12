open Graphjs_base
open Graphjs_shared

module Output = struct
  let taint_config (output : Fpath.t option) (tc : Taint_config.t) : unit =
    let path = Fs.OptPath.(create Dir output / "taint_config.conf") in
    Log.verbose "%a" Taint_config.pp tc;
    Fs.write_noerr path (Fmt.dly "%a" Taint_config.pp tc)
end

let parse_taint_config = function
  | None -> Shared_config.default_taint_config ()
  | Some tc -> tc

let read_taint_config (output : Fpath.t option) (path : Fpath.t) () :
    Taint_config.t =
  let tc = Taint_config.read path in
  Log.info "Tainted config \"%a\" read successfully." Fpath.pp path;
  Output.taint_config output tc;
  tc
