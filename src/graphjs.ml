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
   let mdg : bool Term.t =
     let doc = "Generates Multiversion Dependency Mdg." in
     Arg.(value & flag & info [ "mdg" ] ~doc)

   let no_dot : bool Term.t =
     let doc = "Dont generate .dot and .svg graph representation." in
     Arg.(value & flag & info [ "noDot" ] ~doc)

   let fpath = ((fun str -> `Ok (Fpath.v str)), Fpath.pp)

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

let set_copts (colorless : bool) (lvl : Enums.DebugLvl.t) (verbose : bool) :
    unit =
  Font.Config.(colored $= not colorless);
  Log.Config.(log_warns $= (lvl >= Warn));
  Log.Config.(log_infos $= (lvl >= Info));
  Log.Config.(log_debugs $= (lvl >= Full));
  Log.Config.(log_verbose $= verbose)

let copts : unit Term.t =
  let open Term in
  const set_copts
  $ Docs.CommonOpts.colorless
  $ Docs.CommonOpts.debug
  $ Docs.CommonOpts.verbose

let set_shared_opts (mode' : Enums.AnalysisMode.t) () : unit =
  let open Graphjs_shared in
  Shared_config.(mode $= Enums.AnalysisMode.conv mode')

let shared_opts : unit Term.t =
  Term.(const set_shared_opts $ Docs.SharedOpts.mode $ copts)

let parse_opts : unit Term.t =
  Term.(const Cmd_parse.Options.set $ Docs.ParseOpts.test262_conform_hoisted)

let parse_cmd_opts : Cmd_parse.Options.t Term.t =
  let open Term in
  const Cmd_parse.Options.set_cmd
  $ Docs.FileOpts.input
  $ Docs.FileOpts.output
  $ parse_opts

let parse_cmd : unit Exec.status Cmd.t =
  let open Docs.ParseCmd in
  let info = Cmd.info name ~sdocs ~doc ~man ~man_xrefs ~exits in
  Cmd.v info Term.(const Cmd_parse.run $ parse_cmd_opts $ shared_opts)

(* let mdg_opts : unit Term.t =
   Term.(const Cmd_mdg.Options.set) *)

let mdg_cmd_opts : Cmd_mdg.Options.t Term.t =
  let open Term in
  const Cmd_mdg.Options.set_cmd
  $ Docs.FileOpts.input
  $ Docs.FileOpts.output
  $ Docs.MdgOpts.config
(* $ mdg_opts *)

let mdg_cmd : unit Exec.status Cmd.t =
  let open Docs.MdgCmd in
  let info = Cmd.info name ~sdocs ~doc ~man ~man_xrefs ~exits in
  Cmd.v info Term.(const Cmd_mdg.run $ mdg_cmd_opts $ shared_opts)

let cmd_list : unit Exec.status Cmd.t list = [ parse_cmd; mdg_cmd ]

let main_cmd : unit Exec.status Cmd.t =
  let open Docs.Application in
  let default = Term.(ret (const (fun _ -> `Help (`Pager, None)) $ copts)) in
  let info = Cmd.info name ~sdocs ~doc ~version ~man ~man_xrefs ~exits in
  Cmd.group info ~default cmd_list

let eval_cmd : status -> int = function
  | Ok (`Help | `Version) -> Docs.ExitCodes.ok
  | Ok (`Ok (Ok ())) -> Docs.ExitCodes.ok
  | Ok (`Ok (Error (`DepTree _))) -> Docs.ExitCodes.deptree
  | Ok (`Ok (Error (`ParseJS _))) -> Docs.ExitCodes.parsejs
  | Ok (`Ok (Error (`Generic _))) -> Docs.ExitCodes.generic
  | Error `Term -> Docs.ExitCodes.term
  | Error `Parse -> Docs.ExitCodes.client
  | Error `Exn -> Docs.ExitCodes.internal

let () =
  Printexc.record_backtrace true;
  try Cmdliner.Cmd.eval_value main_cmd |> eval_cmd |> exit
  with exn ->
    flush_all ();
    Log.stderr "[graphjs] uncaught exception %s@." (Printexc.to_string exn);
    Printexc.print_backtrace stderr;
    exit Docs.ExitCodes.internal
