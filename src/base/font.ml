module Config = struct
  include Config

  let colored : bool t = static true
end

let colored (writer : Writer.t) : bool =
  Config.(!colored) && Writer.colored writer
[@@inline]

module Code = struct
  type color =
    [ `Black
    | `Red
    | `Green
    | `Yellow
    | `Blue
    | `Purple
    | `Cyan
    | `LightGray
    | `DarkGray
    | `LightRed
    | `LightGreen
    | `LightYellow
    | `LightBlue
    | `LightPurple
    | `LightCyan
    | `White
    ]

  type effect =
    [ `Disable
    | `Faint
    | `Blink
    | `Blinkfast
    | `Invisible
    ]

  type style =
    [ `Bold
    | `Italic
    | `Underline
    | `Strike
    ]

  type t =
    [ `Reset
    | `Foreground of color
    | `Background of color
    | `Effect of effect
    | `Style of style
    ]

  let ( ! ) (code : t) : int =
    let attr_to_int = function
      | `Bold -> 1
      | `Faint -> 2
      | `Italic -> 3
      | `Underline -> 4
      | `Blink -> 5
      | `Blinkfast -> 6
      | `Invisible -> 8
      | `Strike -> 9
      | `Disable -> 20
      | `Black -> 30
      | `Red -> 31
      | `Green -> 32
      | `Yellow -> 33
      | `Blue -> 34
      | `Purple -> 35
      | `Cyan -> 36
      | `LightGray -> 37
      | `DarkGray -> 90
      | `LightRed -> 91
      | `LightGreen -> 92
      | `LightYellow -> 93
      | `LightBlue -> 94
      | `LightPurple -> 95
      | `LightCyan -> 96
      | `White -> 97 in
    match code with
    | `Reset -> 0
    | `Foreground fg -> attr_to_int fg
    | `Background bg -> attr_to_int bg + 10
    | `Effect effect -> attr_to_int effect
    | `Style style -> attr_to_int style
end

open struct
  type font = Code.t list

  let get_foreground : font -> Code.color option =
    List.find_map (function `Foreground fg' -> Some fg' | _ -> None)

  let get_background : font -> Code.color option =
    List.find_map (function `Background bg' -> Some bg' | _ -> None)

  let get_effect : font -> Code.effect option =
    List.find_map (function `Effect effect' -> Some effect' | _ -> None)

  let get_style (style : Code.style) : font -> bool option =
    List.find_map (function
      | `Style style' when style == style' -> Some true
      | _ -> None )

  let set_foreground (fg : Code.color option) (font : font) : font =
    Option.fold ~none:font ~some:(fun color' -> `Foreground color' :: font) fg

  let set_background (bg : Code.color option) (font : font) : font =
    Option.fold ~none:font ~some:(fun color' -> `Background color' :: font) bg

  let set_effect (effect : Code.effect option) (font : font) : font =
    Option.fold ~none:font ~some:(fun effect' -> `Effect effect' :: font) effect

  let set_style ((style, on) : Code.style * bool option) (font : font) : font =
    let style_f = function true -> `Style style :: font | false -> font in
    Option.fold ~none:font ~some:style_f on

  let make_font (fg : Code.color option) (bg : Code.color option)
      (effect : Code.effect option) (bold : bool option) (italic : bool option)
      (underline : bool option) (strike : bool option) =
    set_foreground fg
    @@ set_background bg
    @@ set_effect effect
    @@ set_style (`Bold, bold)
    @@ set_style (`Italic, italic)
    @@ set_style (`Underline, underline)
    @@ set_style (`Strike, strike) []
end

type t = font

let create ?(fg : Code.color option) ?(bg : Code.color option)
    ?(effect : Code.effect option) ?(bold : bool option) ?(italic : bool option)
    ?(underline : bool option) ?(strike : bool option) () : t =
  make_font fg bg effect bold italic underline strike
[@@inline]

let update ?(fg : Code.color option) ?(bg : Code.color option)
    ?(effect : Code.effect option) ?(bold : bool option) ?(italic : bool option)
    ?(underline : bool option) ?(strike : bool option) (font : t) : t =
  let fg = Option.map_none ~value:(get_foreground font) fg in
  let bg = Option.map_none ~value:(get_background font) bg in
  let effect = Option.map_none ~value:(get_effect font) effect in
  let bold = Option.map_none ~value:(get_style `Bold font) bold in
  let italic = Option.map_none ~value:(get_style `Italic font) italic in
  let underline = Option.map_none ~value:(get_style `Underline font) underline in
  let strike = Option.map_none ~value:(get_style `Strike font) strike in
  make_font fg bg effect bold italic underline strike

let pp_font (ppf : Fmt.t) (font : t) : unit =
  let pp_code ppf code = Fmt.pp_int ppf Code.(!code) in
  Fmt.fmt ppf "\027[%am" Fmt.(pp_lst !>";" pp_code) font
[@@inline]

let pp (font : t) (pp_v : Fmt.t -> 'a -> unit) (ppf : Fmt.t) (v : 'a) : unit =
  if not (colored (Writer.find ppf)) then pp_v ppf v
  else Fmt.fmt ppf "%a%a%a" pp_font font pp_v v pp_font [ `Reset ]

let pp_int (font : t) : Fmt.t -> int -> unit = pp font Fmt.pp_int
let pp_float (font : t) : Fmt.t -> float -> unit = pp font Fmt.pp_float
let pp_char (font : t) : Fmt.t -> char -> unit = pp font Fmt.pp_char
let pp_str (font : t) : Fmt.t -> string -> unit = pp font Fmt.pp_str
let pp_bool (font : t) : Fmt.t -> bool -> unit = pp font Fmt.pp_bool
let pp_bytes (font : t) : Fmt.t -> bytes -> unit = pp font Fmt.pp_bytes

let kfmt (font : t) (ppf_f : Fmt.t -> 'a) (ppf : Fmt.t)
    (format : ('b, Fmt.t, unit, 'a) format4) : 'b =
  let pp_format ppf fmt = Fmt.fmt ppf "%t" fmt in
  Fmt.kdly (Fmt.kfmt ppf_f ppf "%a" (pp font pp_format)) format

let fmt (font : t) (ppf : Fmt.t) (format : ('a, Fmt.t, unit) format) : 'a =
  kfmt font ignore ppf format
[@@inline]
