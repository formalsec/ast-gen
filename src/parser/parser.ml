open Graphjs_base

module Config = struct
  include Config

  let loc_font : Font.t t = constant (Font.create ~fg:`DarkGray ~italic:true ())
end

exception Error of (Fmt.t -> unit)

open struct
  let pp_msg (ppf : Fmt.t) (filename : string) : unit =
    Log.fmt_error ppf "Flow was unable to parse the file %S.@\n" filename

  let pp_loc (ppf : Fmt.t) ((filename, loc) : string * Loc.t) : unit =
    let font = Config.(!loc_font) in
    Font.fmt font ppf "File %S, line %d, characters %d-%d" filename
      loc.start.line loc.start.column loc._end.column

  let pp_err (filename : string) (ppf : Fmt.t)
      ((loc, err) : Loc.t * Parse_error.t) : unit =
    Fmt.fmt ppf "%s@\n%a" (Parse_error.PP.error err) pp_loc (filename, loc)

  let raise_parsing_error (filename : string)
      (flow_errors : (Loc.t * Parse_error.t) list) : 'a =
    let pp_errs = Fmt.(pp_lst !>"@\n" (pp_err filename)) in
    let err = Fmt.dly "%a%a" pp_msg filename pp_errs flow_errors in
    raise (Error err)
end

open struct
  let parse_file (filename : string) (ic : in_channel) :
      (Loc.t, Loc.t) Flow_ast.Program.t =
    let ic_sz = in_channel_length ic in
    let prog_text = really_input_string ic ic_sz in
    let (flow_ast, flow_errors) = Parser_flow.program ~fail:false prog_text in
    match flow_errors with
    | [] -> flow_ast
    | _ -> raise_parsing_error filename flow_errors
end

let parse (filename : string) : (Loc.t, Loc.t) Flow_ast.Program.t =
  let ic = open_in filename in
  let parse_f () = parse_file filename ic in
  let finally () = close_in_noerr ic in
  Fun.protect ~finally parse_f
