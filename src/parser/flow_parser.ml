exception Exn of (Fmt.t -> unit)

module Config = struct
  include Config

  let loc_font = constant (Font.create ~fg:`DarkGray ~italic:true ())
end

let pp_err_header (ppf : Fmt.t) (path : string) : unit =
  Log.fmt_error ppf "Flow was unable to parse the file %S." path

let pp_flow_loc (ppf : Fmt.t) ((path, loc) : string * Loc.t) : unit =
  let font = Config.(!loc_font) in
  Font.fmt font ppf "File %S, line %d, characters %d-%d" path loc.start.line
    loc.start.column loc._end.column

let pp_flow_err (path : string) (ppf : Fmt.t)
    ((loc, err) : Loc.t * Parse_error.t) : unit =
  Fmt.fmt ppf "%a@\n%s" pp_flow_loc (path, loc) (Parse_error.PP.error err)

let raise (path : string) (flow_errs : (Loc.t * Parse_error.t) list) : 'a =
  let pp_flow_errs = Fmt.(pp_lst !>"@\n" (pp_flow_err path)) in
  let err = Fmt.dly "%a%a@\n" pp_err_header path pp_flow_errs flow_errs in
  raise (Exn err)

let parse_code (code : string) : (Loc.t, Loc.t) Flow_ast.Program.t =
  match Parser_flow.program_file ~fail:false code None with
  | (flow_ast, []) -> flow_ast
  | (_, flow_errors) -> raise "" flow_errors

let parse_ic (ic : in_channel) (path : string) (rel : string) :
    (Loc.t, Loc.t) Flow_ast.Program.t =
  let ic_sz = in_channel_length ic in
  let ic_text = really_input_string ic ic_sz in
  let source = Some (File_key.SourceFile rel) in
  match Parser_flow.program_file ~fail:false ic_text source with
  | (flow_ast, []) -> flow_ast
  | (_, flow_errors) -> raise path flow_errors

let parse (path : Fpath.t) (rel : Fpath.t) : (Loc.t, Loc.t) Flow_ast.Program.t =
  let path' = Fpath.to_string path in
  let rel' = Fpath.to_string rel in
  let ic = open_in path' in
  let parse_f () = parse_ic ic path' rel' in
  let finally () = close_in_noerr ic in
  Fun.protect ~finally parse_f
