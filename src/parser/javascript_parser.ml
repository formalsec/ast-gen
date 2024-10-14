open Graphjs_base

exception Exn of (Fmt.t -> unit)

module Config = struct
  include Config

  let loc_font : Font.t t = constant (Font.create ~fg:`DarkGray ~italic:true ())
end

open struct
  let pp_err (ppf : Fmt.t) (path : string) : unit =
    Log.fmt_error ppf "Flow was unable to parse the file %S.@\n" path

  let pp_flow_loc (ppf : Fmt.t) ((path, loc) : string * Loc.t) : unit =
    let font = Config.(!loc_font) in
    Font.fmt font ppf "File %S, line %d, characters %d-%d" path loc.start.line
      loc.start.column loc._end.column

  let pp_flow_err (path : string) (ppf : Fmt.t)
      ((loc, err) : Loc.t * Parse_error.t) : unit =
    Fmt.fmt ppf "%s@\n%a" (Parse_error.PP.error err) pp_flow_loc (path, loc)

  let raise (path : string) (flow_errors : (Loc.t * Parse_error.t) list) : 'a =
    let pp_flow_errs = Fmt.(pp_lst !>"@\n" (pp_flow_err path)) in
    let err = Fmt.dly "%a%a" pp_err path pp_flow_errs flow_errors in
    raise (Exn err)

  let parse_ic (path : string) (ic : in_channel) :
      (Loc.t, Loc.t) Flow_ast.Program.t =
    let ic_sz = in_channel_length ic in
    let prog_text = really_input_string ic ic_sz in
    let (flow_ast, flow_errors) = Parser_flow.program ~fail:false prog_text in
    match flow_errors with [] -> flow_ast | _ -> raise path flow_errors
end

let parse (path : string) : (Loc.t, Loc.t) Flow_ast.Program.t =
  let ic = open_in path in
  let parse_f () = parse_ic path ic in
  let finally () = close_in_noerr ic in
  Fun.protect ~finally parse_f
