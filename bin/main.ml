open Ast_gen
open Cmdliner

let main (filename : string) : int =
  match Js_parser.from_file filename with
  | Ok ast ->
      let ast' = Test.program ast in
      let json_ast = Json_translator.program None ast' in
      Format.printf "Js ast:@\n %a@." (Yojson.pretty_print ~std:true) json_ast;
      0
  | Error msg ->
      Format.eprintf "%s@." msg;
      1

let input_file : string Term.t =
  let doc = "" in
  let docv = "FILE" in
  Arg.(required & pos 0 (some non_dir_file) None & info [] ~doc ~docv)

let cli =
  let cmd = Term.(const main $ input_file) in
  let info = Cmd.info "ast_gen" in
  Cmd.v info cmd

let () = exit (Cmd.eval' cli)
