module Config = struct
  include Config

  let log_warns = static true
  let log_infos = static false
  let log_debugs = static false
  let log_verbose = static false
  let app = constant (Fmt.dly "graphjs", Font.create ~fg:`White ())
  let error = constant (Fmt.dly "error", Font.create ~fg:`LightRed ())
  let warn = constant (Fmt.dly "warn", Font.create ~fg:`Yellow ())
  let info = constant (Fmt.dly "info", Font.create ~fg:`LightCyan ())
  let debug = constant (Fmt.dly "debug", Font.create ~fg:`Cyan ())
end

open struct
  let create_log ((header, font) : (Fmt.t -> unit) * Font.t) (ppf : Fmt.t)
      (fmt : ('a, Fmt.t, unit, 'b) format4) : 'a =
    let pp_content ppf fmt = Font.fmt font ppf "[%t] %t" header fmt in
    Fmt.kdly (Fmt.fmt ppf "%a@." pp_content) fmt
end

let fmt_app (ppf : Fmt.t) (fmt : ('a, Fmt.t, unit, unit) format4) : 'a =
  create_log Config.(!app) ppf fmt

let fmt_error (ppf : Fmt.t) (fmt : ('a, Fmt.t, unit, unit) format4) : 'a =
  create_log Config.(!error) ppf fmt

let fmt_warn (ppf : Fmt.t) (fmt : ('a, Fmt.t, unit, unit) format4) : 'a =
  if Config.(!log_warns) then create_log Config.(!warn) ppf fmt
  else (Fmt.ignore ppf [@inlined]) fmt

let fmt_info (ppf : Fmt.t) (fmt : ('a, Fmt.t, unit, unit) format4) : 'a =
  if Config.(!log_infos) then create_log Config.(!info) ppf fmt
  else (Fmt.ignore ppf [@inlined]) fmt

let fmt_debug (ppf : Fmt.t) (fmt : ('a, Fmt.t, unit, unit) format4) : 'a =
  if Config.(!log_debugs) then create_log Config.(!debug) ppf fmt
  else (Fmt.ignore ppf [@inlined]) fmt

let fmt_verbose (ppf : Fmt.t) (fmt : ('a, Fmt.t, unit, unit) format4) : 'a =
  let pp_content ppf fmt = Fmt.fmt ppf "%t" fmt in
  if Config.(!log_verbose) then Fmt.kdly (Fmt.fmt ppf "%a@." pp_content) fmt
  else (Fmt.ignore ppf [@inlined]) fmt

let writer (writer : Writer.t) (fmt : ('a, Fmt.t, unit, unit) format4) : 'a =
  Fmt.fmt writer.ppf fmt

let stdout (fmt : ('a, Fmt.t, unit, unit) format4) : 'a =
  Fmt.fmt Writer.Config.(!stdout).ppf fmt

let stderr (fmt : ('a, Fmt.t, unit, unit) format4) : 'a =
  Fmt.fmt Writer.Config.(!stderr).ppf fmt

let ignore (fmt : ('a, Fmt.t, unit, unit) format4) : 'a =
  Fmt.ignore Writer.Config.(!stdbuf).ppf fmt

let fail (fmt : ('a, Fmt.t, unit, 'b) format4) : 'a = Fmt.ksstr failwith fmt

let app (fmt : ('a, Fmt.t, unit, unit) format4) : 'a =
  (fmt_app Writer.Config.(!stdout).ppf [@inlined]) fmt

let error (fmt : ('a, Fmt.t, unit, unit) format4) : 'a =
  (fmt_error Writer.Config.(!stderr).ppf [@inlined]) fmt

let warn (fmt : ('a, Fmt.t, unit, unit) format4) : 'a =
  (fmt_warn Writer.Config.(!stderr).ppf [@inlined]) fmt

let info (fmt : ('a, Fmt.t, unit, unit) format4) : 'a =
  (fmt_info Writer.Config.(!stderr).ppf [@inlined]) fmt

let debug (fmt : ('a, Fmt.t, unit, unit) format4) : 'a =
  (fmt_debug Writer.Config.(!stderr).ppf [@inlined]) fmt

let verbose (fmt : ('a, Fmt.t, unit, unit) format4) : 'a =
  (fmt_verbose Writer.Config.(!stderr).ppf [@inlined]) fmt

module Redirect = struct
  type mode =
    | Out
    | Err
    | All
    | Shared

  type t =
    { old_out : Writer.t
    ; old_err : Writer.t
    ; new_out : Buffer.t option
    ; new_err : Buffer.t option
    }

  let capture (old : Writer.t Config.t) (buf : Buffer.t) : Buffer.t =
    Writer.Config.(old := Writer.to_buffer buf);
    buf

  let capture_to ~(out : Buffer.t option) ~(err : Buffer.t option) : t =
    let old_out = Writer.Config.(!stdout) in
    let old_err = Writer.Config.(!stderr) in
    let new_out = Option.map (capture Writer.Config.stdout) out in
    let new_err = Option.map (capture Writer.Config.stderr) err in
    { old_out; old_err; new_out; new_err }

  let capture (mode : mode) : t =
    let buffer () = Some (Buffer.create Config.(!dflt_buf_sz)) in
    match mode with
    | Out -> capture_to ~out:(buffer ()) ~err:None
    | Err -> capture_to ~err:(buffer ()) ~out:None
    | All -> capture_to ~out:(buffer ()) ~err:(buffer ())
    | Shared ->
      let streams = capture_to ~out:(buffer ()) ~err:None in
      let new_out = Writer.Config.(!stdout) in
      Writer.Config.(stderr := new_out);
      streams

  let pp_captured (ppf : Fmt.t) (streams : t) : unit =
    let log ppf buf = Fmt.pp_str ppf (Buffer.contents buf) in
    Option.fold ~none:() ~some:(log ppf) streams.new_out;
    Option.fold ~none:() ~some:(log ppf) streams.new_err

  let restore ?(log : bool = false) (streams : t) : unit =
    let close writer ppf buf =
      Writer.remove writer;
      if log then Fmt.fmt ppf "%s@?" (Buffer.contents buf) in
    let old_out = streams.old_out in
    let old_err = streams.old_err in
    let new_out = Writer.Config.(!stdout) in
    let new_err = Writer.Config.(!stderr) in
    Option.fold ~none:() ~some:(close new_out old_out.ppf) streams.new_out;
    Option.fold ~none:() ~some:(close new_err old_err.ppf) streams.new_err;
    Writer.Config.(stdout := old_out);
    Writer.Config.(stderr := old_err)
end
