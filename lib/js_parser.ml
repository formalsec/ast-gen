let from_file (filename : string) :
    ((Loc.t, Loc.t) Flow_ast.Program.t, string) Result.t =
  In_channel.with_open_text filename (fun in_chan ->
      let program_text = In_channel.input_all in_chan in
      let ast, errors = Parser_flow.program program_text in
      match errors with
      | [] -> Ok ast
      | _ ->
          List.iter
            (fun (loc, err) ->
              let err = Parse_error.PP.error err in
              Format.eprintf "%a: error: %s" Loc.pp loc err)
            errors;
          Error "TODO: display parsing errors")
