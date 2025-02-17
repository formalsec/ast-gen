open Graphjs_base
open Graphjs_share

module Output = struct
  let taint_config (w : Workspace.t) (path : Fpath.t) (tc : Taint_config.t) :
      unit =
    let w' = Workspace.(w / "taint_config.conf") in
    Log.info "Tainted config \"%a\" read successfully." Fpath.pp path;
    Log.verbose "%a" Taint_config.pp tc;
    Workspace.output_noerr Side w' Taint_config.pp tc
end

let parse_taint_config = function
  | None -> Properties.default_taint_config ()
  | Some tc -> tc

let read_taint_config (w : Workspace.t) (path : Fpath.t) () : Taint_config.t =
  let tc = Taint_config.read path in
  Output.taint_config w path tc;
  tc
