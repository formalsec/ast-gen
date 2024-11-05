open Cmdliner
open Setup
module Graph = Mdg.Graph'
module ExportedObject = Mdg.ExportedObject
module ExternalReferences = Mdg.ExternalReferences
module LocationSet = Mdg.Structures.LocationSet
module Mode = Auxiliary.Mode
module Program = Ast.Grammar.Program
open Auxiliary.Functions

(* Monadic let binding for result *)
let ( let* ) = Result.bind

let setup_output output_path =
  let open Bos in
  let code_dir = Fpath.(output_path / "code") in
  let graph_dir = Fpath.(output_path / "graph") in
  let run_dir = Fpath.(output_path / "run") in
  let* () = OS.Dir.delete ~recurse:true output_path in
  let* _ = OS.Dir.create ~path:true code_dir in
  let* _ = OS.Dir.create ~path:true graph_dir in
  let* _ = OS.Dir.create ~path:true run_dir in
  Ok (code_dir, graph_dir, run_dir)

(* TODO: Use Fpath everywhere *)
let main file_name output_path config_path mode generate_mdg run_queries no_dot
  verbose =
  (* DANGEROUS: We create "run" but don't pass it to any function?
     Is there any global behaviour that will write to "run"? *)
  let* code_dir, graph_dir, run_dir = setup_output output_path in
  let* dep_tree = DependencyTree.generate file_name mode in

  (* process dependencies first with the aid of the depedency tree *)
  let summaries = Summaries.empty () in
  let module_graphs = ModuleGraphs.empty () in
  
  let start = Sys.time () in 
  List.iter
    (fun file_path ->
      let dir = Fpath.append (Fpath.v (Unix.getcwd ())) @@ Fpath.parent @@ Fpath.v file_path in
      let file_name = Fpath.base @@ Fpath.v file_path in

      print_endline ("[STEP 1] Normalizing " ^ Fpath.to_string file_name ^ " code...");

      (* STEP 0 : Generate AST using Flow library *)
      let ast = Js_parser.from_file file_path in

      (* STEP 1 : Normalize AST *)
      let norm_program = Ast.Normalize.program ast file_path in

      let norm_program =
        if file_path = dep_tree.main then Program.set_main norm_program
        else norm_program
      in
      let js_program = Ast.Pp.Js.print norm_program in
      File_system.write_to_file
        Fpath.(to_string @@ (code_dir // file_name))
        js_program;

      (* STEP 2 : Generate MDG for the normalized code *)
      if generate_mdg then (
        print_endline "[STEP 2] Generating MDG...";
        let graph, exportedObject, external_calls =
          Mdg.Analyse.program mode verbose config_path norm_program
        in
        ExternalReferences.iter
          (fun locs info ->
            let l_call = LocationSet.min_elt locs in

            (* module information *)
            let module_name = Fpath.(to_string @@ (dir // (v info._module))) in
            let moduleEO = Summaries.get_opt summaries module_name in
            option_may
              (fun moduleEO ->
                let moduleGraph = ModuleGraphs.get module_graphs module_name in

                (* exported function information *)
                let func_loc =
                  ExportedObject.get_value_location moduleEO info.properties
                in
                ( if not (Graph.has_external_function graph func_loc) then
                    let func_graph = Graph.get_function moduleGraph func_loc in
                    Graph.add_external_func graph func_graph l_call func_loc );

                Graph.add_call_edge graph l_call func_loc )
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
    let mdg_end = (Sys.time () -. start) *. 1000.0 in 
    let main = DependencyTree.get_main dep_tree in
    let graph = ModuleGraphs.get module_graphs main in
    if not no_dot then Mdg.Pp.Dot.output graph_dir graph;
    Mdg.Pp.CSV.output graph_dir graph;
    Mdg.Pp.Time.output run_dir mdg_end;

    (* run queries *)
    if run_queries then
      let config = Config.read config_path in
      print_endline ("[STEP 3] Running queries...");
      Queries.run_queries Format.std_formatter graph config output_path);

  Ok 0

let read_inputs dir =
  let fold_f fpath acc = fpath :: acc in
  let* files =
    Bos.OS.Dir.fold_contents ~elements:`Files ~traverse:`Any fold_f [] dir
  in
  Ok
    ( List.filter (Fpath.has_ext "js") files
    |> List.map (fun f -> (Fpath.parent f, f)) )

let queries input_dir config_path mode =
  let* inputs = read_inputs (Fpath.v input_dir) in
  ignore
    (List.map
       (fun (dir, input) ->
         try
           let file_name = Fpath.to_string input in
           let name = Fpath.basename input in
           let output = Fpath.((dir / name) + "out") in
           let* dep_tree = DependencyTree.generate file_name mode in
           let summaries = Summaries.empty () in
           let module_graphs = ModuleGraphs.empty () in
           List.iter
             (fun file_path ->
               let ast = Js_parser.from_file file_path in
               let norm_program = Ast.Normalize.program ast file_path in
               let norm_program =
                 if file_path = dep_tree.main then Program.set_main norm_program
                 else norm_program
               in
               (* STEP 2 : Generate MDG for the normalized code *)
               let graph, exportedObject, external_calls =
                 Mdg.Analyse.program mode false config_path norm_program
               in
               ExternalReferences.iter
                 (fun locs info ->
                   let l_call = LocationSet.min_elt locs in
                   let module_name =
                     Fpath.(to_string @@ (dir / info._module))
                   in
                   let moduleEO = Summaries.get_opt summaries module_name in
                   option_may
                     (fun moduleEO ->
                       let moduleGraph =
                         ModuleGraphs.get module_graphs module_name
                       in
                       let func_loc =
                         ExportedObject.get_value_location moduleEO
                           info.properties
                       in
                       ( if not (Graph.has_external_function graph func_loc) then
                           let func_graph =
                             Graph.get_function moduleGraph func_loc
                           in
                           Graph.add_external_func graph func_graph l_call
                             func_loc );
                       Graph.add_call_edge graph l_call func_loc )
                     moduleEO )
                 external_calls;
               let alter_name =
                 String.sub file_path 0 (String.length file_path - 3)
               in
               ModuleGraphs.add module_graphs file_path graph;
               ModuleGraphs.add module_graphs alter_name graph;
               Summaries.add summaries file_path exportedObject;
               Summaries.add summaries alter_name exportedObject )
             (DependencyTree.bottom_up_visit dep_tree);

           (* let main = DependencyTree.get_main dep_tree in
           let graph = ModuleGraphs.get module_graphs main in
           let exportedObject = Summaries.get summaries main in
           let config = Config.read config_path in *)
           let oc = open_out (Fpath.to_string output) in
           (* let ppf = Format.formatter_of_out_channel oc in *)
           (* Queries.run_queries ppf graph exportedObject config; *)
           close_out oc;
           Ok 0
         with _ ->
           Format.eprintf "input = %a@\n@." Fpath.pp input;
           Printexc.print_backtrace stderr;
           Ok 1 )
       inputs );
  Ok 0

(* setup comand line interface using CMDLiner library*)
let input_file : string Term.t =
  let doc =
    "Path to JavaScript file (.js) or directory containing JavaScript files \
     for analysis."
  in
  let docv = "FILE_OR_DIR" in
  Arg.(required & pos 0 (some file) None & info [] ~doc ~docv)

let input_dir : string Term.t =
  let doc = "Path to JavaScript tests." in
  let docv = "DIR" in
  Arg.(required & pos 0 (some dir) None & info [] ~doc ~docv)

let mode : Mode.t Term.t =
  let mode_enum =
    Arg.enum
      [ ("basic", Mode.Basic)
      ; ("single_file", Mode.Single_file)
      ; ("multi_file", Mode.Multi_file)
      ]
  in
  let doc =
    "Analysis mode.\n\
     \t 1) basic: attacker controlls all parameters from all functions \n\
     \t 2) single_file: the attacker controlls the functions that were \
     exported by the input file \n\
     \t 3) multi_file: the attacker controlls the functions that were exported \
     in the \"main\" file"
  in
  Arg.(value & opt mode_enum Mode.single_file & info [ "m"; "mode" ] ~doc)

let mdg : bool Term.t =
  let doc = "Generates Multiversion Dependency Graph." in
  Arg.(value & flag & info [ "mdg" ] ~doc)

let run_queries : bool Term.t =
  let doc = "..." in
  Arg.(value & flag & info [ "q"; "queries" ] ~doc)

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
  let default_path = Fpath.to_string @@ Auxiliary.Share.Config.default () in
  Arg.(value & opt non_dir_file default_path & info [ "c"; "config" ] ~doc)

let verbose : bool Term.t =
  let doc = "Verbose mode." in
  Arg.(value & flag & info [ "v"; "verbose" ] ~doc)

let cli =
  let queries_info = Cmd.info "queries" in
  let queries = Term.(const queries $ input_dir $ config_path $ mode) in
  let main_info = Cmd.info "run" in
  let main =
    Term.(
      const main $ input_file $ output_path $ config_path $ mode $ mdg
      $ run_queries $ no_dot $ verbose )
  in
  let info = Cmd.info "graphjs2" in
  Cmd.group ~default:main info
    [ Cmd.v main_info main; Cmd.v queries_info queries ]

let () =
  match Cmd.eval_value' cli with
  | `Exit code -> exit code
  | `Ok return -> (
    match return with
    | Error (`Msg err) -> Fmt.failwith "%s" err
    | Ok code -> exit code )
