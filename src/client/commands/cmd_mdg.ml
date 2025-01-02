open Graphjs_base
open Graphjs_share
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

  let set (no_svg : bool) (wrap_prop_updates : bool) () : unit =
    Builder_config.(export_svg $= not no_svg);
    Builder_config.(wrap_literal_property_updates $= wrap_prop_updates)

  let set_cmd (inputs : Fpath.t list) (output : Fpath.t option)
      (taint_config' : Fpath.t option) () : t =
    let taint_config = Share.parse_taint_config taint_config' in
    { inputs; output; taint_config }
end

module Workspace = struct
  include Workspace

  let mdg (w : t) (rel : Fpath.t) (main : bool) : t =
    let temp_f rel = Filename.temp_file "graphjs" (Fpath.to_string rel) in
    let dir_f w = Fs.mkdir_noerr (Fpath.parent (path w)) |> fun () -> w in
    let rel' = Fpath.rem_ext rel in
    match (main, w.out, Builder_config.(!export_svg)) with
    | (true, None, true) -> single ~w Fpath.(v (temp_f rel') + "svg")
    | (true, None, false) -> w
    | (true, Single _, _) -> w
    | (true, Bundle _, _) -> dir_f ((w / "mdg" // rel') + "svg")
    | (false, Bundle _, _) -> dir_f ((w / "mdg" // rel' // rel') + "svg")
    | (false, _, _) -> none
end

module Output = struct
  let svg_url (url : Fpath.t) : string = Console.url (Fpath.to_string url)

  let export_svg (kind : [ `Dot of Fpath.t | `Mdg of Mdg.t ]) (path : Fpath.t) :
      unit Exec.status =
    Exec.graphjs (fun () -> Svg_exporter.export_svg path kind)

  let mdg (w : Workspace.t) (path : Fpath.t) (mdg : Mdg.t) : unit =
    let w' = Workspace.(w -+ "mdg") in
    Log.info "MDG \"%a\" built successfully." Fpath.pp path;
    Log.verbose "%a" Mdg.pp mdg;
    Workspace.output_noerr Side w' Mdg.pp mdg;
    if Builder_config.(!export_svg) then (
      let w'' = Workspace.(w -+ "dot") in
      Workspace.execute_noerr Side w'' (Fun.flip Svg_exporter.export_dot mdg);
      match w.out with
      | Bundle svg_path ->
        let dot_path = Workspace.path w'' in
        Log.info "MDG \"%a\" exported successfully." Fpath.pp path;
        Workspace.execute_noerr Side w (export_svg (`Dot dot_path));
        Log.verbose "%s" (svg_url svg_path)
      | _ -> () )

  let main (w : Workspace.t) (mdg : Mdg.t) : unit Exec.status =
    let w' = Workspace.(w -+ "mdg") in
    Log.info "MDGs merged successfully.";
    Log.verbose "%a" Mdg.pp mdg;
    match (Builder_config.(!export_svg), w.out) with
    | (false, _) ->
      Workspace.output_noerr Main w' Mdg.pp mdg;
      Workspace.log w (Fmt.dly "%a@." Mdg.pp mdg);
      Ok ()
    | (true, Single path') ->
      let* res = Workspace.execute Main w (export_svg (`Mdg mdg)) in
      Workspace.log w (Fmt.dly "%s@." (svg_url path'));
      Ok res
    | (true, Bundle path') ->
      let w'' = Workspace.(w -+ "dot") in
      let dot_path = Workspace.path w'' in
      Workspace.execute_noerr Side w'' (Fun.flip Svg_exporter.export_dot mdg);
      let* res = Workspace.execute Main w (export_svg (`Dot dot_path)) in
      Workspace.log w (Fmt.dly "%s@." (svg_url path'));
      Ok res
    | _ -> Ok ()
end

let mdg_builder (builder : State.t) (file : 'm File.t) () : Mdg.t =
  Builder.build_file builder file

let mdg_merger (merger : Merger.t) () : Mdg.t = Merger.merge_entries merger

let mdgs_files (w : Workspace.t) (builder : State.t) (dt : Dependency_tree.t)
    (prog : 'm Prog.t) : (Fpath.t * Mdg.t) Exec.status list =
  Fun.flip Dependency_tree.bottom_up_visit dt (fun (path, mrel) ->
      let file = Prog.find prog path in
      let* mdg = Exec.graphjs (mdg_builder builder file) in
      let w' = Workspace.mdg w mrel false in
      Output.mdg w' path mdg;
      Ok (mrel, mdg) )

let merge_mdgs (w : Workspace.t) (merger : Merger.t) (main_path : Fpath.t) :
    Mdg.t Exec.status =
  let* mdg = Exec.graphjs (mdg_merger merger) in
  let w' = Workspace.mdg w main_path true in
  let* _ = Output.main w' mdg in
  Ok mdg

let run (tc : Taint_config.t) (input : Fpath.t) (w : Workspace.t) :
    Mdg.t Exec.status =
  let* (dt, prog) = Cmd_parse.run input (Workspace.side w) in
  let builder = Builder.initialize_builder tc in
  let* mdgs = Result.extract (mdgs_files w builder dt prog) in
  let merger = Merger.create tc mdgs in
  merge_mdgs w merger dt.mrel

let outcome (result : Mdg.t Exec.status) : Bulk.Instance.outcome =
  match result with
  | Ok _ -> Success
  | Error (`DepTree _) -> Failure
  | Error (`ParseJS _) -> Failure
  | Error (`BuildMDG _) -> Failure
  | Error (`ExportMDG _) -> Anomaly
  | Error _ -> Anomaly

let bulk_interface (tc : Taint_config.t) : (module Bulk.CmdInterface) =
  ( module struct
    type t = Mdg.t

    let cmd = "mdg"
    let run = run tc
    let outcome = outcome
  end )

let main (opts : Options.t) () : unit Exec.status =
  let ext = if Builder_config.(!export_svg) then "svg" else "mdg" in
  let w = Workspace.create ~default:`Single opts.inputs opts.output in
  let* () = Workspace.clean w in
  let* ipairs = Bulk.InputTree.generate ~ext opts.inputs in
  let* tc = Exec.graphjs (Share.read_taint_config w opts.taint_config) in
  let module Interface = (val bulk_interface tc) in
  let module Executor = Bulk.Executor (Interface) in
  Executor.execute w ipairs
