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
    | (false, Bundle _, _) -> dir_f ((w / "mdg" // rel') + "svg")
    | (true, Bundle _, _) -> dir_f ((w / "mdg" // rel' // rel') + "svg")
    | (true, _, _) -> none
end

module Output = struct
  let svg_url (url : Fpath.t) : string =
    (* FIXME: add url text *)
    Console.url (Fpath.to_string url)

  let mdg (w : Workspace.t) (path : Fpath.t) (mdg : Mdg.t) : unit =
    let w' = Workspace.(w -+ "mdg") in
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

  let svg (w : Workspace.t) (path : Fpath.t) (mdg : Mdg.t) : unit Exec.status =
    if Builder_config.(!export_svg) then (
      Log.info "MDG \"%a\" exported successfully." Fpath.pp path;
      match w.out with
      | Single path' ->
        let export_f path = Svg_exporter.export_svg path (`Mdg mdg) in
        let export_f' path = Exec.graphjs (fun () -> export_f path) in
        let* res = Workspace.execute Main w export_f' in
        Log.verbose "%s" (svg_url path');
        Ok res
      | Bundle path' ->
        let dot_path = Fpath.(path' -+ "dot") in
        let export_f path = Svg_exporter.export_svg path (`Dot dot_path) in
        let export_f' path = Exec.graphjs (fun () -> export_f path) in
        Workspace.execute_noerr Side w export_f';
        let* res = Workspace.execute Main w export_f' in
        Log.verbose "%s" (svg_url path');
        Ok res
      | _ -> Ok () )
    else Ok ()

  let main (w : Workspace.t) (mdg : Mdg.t) : unit =
    match (Builder_config.(!export_svg), w.out) with
    | (false, _) -> Workspace.log w (Fmt.dly "%a@." Mdg.pp mdg)
    | (true, Single path) | (true, Bundle path) ->
      Workspace.log w (Fmt.dly "%s@." (svg_url path))
    | _ -> ()
end

type mdg_res = Fpath.t * Workspace.t * Mdg.t

let mdg_builder (builder : State.t) (file : 'm File.t) () : Mdg.t =
  Builder.build_file builder file

let mdgs_files (workspace : Workspace.t) (builder : State.t)
    (dt : Dependency_tree.t) (prog : 'm Prog.t) : mdg_res Exec.status list =
  let multifile = Dependency_tree.multi_file dt in
  Fun.flip Dependency_tree.bottom_up_visit dt (fun (path, mrel) ->
      let file = Prog.find prog path in
      let* mdg = Exec.graphjs (mdg_builder builder file) in
      let w' = Workspace.builder workspace multifile mrel in
      let () = Output.mdg w' path mdg in
      let () = Output.dot w' mdg in
      let* _ = Output.svg w' path mdg in
      Ok (path, w', mdg) )

let merge_mdgs (_w : Workspace.t) (_mdgs : mdg_res list)
    ((_, w', mdg) as main : mdg_res) : mdg_res Exec.status =
  (* TODO: merge the mdgs and add the JavaScript standard functions *)
  Output.main w' mdg;
  Ok main

let run (tc : Taint_config.t) (input : Fpath.t) (w : Workspace.t) :
    mdg_res Exec.status =
  let* _ = Workspace.mkdir Side w in
  let* (dt, prog) = Cmd_parse.run input (Workspace.side w) in
  let builder = Builder.initialize_builder tc in
  let* mdgs = Result.extract (mdgs_files w builder dt prog) in
  merge_mdgs w mdgs
    (List.find (fun (path, _, _) -> Fpath.equal path dt.path) mdgs)

let outcome (result : mdg_res Exec.status) : Bulk.Instance.outcome =
  match result with
  | Ok _ -> Success
  | Error (`DepTree _) -> Failure
  | Error (`ParseJS _) -> Failure
  | Error (`BuildMDG _) -> Failure
  | Error (`ExportMDG _) -> Anomaly
  | Error _ -> Anomaly

let bulk_interface (tc : Taint_config.t) : (module Bulk.CmdInterface) =
  ( module struct
    type t = mdg_res

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
