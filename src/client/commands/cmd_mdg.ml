open Graphjs_base
open Graphjs_shared
open Graphjs_parser
open Graphjs_ast
open Graphjs_mdg
open Result

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
  | Some tconf -> Fpath.to_string tconf
  | None -> Shared_config.default_taint_config ()

let taint_config (path : string) () : Taint_config.t =
  let tconf = Taint_config.read path in
  Log.info "Tainted config %S parsed successfully." path;
  Log.verbose "%a" Taint_config.pp tconf;
  tconf

let build_mdgs (tconf : Taint_config.t) (dep_tree : Dependency_tree.t)
    (prog : 'm Prog.t) : (string * Mdg.t) Exec.status list =
  Fun.flip Dependency_tree.bottom_up_visit dep_tree @@ fun path ->
  let file = Prog.find prog path in
  let* mdg = Exec.graphjs (fun () -> Builder.build_file tconf file) in
  Log.info "MDG of %S built successfully." path;
  Log.verbose "%a" Mdg.pp mdg;
  Ok (path, mdg)

let merge_mdgs (mdgs : (string * Mdg.t) list) : Mdg.t Exec.status =
  Ok (List.hd mdgs |> snd)

let run (input : Fpath.t) (config : Fpath.t option) : Mdg.t Exec.status =
  let config' = parse_taint_config config in
  let* tconf = Exec.graphjs (taint_config config') in
  let* (dep_tree, prog) = Cmd_parse.run input in
  let build_res = build_mdgs tconf dep_tree prog in
  let* mdgs = Result.extract build_res in
  merge_mdgs mdgs

let main (opts : Options.t) () : unit Exec.status =
  let* mdg = run opts.input opts.config in
  if not Log.Config.(!log_verbose) then Log.stdout "%a@." Mdg.pp mdg;
  Ok ()
