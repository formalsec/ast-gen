open Cmdliner

let main (filename : string) (verbose : bool) (generate_mdg : bool) : int =
  match Auxiliary.Js_parser.from_file filename with
  | Ok ast ->
      let norm_program = Normalizer.Normalize.program ast in
      if generate_mdg then (
        let graph, store = Mdg.Analyse.program verbose norm_program in 

        print_endline "Graph\n-----";
        Mdg.Graph.print graph;

        print_endline "Store\n-----";
        Mdg.Store.print store; 
        
        print_endline "Code\n-----"
      );

      let js_program = Pp.Js.print norm_program in
      print_endline js_program;
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

let cli =
  let cmd = Term.(const main $ input_file $ verbose $ mdg) in
  let info = Cmd.info "ast_gen" in
  Cmd.v info cmd

let () = exit (Cmd.eval' cli)
