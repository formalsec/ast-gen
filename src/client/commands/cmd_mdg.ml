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

  let set (no_svg : bool) (wrap_prop_updates : bool) : unit =
    Builder_config.(export_svg $= not no_svg);
    Builder_config.(wrap_literal_property_updates $= wrap_prop_updates)

  let set_cmd (input : Fpath.t) (output : Fpath.t option)
      (taint_config' : Fpath.t option) () : t =
    let taint_config = Share.parse_taint_config taint_config' in
    { input; output; taint_config }
end

type mdg_entry = Fpath.t * Fpath.t option * Mdg.t

module Path = struct
  let graph (output : Fpath.t option) (rel : Fpath.t) (dt : Dependency_tree.t) :
      Fpath.t option =
    match Dependency_tree.multi_file dt with
    | true -> Fs.OptPath.(create Dir output / "mdg" // rel // rel)
    | false -> Fs.OptPath.(create Dir output / "mdg" // rel)

  let svg (graph : Fpath.t option) (rel : Fpath.t) : Fpath.t option =
    let temp_file_f rel = Filename.temp_file "graphjs" (Fpath.to_string rel) in
    match (Builder_config.(!export_svg), graph) with
    | (false, _) -> None
    | (true, None) -> Some (Fpath.v (temp_file_f rel))
    | (true, Some _) -> graph
end

module Output = struct
  let get_svg_path (path : Fpath.t) : string =
    Fpath.(path + "svg") |> Fpath.to_string |> Console.url

  let mdg (graph : Fpath.t option) (mdg : Mdg.t) : unit =
    let path = Fs.OptPath.(graph + "mdg") in
    if not Builder_config.(!export_svg) then Log.verbose "%a" Mdg.pp mdg;
    Fs.write_noerr path (Fmt.dly "%a" Mdg.pp mdg)

  let svg (path : Fpath.t option) (mdg : Mdg.t) : unit =
    Fun.flip Option.iter path @@ fun path' ->
    Log.verbose "%s" (get_svg_path path');
    Svg_exporter.export path' mdg

  let command ((_, svg, mdg) : mdg_entry) : unit =
    match (Log.Config.(!log_verbose), svg) with
    | (true, _) -> ()
    | (false, None) -> Log.stdout "%a@." Mdg.pp mdg
    | (false, Some svg') -> Log.stdout "%s@." (get_svg_path svg')
end

let mdg_builder (builder : State.t) (file : 'm File.t) () : Mdg.t =
  Builder.build_file builder file

let mdgs_files (output : Fpath.t option) (builder : State.t)
    (dt : Dependency_tree.t) (prog : 'm Prog.t) : mdg_entry Exec.status list =
  Fun.flip Dependency_tree.bottom_up_visit dt @@ fun (abs_path, rel_path) ->
  let file = Prog.find prog abs_path in
  let* mdg = Exec.graphjs (mdg_builder builder file) in
  let rel_path' = Fpath.rem_ext rel_path in
  let graph_path = Path.graph output rel_path' dt in
  let svg_path = Path.svg graph_path rel_path' in
  Log.info "MDG of \"%a\" built successfully." Fpath.pp abs_path;
  Output.mdg graph_path mdg;
  Output.svg svg_path mdg;
  Ok (abs_path, svg_path, mdg)

let merge_mdgs (_mdgs : mdg_entry list) (main : mdg_entry) :
    mdg_entry Exec.status =
  (* TODO: merge the mdgs and add the JavaScript standard functions *)
  Ok main

let run (input : Fpath.t) (output : Fpath.t option)
    (taint_config : Taint_config.t) : mdg_entry Exec.status =
  let* (dt, prog) = Cmd_parse.run input output in
  let builder = Builder.initialize_builder taint_config in
  let* mdgs = Result.extract (mdgs_files output builder dt prog) in
  merge_mdgs mdgs
    (List.find (fun (abs_path, _, _) -> Fpath.equal abs_path dt.abs) mdgs)

let main (opts : Options.t) () : unit Exec.status =
  let* () = Fs.prepare opts.output in
  let* taint_config =
    Exec.graphjs (Share.read_taint_config opts.output opts.taint_config) in
  let* mdg = run opts.input opts.output taint_config in
  Output.command mdg;
  Ok ()
