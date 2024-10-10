module Config = struct
  include Config

  let log_warns : bool t = static true
  let log_infos : bool t = static false
  let log_debugs : bool t = static false

  let app : ((Fmt.t -> unit) * Font.t) t =
    constant ((fun _ -> ()), Font.create ())

  let error : ((Fmt.t -> unit) * Font.t) t =
    constant (Fmt.dly "error", Font.create ~fg:`LightRed ())

  let warn : ((Fmt.t -> unit) * Font.t) t =
    constant (Fmt.dly "warn", Font.create ~fg:`LightYellow ())

  let info : ((Fmt.t -> unit) * Font.t) t =
    constant (Fmt.dly "debug", Font.create ~fg:`LightCyan ())

  let debug : ((Fmt.t -> unit) * Font.t) t =
    constant (Fmt.dly "debug", Font.create ~fg:`Cyan ())
end

open struct
  let create_log ((header, font) : (Fmt.t -> unit) * Font.t)
      (ppf_f : Fmt.t -> 'a) (ppf : Fmt.t)
      (format : ('b, Fmt.t, unit, 'a) format4) : 'b =
    Fmt.kdly (Font.kfmt font ppf_f ppf "[%t] %t" header) format
  [@@inline]
end

let kfmt_app (ppf_f : Fmt.t -> 'a) (ppf : Fmt.t)
    (format : ('b, Fmt.t, unit, 'a) format4) : 'b =
  (create_log [@inlined]) Config.(!app) ppf_f ppf format

let kfmt_error (ppf_f : Fmt.t -> 'a) (ppf : Fmt.t)
    (format : ('b, Fmt.t, unit, 'a) format4) : 'b =
  (create_log [@inlined]) Config.(!error) ppf_f ppf format

let kfmt_warn (ppf_f : Fmt.t -> 'a) (ppf : Fmt.t)
    (format : ('b, Fmt.t, unit, 'a) format4) : 'b =
  let open Config in
  if !log_warns then (create_log [@inlined]) !warn ppf_f ppf format
  else (Fmt.kignore ppf_f ppf [@inlined]) format

let kfmt_info (ppf_f : Fmt.t -> 'a) (ppf : Fmt.t)
    (format : ('b, Fmt.t, unit, 'a) format4) : 'b =
  let open Config in
  if !log_infos then (create_log [@inlined]) !info ppf_f ppf format
  else (Fmt.kignore ppf_f ppf [@inlined]) format

let kfmt_debug (ppf_f : Fmt.t -> 'a) (ppf : Fmt.t)
    (format : ('b, Fmt.t, unit, 'a) format4) : 'b =
  let open Config in
  if !log_debugs then (create_log [@inlined]) !debug ppf_f ppf format
  else (Fmt.kignore ppf_f ppf [@inlined]) format

let fmt_app (ppf : Fmt.t) (format : ('a, Fmt.t, unit, 'b) format4) : 'a =
  (kfmt_app ignore [@inlined]) ppf format

let fmt_error (ppf : Fmt.t) (format : ('a, Fmt.t, unit, 'b) format4) : 'a =
  (kfmt_error ignore [@inlined]) ppf format

let fmt_warn (ppf : Fmt.t) (format : ('a, Fmt.t, unit, 'b) format4) : 'a =
  (kfmt_warn ignore [@inlined]) ppf format

let fmt_info (ppf : Fmt.t) (format : ('a, Fmt.t, unit, 'b) format4) : 'a =
  (kfmt_info ignore [@inlined]) ppf format

let fmt_debug (ppf : Fmt.t) (format : ('a, Fmt.t, unit, 'b) format4) : 'a =
  (kfmt_debug ignore [@inlined]) ppf format

let stdout (format : ('a, Fmt.t, unit, unit) format4) : 'a =
  Fmt.fmt Writer.stdout.ppf format
[@@inline]

let stderr (format : ('a, Fmt.t, unit, unit) format4) : 'a =
  Fmt.fmt Writer.stderr.ppf format
[@@inline]

let fail (format : ('a, Fmt.t, unit, 'b) format4) : 'a =
  Fmt.kstr failwith format
[@@inline]

let app (format : ('a, Fmt.t, unit, unit) format4) : 'a =
  (fmt_app Writer.stdout.ppf [@inlined]) format

let error (format : ('a, Fmt.t, unit, unit) format4) : 'a =
  (fmt_error Writer.stderr.ppf [@inlined]) format

let warn (format : ('a, Fmt.t, unit, unit) format4) : 'a =
  (fmt_warn Writer.stderr.ppf [@inlined]) format

let info (format : ('a, Fmt.t, unit, unit) format4) : 'a =
  (fmt_info Writer.stderr.ppf [@inlined]) format

let debug (format : ('a, Fmt.t, unit, unit) format4) : 'a =
  (fmt_debug Writer.stderr.ppf [@inlined]) format
