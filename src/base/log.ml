module Config = struct
  include Config

  let log_warns : bool t = static true
  let log_debugs : bool t = static false

  let app : ((Fmt.t -> unit) * Font.t) t =
    constant ((fun _ -> ()), Font.create ())

  let error : ((Fmt.t -> unit) * Font.t) t =
    constant (Fmt.inv "error", Font.create ~fg:`LightRed ())

  let warn : ((Fmt.t -> unit) * Font.t) t =
    constant (Fmt.inv "warn", Font.create ~fg:`LightYellow ())

  let debug : ((Fmt.t -> unit) * Font.t) t =
    constant (Fmt.inv "debug", Font.create ~fg:`LightCyan ())
end

open struct
  let create_log ((header, font) : (Fmt.t -> unit) * Font.t) (ppf : Fmt.t)
      (format : ('a, Fmt.t, unit, unit) format4) : 'a =
    let pp_log ppf fmt = Fmt.fmt ppf "%t%t" header fmt in
    Fmt.kinv (Fmt.fmt ppf "%a@." (Font.pp font pp_log)) format

  let header ((header, font) : (Fmt.t -> unit) * Font.t) :
      (Fmt.t -> unit) * Font.t =
    (Fmt.inv "[%t] " header, font)
  [@@inline]
end

let stdout (format : ('a, Fmt.t, unit, unit) format4) : 'a =
  Fmt.kfmt ignore Writer.stdout.ppf format
[@@inline]

let stderr (format : ('a, Fmt.t, unit, unit) format4) : 'a =
  Fmt.kfmt ignore Writer.stderr.ppf format
[@@inline]

let fail (format : ('a, Fmt.t, unit, unit) format4) : 'a =
  Fmt.kstr failwith format
[@@inline]

let app (format : ('a, Fmt.t, unit, unit) format4) : 'a =
  create_log Config.(!app) Writer.stdout.ppf format
[@@inline]

let error (format : ('a, Fmt.t, unit, unit) format4) : 'a =
  create_log (header Config.(!error)) Writer.stderr.ppf format
[@@inline]

let warn (format : ('a, Fmt.t, unit, unit) format4) : 'a =
  if Config.(!log_warns) then
    create_log (header Config.(!warn)) Writer.stderr.ppf format
[@@inline]

let debug (format : ('a, Fmt.t, unit, unit) format4) : 'a =
  if Config.(!log_debugs) then
    create_log (header Config.(!debug)) Writer.stderr.ppf format
[@@inline]
