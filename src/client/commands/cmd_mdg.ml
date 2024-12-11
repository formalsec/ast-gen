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
    ; taint_config : Fpath.t
    }

  let parse_taint_config = function
    | Some taint_config -> taint_config
    | None -> Shared_config.default_taint_config ()

  let set (no_svg : bool) (wrap_prop_updates : bool) : unit =
    Builder_config.(export_svg $= not no_svg);
    Builder_config.(wrap_literal_property_updates $= wrap_prop_updates)

  let set_cmd (input : Fpath.t) (output : Fpath.t option)
      (taint_config' : Fpath.t option) () : t =
    let taint_config = parse_taint_config taint_config' in
    { input; output; taint_config }
end

let read_taint_config (output : Fpath.t option) (path : Fpath.t) () :
    Taint_config.t =
  let tc = Taint_config.read path in
  let tc_path = Fs.OptPath.(create Dir output / "taint_config.conf") in
  Log.info "Tainted config \"%a\" parsed successfully." Fpath.pp path;
  Log.verbose "%a" Taint_config.pp tc;
  Fs.write_noerr tc_path (Fmt.dly "%a" Taint_config.pp tc);
  tc

let build_file (tc : Taint_config.t) (file : 'm File.t) () : Mdg.t =
  Builder.build_file tc file

let build_mdgs (output : Fpath.t option) (tc : Taint_config.t)
    (dt : Dependency_tree.t) (prog : 'm Prog.t) :
    (Fpath.t * Mdg.t) Exec.status list =
  Fun.flip Dependency_tree.bottom_up_visit dt @@ fun (abs_path, rel_path) ->
  let file = Prog.find prog abs_path in
  let* mdg = Exec.graphjs (build_file tc file) in
  let rel_path' = Fpath.rem_ext rel_path in
  let graph_path = Fs.OptPath.(create Dir output / "mdg" // rel_path') in
  let mdg_path = Fs.OptPath.((graph_path // rel_path') + "mdg") in
  let svg_path = Fs.OptPath.(graph_path // rel_path') in
  Log.info "MDG of \"%a\" built successfully." Fpath.pp abs_path;
  Log.verbose "%a" Mdg.pp mdg;
  Fs.write_noerr mdg_path (Fmt.dly "%a" Mdg.pp mdg);
  Fs.output_noerr svg_path (fun path -> Ok (Svg_exporter.export path mdg));
  Ok (abs_path, mdg)

let merge_mdgs (mdgs : (Fpath.t * Mdg.t) list) : Mdg.t Exec.status =
  (* TODO: merge the mdgs and add the JavaScript standard functions *)
  Ok (List.hd mdgs |> snd)

let run (input : Fpath.t) (output : Fpath.t option) (taint_config : Fpath.t) :
    Mdg.t Exec.status =
  let* tc = Exec.graphjs (read_taint_config output taint_config) in
  let* (dt, prog) = Cmd_parse.run input output in
  let* mdgs = Result.extract (build_mdgs output tc dt prog) in
  merge_mdgs mdgs

let main (opts : Options.t) () : unit Exec.status =
  let* () = Fs.prepare opts.output in
  let* mdg = run opts.input opts.output opts.taint_config in
  if not Log.Config.(!log_verbose) then Log.stdout "%a@." Mdg.pp mdg;
  Ok ()
