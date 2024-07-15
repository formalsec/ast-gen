open Cmdliner

let rec main (filename : string) (output_path : string) (config_path : string) (_multifile : bool) (generate_mdg : bool) (verbose : bool) : int =
  let filename = Auxiliary.File_system.real_path filename in 
  (* STEP 0 : Generate AST using Flow library *)
  match Auxiliary.Js_parser.from_file filename with
  | Ok ast ->
      (* create output fs structure *)
      let code_dir, graph_dir, _ = setup_output output_path in 

      (* STEP 1 : Normalize AST *)
      let norm_program = Ast.Normalize.program ast filename in
      let js_program = Ast.Pp.Js.print norm_program in
      Auxiliary.File_system.write_to_file (code_dir ^ "normalized.js") js_program;

      (* STEP 2 : Generate MDG for the normalized code *)
      if generate_mdg then (
        let config = Mdg.Config.read config_path in 
        let graph = Mdg.Analyse.program verbose config norm_program in
        Mdg.Pp.Dot.output graph_dir graph;
        Mdg.Pp.CSV.output graph_dir graph
      );

      0
  | Error msg ->
      Format.eprintf "%s@." msg;
      1

and setup_output (output_path : string) : (string * string * string) = 
  let code_dir = output_path  ^ "/code/" in 
  let graph_dir = output_path ^ "/graph/" in 
  let run_dir   = output_path ^ "/run/" in
  Auxiliary.File_system.create_dir code_dir;
  Auxiliary.File_system.create_dir graph_dir;
  Auxiliary.File_system.create_dir run_dir;
  
  code_dir, graph_dir, run_dir



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
  let default_path = "config.json" in 
  Arg.(value & opt non_dir_file default_path & info ["c"; "config"] ~doc)

let verbose : bool Term.t =
  let doc = "Verbose mode." in
  Arg.(value & flag & info ["v"; "verbose"] ~doc)

let cli =
  let cmd = Term.(const main $ input_file $ output_path $ config_path $ multifile $ mdg $ verbose) in
  let info = Cmd.info "ast_gen" in
  Cmd.v info cmd

let () = exit (Cmd.eval' cli)
