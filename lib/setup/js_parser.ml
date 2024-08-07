(* read javascript code and generate ast with flow library *)
let from_file (filename : string) : (Loc.t, Loc.t) Flow_ast.Program.t =
  In_channel.with_open_text filename (
    fun in_chan ->
      let program_text = In_channel.input_all in_chan in
      let ast, errors = Parser_flow.program program_text in
      match errors with
        | [] -> ast
        | _ -> List.iter (fun (loc, err) ->
                let err = Parse_error.PP.error err in
                Format.printf "%a: error: %s" Loc.pp loc err
              ) errors; 
              failwith ("[ERROR] Flow failed to process file : " ^ filename)
    )
