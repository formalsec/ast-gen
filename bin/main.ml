open Cmdliner

let main (filename : string) (output_path : string) (verbose : bool) (generate_mdg : bool) : int =
  (* STEP 0 : Generate AST using Flow library *)
  match Auxiliary.Js_parser.from_file filename with
  | Ok ast ->
      (* create output fs structure *)
      let graph_dir = output_path ^ "/graph/" in 
      let run_dir   = output_path ^ "/run/" in
      Auxiliary.File_system.create_dir graph_dir;
      Auxiliary.File_system.create_dir run_dir;

      (* STEP 1 : Normalize AST *)
      let norm_program = Ast.Normalize.program ast in
      let js_program = Ast.Pp.Js.print norm_program in
      Auxiliary.File_system.write_to_file (graph_dir ^ "normalized.js") js_program;

      (* STEP 2 : Generate MDG for the normalized code *)
      if generate_mdg then (
        let graph, _ = Mdg.Analyse.program verbose norm_program in
        Mdg.Pp.Dot.output (graph_dir ^ "graph") graph
      );

      0
  | Error msg ->
      Format.eprintf "%s@." msg;
      1



(* setup comand line interface using CMDLiner library*)
let input_file : string Term.t =
  let doc = "" in
  let docv = "FILE" in
  Arg.(required & pos 0 (some non_dir_file) None & info [] ~doc ~docv)

let verbose : bool Term.t =
  let doc = "Enable verbose mode" in
  Arg.(value & flag & info ["v"; "verbose"] ~doc)

let mdg : bool Term.t =
  let doc = "Generate mdg" in
  Arg.(value & flag & info ["mdg"] ~doc)

let output_path : string Term.t =
  let doc = "Output folder path" in
  let default_path = "graphjs-results" in 
  Arg.(value & opt string default_path & info ["o"] ~doc)

let cli =
  let cmd = Term.(const main $ input_file $ output_path $ verbose $ mdg) in
  let info = Cmd.info "ast_gen" in
  Cmd.v info cmd

let () = exit (Cmd.eval' cli)
