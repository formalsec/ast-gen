let from_file (filename : string) : (Loc.t, Loc.t) Flow_ast.Program.t =
  let print_err (loc, err) =
    Format.printf "%a: error: %s" Loc.pp loc (Parse_error.PP.error err) in
  In_channel.with_open_text filename @@ fun ic ->
  let program_text = In_channel.input_all ic in
  let (ast, errors) = Parser_flow.program program_text in
  match errors with
  | [] -> ast
  | _ ->
    List.iter print_err errors;
    failwith ("[ERROR] Flow failed to process file: " ^ filename)
