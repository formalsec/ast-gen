(* open Graphjs_base
   open Graphjs_config
   open Graphjs_ast
   open Graphjs_mdg
   open Graphjs_client
   open Cmdliner
   module LocationSet = Structures.LocationSet
   module Program = Grammar.Program

   (* Monadic let binding for result *)
   let setup_output output_path =
     let open Result in
     let code_dir = Fpath.(output_path / "code") in
     let graph_dir = Fpath.(output_path / "graph") in
     let run_dir = Fpath.(output_path / "run") in
     let* () = Bos.OS.Dir.delete ~recurse:true output_path in
     let* _ = Bos.OS.Dir.create ~path:true code_dir in
     let* _ = Bos.OS.Dir.create ~path:true graph_dir in
     let* _ = Bos.OS.Dir.create ~path:true run_dir in
     Ok (code_dir, graph_dir, run_dir)

   (* TODO: Use Fpath everywhere *)
   let main file_name output_path config_path mode generate_mdg no_dot verbose =
     (* DANGEROUS: We create "run" but don't pass it to any function?
        Is there any global behaviour that will write to "run"? *)
     let open Result in
     let* (code_dir, graph_dir, _) =
       match setup_output output_path with Ok _ as a -> a | _ -> failwith "temp"
     in
     let* dep_tree = DependencyTree.generate file_name mode in

     (* process dependencies first with the aid of the depedency tree *)
     let summaries = Summaries.empty () in
     let module_graphs = ModuleGraphs.empty () in
     List.iter
       (fun file_path ->
         let dir = Fpath.parent @@ Fpath.v file_name in
         let file_name = Fpath.base @@ Fpath.v file_path in

         (* STEP 0 : Generate AST using Flow library *)
         let ast = Js_parser.from_file file_path in

         (* STEP 1 : Normalize AST *)
         let norm_program = Normalize.program ast file_path in
         let norm_program =
           if file_path = dep_tree.main then Program.set_main norm_program
           else norm_program in
         let js_program = Pp.Js.print norm_program in
         File_system.write_to_file
           Fpath.(to_string @@ (code_dir // file_name))
           js_program;

         (* STEP 2 : Generate MDG for the normalized code *)
         if generate_mdg then (
           let (graph, exportedObject, external_calls) =
             Analyse.program mode verbose config_path norm_program in
           ExternalReferences.iter
             (fun locs info ->
               let l_call = LocationSet.min_elt locs in

               (* module information *)
               let module_name = Fpath.(to_string @@ (dir / info._module)) in
               let moduleEO = Summaries.get_opt summaries module_name in
               Option.iter
                 (fun moduleEO ->
                   let moduleGraph = ModuleGraphs.get module_graphs module_name in

                   (* exported function information *)
                   let func_loc =
                     ExportedObject.get_value_location moduleEO info.properties
                   in
                   ( if not (Mdg.has_external_function graph func_loc) then
                       let func_graph = Mdg.get_function moduleGraph func_loc in
                       Mdg.add_external_func graph func_graph l_call func_loc );

                   Mdg.add_call_edge graph l_call func_loc )
                 moduleEO )
             external_calls;
           (* save current module info*)
           let alter_name = String.sub file_path 0 (String.length file_path - 3) in
           ModuleGraphs.add module_graphs file_path graph;
           ModuleGraphs.add module_graphs alter_name graph;
           Summaries.add summaries file_path exportedObject;
           Summaries.add summaries alter_name exportedObject ) )
       (DependencyTree.bottom_up_visit dep_tree);

     (* output *)
     if generate_mdg then (
       let main = DependencyTree.get_main dep_tree in
       let graph = ModuleGraphs.get module_graphs main in
       if not no_dot then Export.Dot.output (Fpath.to_string graph_dir) graph;
       Export.CSV.output (Fpath.to_string graph_dir) graph );
     Ok 0

   (* setup comand line interface using CMDLiner library*)
   let input_file : string Term.t =
     let doc =
       "Path to JavaScript file (.js) or directory containing JavaScript files \
        for analysis." in
     let docv = "FILE_OR_DIR" in
     Arg.(required & pos 0 (some file) None & info [] ~doc ~docv)

   let mode : Mode.t Term.t =
     let mode_enum =
       Arg.enum
         [ ("basic", Mode.Basic); ("single_file", Mode.Single_file)
         ; ("multi_file", Mode.Multi_file) ] in
     let doc =
       "Analysis mode.\n\
        \t 1) basic: attacker controlls all parameters from all functions \n\
        \t 2) single_file: the attacker controlls the functions that were \
        exported by the input file \n\
        \t 3) multi_file: the attacker controlls the functions that were exported \
        in the \"main\" file" in
     Arg.(value & opt mode_enum Mode.single_file & info [ "m"; "mode" ] ~doc)

   let mdg : bool Term.t =
     let doc = "Generates Multiversion Dependency Mdg." in
     Arg.(value & flag & info [ "mdg" ] ~doc)

   let no_dot : bool Term.t =
     let doc = "Dont generate .dot and .svg graph representation." in
     Arg.(value & flag & info [ "noDot" ] ~doc)

   let fpath = ((fun str -> `Ok (Fpath.v str)), Fpath.pp)

   let output_path : Fpath.t Term.t =
     let doc = "Path to store all output files." in
     let default_path = Fpath.v "graphjs-results" in
     Arg.(value & opt fpath default_path & info [ "o"; "output" ] ~doc)

   let config_path : string Term.t =
     let doc = "Path to configuration file." in
     let default_path = Fpath.to_string @@ Share.Config.default () in
     Arg.(value & opt non_dir_file default_path & info [ "c"; "config" ] ~doc)

   let verbose : bool Term.t =
     let doc = "Verbose mode." in
     Arg.(value & flag & info [ "v"; "verbose" ] ~doc)

   let cli =
     let cmd =
       Term.(
         const main
         $ input_file
         $ output_path
         $ config_path
         $ mode
         $ mdg
         $ no_dot
         $ verbose ) in
     let info = Cmd.info "graphjs2" in
     Cmd.v info cmd

   let () =
     match Cmd.eval_value' cli with
     | `Exit code -> exit code
     | `Ok return -> (
       match return with Error err -> Log.fail "%s" err | Ok code -> exit code ) *)

open Graphjs_base
open Graphjs_client
open Cmdliner

type status = (unit Exec.status Cmd.eval_ok, Cmd.eval_error) Result.t

let set_copts (lvl : Enums.DebugLvl.t) (colorless : bool) : unit =
  Font.Config.(colored $= not colorless);
  Log.Config.(log_warns $= (lvl >= Warn));
  Log.Config.(log_debugs $= (lvl >= Full))

let copts : unit Term.t =
  let open Term in
  const set_copts $ Docs.CommonOpts.debug $ Docs.CommonOpts.colorless

let normalize_opts : Cmd_normalize.Options.t Term.t =
  let open Term in
  const Cmd_normalize.Options.set
  $ Docs.NormalizeOpts.input
  $ Docs.NormalizeOpts.output

let normalize_cmd : unit Exec.status Cmd.t =
  let open Docs.NormalizeCmd in
  let info = Cmd.info name ~sdocs ~doc ~man ~man_xrefs ~exits in
  Cmd.v info Term.(const Cmd_normalize.run $ copts $ normalize_opts)

let cmd_list : unit Exec.status Cmd.t list = [ normalize_cmd ]

let main_cmd : unit Exec.status Cmd.t =
  let open Docs.Application in
  let default = Term.(ret (const (fun _ -> `Help (`Pager, None)) $ copts)) in
  let info = Cmd.info name ~sdocs ~doc ~version ~man ~man_xrefs ~exits in
  Cmd.group info ~default cmd_list

let eval_cmd : status -> int = function
  | Ok (`Help | `Version) -> Docs.ExitCodes.ok
  | Ok (`Ok (Ok ())) -> Docs.ExitCodes.ok
  | Ok (`Ok (Error `ParseJS)) -> Docs.ExitCodes.parse
  | Ok (`Ok (Error (`Generic _))) -> Docs.ExitCodes.generic
  | Error `Term -> Docs.ExitCodes.term
  | Error `Parse -> Docs.ExitCodes.client
  | Error `Exn -> Docs.ExitCodes.internal

let () =
  Printexc.record_backtrace true;
  try Cmdliner.Cmd.eval_value main_cmd |> eval_cmd |> exit
  with exn ->
    flush_all ();
    Log.fail "[graphjs] uncaught exception %s@." (Printexc.to_string exn);
    Printexc.print_backtrace stderr;
    exit Docs.ExitCodes.internal
