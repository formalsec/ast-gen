open Cmdliner
open Setup
open Auxiliary.Structures
module Graph = Mdg.Graph'
module ExportedObject = Mdg.ExportedObject

let env_path = Filename.dirname (Filename.dirname Sys.executable_name) ^ "/lib/ast_gen/";;

(* some useful structures *)
type module_graphs = Graph.t HashTable.t
let empty_module_graphs () : module_graphs = HashTable.create 10
let add_graph : module_graphs -> string -> Graph.t -> unit = HashTable.add
let get_graph : module_graphs -> string -> Graph.t = HashTable.find

type summaries = ExportedObject.t HashTable.t
let empty_summaries () : summaries = HashTable.create 10
let add_summary : summaries -> string -> ExportedObject.t -> unit = HashTable.add

let setup_output (output_path : string) : (string * string * string) = 
  let code_dir = output_path  ^ "/code/" in 
  let graph_dir = output_path ^ "/graph/" in 
  let run_dir   = output_path ^ "/run/" in

  File_system.clean_dir output_path;
  File_system.create_dir code_dir;
  File_system.create_dir graph_dir;
  File_system.create_dir run_dir;
  
  code_dir, graph_dir, run_dir

let setup_node (multifile : bool) : string = 
  (* !REFACTOR : inbed this functionality into the dune build and install process *)
  let js_folder    = env_path ^ "js/" in 
  let node_modules = js_folder ^ "node_modules" in 
  let package_info = js_folder ^ "package.json" in 
  let script       = js_folder ^ "generate_cg.js" in 

  if not (Sys.file_exists script)
    then failwith "dependency tree genetarion script not found";

  if not (Sys.file_exists package_info)
    then failwith "package.json not found";

  if multifile && not (Sys.file_exists node_modules)
    then (
      print_endline "installing js dependencies";
      let result = Sys.command ("npm install --prefix " ^ js_folder) in 
      if result != 0 then failwith "error installing js depedencies";
      print_endline "DONE!");

  script


let main (filename : string) (output_path : string) (config_path : string) (multifile : bool) (generate_mdg : bool) (verbose : bool) : int =
  
  (* SETUP *)
  let script = setup_node multifile in
  let dep_tree = DependencyTree.generate script filename multifile in  
  let code_dir, graph_dir, _ = setup_output output_path in 

  (* process dependencies first with the aid of the depedency tree *)
  let summaries = empty_summaries () in 
  let module_graphs = empty_module_graphs () in 
  List.iter (fun file_path -> 
    let filename = File_system.file_name file_path in 

    (* STEP 0 : Generate AST using Flow library *)
    let ast = Js_parser.from_file file_path in 

    (* STEP 1 : Normalize AST *)
    let norm_program = Ast.Normalize.program ast file_path in
    let js_program = Ast.Pp.Js.print norm_program in
    File_system.write_to_file (code_dir ^ filename) js_program;

    (* STEP 2 : Generate MDG for the normalized code *)
    if generate_mdg then (
      let graph, exportedObject = Mdg.Analyse.program verbose config_path norm_program in
      (* 
      TODO : .
      Graph.iter_external_calls (
        fun call -> 
          let _module = call._module in 
          let func = get_func (get_summary summaries _module) call.func in
          let func_graph = Graph.get_func_graph (get_graph module_graphs _module) func in
          Graph.add_external_func graph func_graph; 
      ) graph; *)

      add_graph module_graphs file_path graph;
      add_summary summaries file_path exportedObject; (* TODO *)
      
      print_endline file_path;
      ExportedObject.print exportedObject;
      print_newline ();
    );

  ) (DependencyTree.bottom_up_visit dep_tree);

  (* output *)
  if generate_mdg then (
    let main = DependencyTree.get_main dep_tree in 
    let graph = get_graph module_graphs main in 
    Mdg.Pp.Dot.output graph_dir graph;
    Mdg.Pp.CSV.output graph_dir graph
  );

  0

(* setup comand line interface using CMDLiner library*)
let input_file : string Term.t =
  let doc = "Path to JavaScript file (.js) or directory containing JavaScript files for analysis." in
  let docv = "FILE" in
  Arg.(required & pos 0 (some non_dir_file) None & info [] ~doc ~docv)

let multifile : bool Term.t =
  let doc = "Analysis of a file and its dependencies instead of a single file." in
  Arg.(value & flag & info ["m"; "multifile"] ~doc)

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
  let cmd = Term.(const main $ input_file $ output_path $ config_path $ multifile $ mdg $ verbose) in
  let info = Cmd.info "ast_gen" in
  Cmd.v info cmd

let () = exit (Cmd.eval' cli)
