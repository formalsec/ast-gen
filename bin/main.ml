open Cmdliner
open Setup
module Graph = Mdg.Graph'
module ExportedObject = Mdg.ExportedObject
module ExternalReferences = Mdg.ExternalReferences
module LocationSet = Mdg.Structures.LocationSet
module Mode = Auxiliary.Mode
module Program = Ast.Grammar.Program
open Auxiliary.Functions

let env_path = Filename.dirname (Filename.dirname Sys.executable_name) ^ "/lib/ast_gen/";;

let setup_output (output_path : string) : (string * string * string) = 
  let code_dir = output_path  ^ "/code/" in 
  let graph_dir = output_path ^ "/graph/" in 
  let run_dir   = output_path ^ "/run/" in

  File_system.clean_dir output_path;
  File_system.create_dir code_dir;
  File_system.create_dir graph_dir;
  File_system.create_dir run_dir;
  
  code_dir, graph_dir, run_dir

let setup_node (mode : string) : string = 
  (* !REFACTOR : inbed this functionality into the dune build and install process *)
  let js_folder    = env_path ^ "js/" in 
  let node_modules = js_folder ^ "node_modules" in 
  let package_info = js_folder ^ "package.json" in 
  let script       = js_folder ^ "generate_cg.js" in 

  if not (Sys.file_exists script)
    then failwith "[ERROR] Dependency tree genetarion script not found";

  if not (Sys.file_exists package_info)
    then failwith "[ERROR] Package.json not found";

  if Mode.is_multi_file mode && not (Sys.file_exists node_modules)
    then (
      print_endline "installing js dependencies";
      let result = Sys.command ("npm install --prefix " ^ js_folder) in 
      if result != 0 then failwith "[ERROR] Unable to install js depedencies";
      print_endline "DONE!");

  script


let main (filename : string) (output_path : string) (config_path : string) (mode : string) (generate_mdg : bool) (verbose : bool) : int =
  
  (* SETUP *)
  let script = setup_node mode in
  let dep_tree = DependencyTree.generate script filename mode in  
  let code_dir, graph_dir, _ = setup_output output_path in 

  (* process dependencies first with the aid of the depedency tree *)
  let summaries = Summaries.empty () in 
  let module_graphs = ModuleGraphs.empty () in 
  List.iter (fun file_path -> 
    let dir = Filename.dirname file_path ^ "/" in 
    let filename = File_system.file_name file_path in 

    (* STEP 0 : Generate AST using Flow library *)
    let ast = Js_parser.from_file file_path in 

    (* STEP 1 : Normalize AST *)
    let norm_program = Ast.Normalize.program ast file_path in
    let norm_program = if file_path = dep_tree.main then Program.set_main norm_program else norm_program in 
    let js_program = Ast.Pp.Js.print norm_program in
    File_system.write_to_file (code_dir ^ filename) js_program;

    (* STEP 2 : Generate MDG for the normalized code *)
    if generate_mdg then (
      let graph, exportedObject, external_calls = Mdg.Analyse.program mode verbose config_path norm_program in
    
      ExternalReferences.iter (fun locs info ->
        let l_call = LocationSet.min_elt locs in
        
        (* module information *) 
        let module_name = dir ^ info._module in 
        let moduleEO = Summaries.get_opt summaries module_name in 
        option_may (fun moduleEO ->
          let moduleGraph = ModuleGraphs.get module_graphs module_name in 
          
          (* exported function information *)
          let func_loc = ExportedObject.get_value_location moduleEO info.properties in 
          if not (Graph.has_external_function graph func_loc) then (
            let func_graph = Graph.get_function moduleGraph func_loc in 
            Graph.add_external_func graph func_graph l_call func_loc
          );
          
          Graph.add_call_edge graph l_call func_loc;
        ) moduleEO;

      ) external_calls;
      
      (* save current module info*)
      let alter_name = String.sub file_path 0 (String.length file_path - 3) in 
      ModuleGraphs.add module_graphs file_path graph;
      ModuleGraphs.add module_graphs alter_name graph;
      Summaries.add summaries file_path exportedObject;
      Summaries.add summaries alter_name exportedObject;
    );

  ) (DependencyTree.bottom_up_visit dep_tree);

  (* output *)
  if generate_mdg then (
    let main = DependencyTree.get_main dep_tree in 
    let graph = ModuleGraphs.get module_graphs main in 
    Mdg.Pp.Dot.output graph_dir graph;
    Mdg.Pp.CSV.output graph_dir graph;
  );

  0

(* setup comand line interface using CMDLiner library*)
let input_file : string Term.t =
  let doc = "Path to JavaScript file (.js) or directory containing JavaScript files for analysis." in
  let docv = "FILE_OR_DIR" in
  let is_dir_or_file (param : string) : string =  
    if Sys.file_exists param 
      then param
      else failwith ("[ERROR] Invalid input file : " ^ param) 
  in 

  Term.(const is_dir_or_file $  Arg.(required & pos 0 (some string) None & info [] ~doc ~docv))


let mode : string Term.t =
  let doc = "Analysis mode.\n\t 1) basic: attacker controlls all parameters from all functions \n\t 2) single_file: the attacker controlls the functions that were exported by the input file \n\t 3) multi_file: the attacker controlls the functions that were exported in the \"main\" file" in
  Term.(const Mode.is_valid $ Arg.(value & opt string Mode.default & info ["m"; "mode"] ~doc))

let mdg : bool Term.t =
  let doc = "Generates Multiversion Dependency Graph." in
  Arg.(value & flag & info ["mdg"] ~doc)

let output_path : string Term.t =
  let doc = "Path to store all output files." in
  let default_path = "graphjs-results" in 
  Arg.(value & opt string default_path & info ["o"; "output"] ~doc)

let config_path : string Term.t =
  let doc = "Path to configuration file." in
  let default_path = env_path ^ "config.json" in 
  Arg.(value & opt non_dir_file default_path & info ["c"; "config"] ~doc)

let verbose : bool Term.t =
  let doc = "Verbose mode." in
  Arg.(value & flag & info ["v"; "verbose"] ~doc)

let cli =
  let cmd = Term.(const main $ input_file $ output_path $ config_path $ mode $ mdg $ verbose) in
  let info = Cmd.info "ast_gen" in
  Cmd.v info cmd

let () = exit (Cmd.eval' cli)
