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

  let set (config : Fpath.t option) (no_svg : bool) : Fpath.t option =
    Builder_config.(export_svg $= not no_svg);
    config

  let set_cmd (input : Fpath.t) (output : Fpath.t option)
      (config : Fpath.t option) : t =
    { input; output; config }
end

let parse_taint_config = function
  | Some tconf -> Fpath.to_string tconf
  | None -> Shared_config.default_taint_config ()

let taint_config (output : Fpath.t option) (path : string) () : Taint_config.t =
  let tconf = Taint_config.read path in
  let tconf_path = Fpath.v "tconf.txt" in
  Log.info "Tainted config %S parsed successfully." path;
  Log.verbose "%a" Taint_config.pp tconf;
  Fs.write_noerr output tconf_path (Fmt.dly "%a" Taint_config.pp tconf);
  tconf

let build_mdgs (output : Fpath.t option) (tconf : Taint_config.t)
    (dep_tree : Dependency_tree.t) (prog : 'm Prog.t) :
    (string * Mdg.t) Exec.status list =
  Fun.flip Dependency_tree.bottom_up_visit dep_tree @@ fun (abs, rel) ->
  let path = Fpath.to_string abs in
  let relative_path = Fpath.rem_ext rel in
  let mdg_path = Fpath.((v "graph" // relative_path // relative_path) + "mdg") in
  let export_path = Fpath.(v "graph" // relative_path // relative_path) in
  let file = Prog.find prog path in
  let* mdg = Exec.graphjs (fun () -> Builder.build_file tconf file) in
  Log.info "MDG of %S built successfully." path;
  Log.verbose "%a" Mdg.pp mdg;
  Fs.write_noerr output mdg_path (Fmt.dly "%a" Mdg.pp mdg);
  Fs.output_noerr output export_path (fun path ->
      Ok (Svg_exporter.export (Fpath.to_string path) mdg) );
  Ok (path, mdg)

let merge_mdgs (mdgs : (string * Mdg.t) list) : Mdg.t Exec.status =
  Ok (List.hd mdgs |> snd)

let run (input : Fpath.t) (output : Fpath.t option) (config : Fpath.t option) :
    Mdg.t Exec.status =
  let config' = parse_taint_config config in
  let* tconf = Exec.graphjs (taint_config output config') in
  let* (dep_tree, prog) = Cmd_parse.run input output in
  let build_res = build_mdgs output tconf dep_tree prog in
  let* mdgs = Result.extract build_res in
  merge_mdgs mdgs

let main (opts : Options.t) () : unit Exec.status =
  let* () = Fs.prepare opts.output in
  let* mdg = run opts.input opts.output opts.config in
  if not Log.Config.(!log_verbose) then Log.stdout "%a@." Mdg.pp mdg;
  Ok ()
