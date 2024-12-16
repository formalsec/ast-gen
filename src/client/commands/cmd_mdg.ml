open Graphjs_base
open Graphjs_shared
open Graphjs_parser
open Graphjs_ast
open Graphjs_mdg
open Result

module Options = struct
  type t =
    { inputs : Fpath.t list
    ; output : Fpath.t option
    ; taint_config : Fpath.t
    }

  let set (no_svg : bool) (wrap_prop_updates : bool) : unit =
    Builder_config.(export_svg $= not no_svg);
    Builder_config.(wrap_literal_property_updates $= wrap_prop_updates)

  let set_cmd (inputs : Fpath.t list) (output : Fpath.t option)
      (taint_config' : Fpath.t option) () : t =
    let taint_config = Share.parse_taint_config taint_config' in
    { inputs; output; taint_config }
end

module Workspace = struct
  include Workspace

  let builder (w : t) (multifile : bool) (rel : Fpath.t) : t =
    let temp_f rel = Filename.temp_file "graphjs" (Fpath.to_string rel) in
    let dir_f w = Fs.mkdir_noerr (Fpath.parent (path w)) |> fun () -> w in
    let rel' = Fpath.rem_ext rel in
    match (multifile, w.out, Builder_config.(!export_svg)) with
    | (false, None, true) -> single ~w Fpath.(v (temp_f rel') + "svg")
    | (false, None, false) -> w
    | (false, Single _, _) -> w
    | (false, Bundle _, _) -> dir_f (w / "mdg" // rel')
    | (true, Bundle _, _) -> dir_f (w / "mdg" // rel' // rel')
    | (true, _, _) -> none
end

module Output = struct
  let svg_url (path : Fpath.t) : string = Fpath.to_string path |> Console.url

  let mdg (w : Workspace.t) (path : Fpath.t) (mdg : Mdg.t) : unit =
    let w' = Workspace.(w + "mdg") in
    Log.info "MDG \"%a\" built successfully." Fpath.pp path;
    Log.verbose "%a" Mdg.pp mdg;
    match (w'.out, Builder_config.(!export_svg)) with
    | (Bundle _, _) -> Workspace.write_noerr Side w' (Fmt.dly "%a" Mdg.pp mdg)
    | (_, false) -> Workspace.write_noerr Main w (Fmt.dly "%a" Mdg.pp mdg)
    | _ -> ()

  let dot (w : Workspace.t) (mdg : Mdg.t) : unit =
    if Builder_config.(!export_svg) then
      let w' = Workspace.(w -+ "dot") in
      Workspace.execute_noerr Side w' (Fun.flip Svg_exporter.export_dot mdg)

  let svg (w : Workspace.t) (path : Fpath.t) (mdg : Mdg.t) : unit =
    if Builder_config.(!export_svg) then (
      Log.info "MDG \"%a\" exported successfully." Fpath.pp path;
      match w.out with
      | Single path ->
        let export_f = Fun.flip Svg_exporter.export_svg (`Mdg mdg) in
        Log.verbose "%s" (svg_url path);
        Workspace.execute_noerr Main w export_f
      | Bundle path ->
        let w' = Workspace.(w + "svg") in
        let dot_path = Fpath.(path + "dot") in
        let export_f = Fun.flip Svg_exporter.export_svg (`Dot dot_path) in
        Log.verbose "%s" (svg_url (Workspace.path w'));
        Workspace.execute_noerr Side w' export_f
      | _ -> () )

  let builder (w : Workspace.t) (multifile : bool) (mdg : Mdg.t) : unit =
    match (multifile, Builder_config.(!export_svg), w.out) with
    | (false, false, _) -> Workspace.log w (Fmt.dly "%a@." Mdg.pp mdg)
    | (false, true, Single path) ->
      Workspace.log w (Fmt.dly "%s@." (svg_url path))
    | (false, true, Bundle path) ->
      Workspace.log w (Fmt.dly "%s@." (svg_url Fpath.(path + "svg")))
    | _ -> ()
end

let mdg_builder (builder : State.t) (file : 'm File.t) () : Mdg.t =
  Builder.build_file builder file

let mdgs_files (workspace : Workspace.t) (builder : State.t)
    (dt : Dependency_tree.t) (prog : 'm Prog.t) :
    (Fpath.t * Mdg.t) Exec.status list =
  let multifile = Dependency_tree.multi_file dt in
  Fun.flip Dependency_tree.bottom_up_visit dt @@ fun (path, mrel) ->
  let file = Prog.find prog path in
  let* mdg = Exec.graphjs (mdg_builder builder file) in
  let w' = Workspace.builder workspace multifile mrel in
  Output.mdg w' path mdg;
  Output.dot w' mdg;
  Output.svg w' path mdg;
  Output.builder w' multifile mdg;
  Ok (path, mdg)

let merge_mdgs (_workspace : Workspace.t) (_mdgs : (Fpath.t * Mdg.t) list)
    (main : Fpath.t * Mdg.t) : (Fpath.t * Mdg.t) Exec.status =
  (* TODO: merge the mdgs and add the JavaScript standard functions *)
  Ok main

let run (tc : Taint_config.t) ((w, input) : Workspace.t * Fpath.t) :
    (Fpath.t * Mdg.t) Exec.status =
  let* _ = Workspace.mkdir Side w in
  let* (dt, prog) = Cmd_parse.run (Workspace.side w, input) in
  let builder = Builder.initialize_builder tc in
  let* mdgs = Result.extract (mdgs_files w builder dt prog) in
  merge_mdgs w mdgs (List.find (fun (path, _) -> Fpath.equal path dt.path) mdgs)

let main (opts : Options.t) () : unit Exec.status =
  let ext = if Builder_config.(!export_svg) then "svg" else "mdg" in
  let w = Workspace.create ~default:`Single opts.inputs opts.output in
  let* () = Workspace.clean w in
  let* workpairs = Workspace.prepare ~ext w opts.inputs in
  let* tc = Exec.graphjs (Share.read_taint_config w opts.taint_config) in
  Workspace.run (run tc) workpairs
