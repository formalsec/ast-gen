module Config = struct
  include Config

  let log_warns : bool t = static true
  let log_infos : bool t = static false
  let log_debugs : bool t = static false
  let log_verbose : bool t = static false

  let app : ((Fmt.t -> unit) * Font.t) t =
    constant (Fmt.dly "graphjs", Font.create ~fg:`White ())

  let error : ((Fmt.t -> unit) * Font.t) t =
    constant (Fmt.dly "error", Font.create ~fg:`LightRed ())

  let warn : ((Fmt.t -> unit) * Font.t) t =
    constant (Fmt.dly "warn", Font.create ~fg:`Yellow ())

  let info : ((Fmt.t -> unit) * Font.t) t =
    constant (Fmt.dly "info", Font.create ~fg:`LightCyan ())

  let debug : ((Fmt.t -> unit) * Font.t) t =
    constant (Fmt.dly "debug", Font.create ~fg:`Cyan ())
end

open struct
  let create_log ((header, font) : (Fmt.t -> unit) * Font.t) (ppf : Fmt.t) :
      ('a, Fmt.t, unit, 'b) format4 -> 'a =
    let pp_content ppf fmt = Font.fmt font ppf "[%t] %t" header fmt in
    Fmt.kdly (Fmt.fmt ppf "%a@." pp_content)
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

let stdout (fmt : ('a, Fmt.t, unit, unit) format4) : 'a =
  Fmt.fmt Writer.stdout.ppf fmt
[@@inline]

let stderr (fmt : ('a, Fmt.t, unit, unit) format4) : 'a =
  Fmt.fmt Writer.stderr.ppf fmt
[@@inline]

let fail (fmt : ('a, Fmt.t, unit, 'b) format4) : 'a = Fmt.ksstr failwith fmt
[@@inline]

let app (fmt : ('a, Fmt.t, unit, unit) format4) : 'a =
  (fmt_app Writer.stdout.ppf [@inlined]) fmt

let error (fmt : ('a, Fmt.t, unit, unit) format4) : 'a =
  (fmt_error Writer.stderr.ppf [@inlined]) fmt

let warn (fmt : ('a, Fmt.t, unit, unit) format4) : 'a =
  (fmt_warn Writer.stderr.ppf [@inlined]) fmt

let info (fmt : ('a, Fmt.t, unit, unit) format4) : 'a =
  (fmt_info Writer.stderr.ppf [@inlined]) fmt

let debug (fmt : ('a, Fmt.t, unit, unit) format4) : 'a =
  (fmt_debug Writer.stderr.ppf [@inlined]) fmt

let verbose (fmt : ('a, Fmt.t, unit, unit) format4) : 'a =
  (fmt_verbose Writer.stderr.ppf [@inlined]) fmt
