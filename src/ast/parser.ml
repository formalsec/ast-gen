open Graphjs_base

module Config = struct
  include Config

  let loc_font : Font.t t = constant (Font.create ~fg:`DarkGray ~italic:true ())
end

exception Error

open struct
  let log_loc (ppf : Fmt.t) ((filename, loc) : string * Loc.t) : unit =
    Fmt.fmt ppf "File %S, line %d, characters %d-%d" filename loc.start.line
      loc.start.column loc._end.column

  let log_err (filename : string) ((loc, err) : Loc.t * Parse_error.t) : unit =
    let loc_pp = Font.pp Config.(!loc_font) log_loc in
    Log.app "%s@\n%a" (Parse_error.PP.error err) loc_pp (filename, loc)

  let parsing_error (filename : string)
      (flow_errors : (Loc.t * Parse_error.t) list) : 'a =
    Log.error "Flow was unable to parse the file %S." filename;
    List.iter (log_err filename) flow_errors;
    raise Error

  let parse_file (filename : string) (ic : in_channel) :
      (Loc.t, Loc.t) Flow_ast.Program.t =
    let ic_sz = in_channel_length ic in
    let prog_text = really_input_string ic ic_sz in
    let (flow_ast, flow_errors) = Parser_flow.program ~fail:false prog_text in
    match flow_errors with
    | [] -> flow_ast
    | _ -> parsing_error filename flow_errors
end

let parse (fname : string) : (Loc.t, Loc.t) Flow_ast.Program.t =
  let ic = open_in fname in
  let parse_f () = parse_file fname ic in
  let finally () = close_in_noerr ic in
  Fun.protect ~finally parse_f
