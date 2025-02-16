module Config = struct
  include Config

  let colored = static true
end

module Attr = struct
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

  let code (attr : t) : int =
    let to_code = function
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
    match attr with
    | `Reset -> 0
    | `Foreground fg -> to_code fg
    | `Background bg -> to_code bg + 10
    | `Effect effect -> to_code effect
    | `Style style -> to_code style
end

type t = Attr.t list

open struct
  let mk_foreground (fg : Attr.color option) (font : t) : t =
    Option.fold ~none:font ~some:(fun fg' -> `Foreground fg' :: font) fg

  let mk_background (bg : Attr.color option) (font : t) : t =
    Option.fold ~none:font ~some:(fun bg -> `Background bg :: font) bg

  let mk_effect (effect : Attr.effect option) (font : t) : t =
    Option.fold ~none:font ~some:(fun effect' -> `Effect effect' :: font) effect

  let mk_style ((style, on) : Attr.style * bool option) (font : t) : t =
    let style_f = function true -> `Style style :: font | false -> font in
    Option.fold ~none:font ~some:style_f on

  let mk_font (fg : Attr.color option) (bg : Attr.color option)
      (effect : Attr.effect option) (bold : bool option) (italic : bool option)
      (underline : bool option) (strike : bool option) : t =
    mk_foreground fg []
    |> mk_background bg
    |> mk_effect effect
    |> mk_style (`Bold, bold)
    |> mk_style (`Italic, italic)
    |> mk_style (`Underline, underline)
    |> mk_style (`Strike, strike)
end

let colored (writer : Writer.t) : bool =
  Config.(!colored) && Writer.colored writer

let get_foreground (font : t) : Attr.color option =
  List.find_map (function `Foreground fg -> Some fg | _ -> None) font

let get_background (font : t) : Attr.color option =
  List.find_map (function `Background bg -> Some bg | _ -> None) font

let get_effect (font : t) : Attr.effect option =
  List.find_map (function `Effect effect -> Some effect | _ -> None) font

let get_style (style : Attr.style) (font : t) : bool option =
  Fun.flip List.find_map font (function
    | `Style style' when style == style' -> Some true
    | _ -> None )

let create ?(fg : Attr.color option) ?(bg : Attr.color option)
    ?(effect : Attr.effect option) ?(bold : bool option) ?(italic : bool option)
    ?(underline : bool option) ?(strike : bool option) () : t =
  mk_font fg bg effect bold italic underline strike

let update ?(fg : Attr.color option) ?(bg : Attr.color option)
    ?(effect : Attr.effect option) ?(bold : bool option) ?(italic : bool option)
    ?(underline : bool option) ?(strike : bool option) (font : t) : t =
  let fg = Option.map_none ~value:(get_foreground font) fg in
  let bg = Option.map_none ~value:(get_background font) bg in
  let effect = Option.map_none ~value:(get_effect font) effect in
  let bold = Option.map_none ~value:(get_style `Bold font) bold in
  let italic = Option.map_none ~value:(get_style `Italic font) italic in
  let underline = Option.map_none ~value:(get_style `Underline font) underline in
  let strike = Option.map_none ~value:(get_style `Strike font) strike in
  mk_font fg bg effect bold italic underline strike

let pp_font (ppf : Fmt.t) (font : t) : unit =
  let pp_attr ppf attr = Fmt.pp_int ppf (Attr.code attr) in
  Fmt.fmt ppf "\027[%am" Fmt.(pp_lst !>";" pp_attr) font

let pp (font : t) (pp_v : Fmt.t -> 'a -> unit) (ppf : Fmt.t) (v : 'a) : unit =
  if not (colored (Writer.find ppf)) then pp_v ppf v
  else Fmt.fmt ppf "%a%a%a" pp_font font pp_v v pp_font [ `Reset ]

let kfmt (font : t) (k : Fmt.t -> 'a) (ppf : Fmt.t)
    (fmt : ('b, Fmt.t, unit, 'a) format4) : 'b =
  let pp_fmt ppf = Fmt.fmt ppf "%t" in
  Fmt.kdly (fun acc -> pp font pp_fmt ppf acc |> fun () -> k ppf) fmt

let kdly (font : t) (k : (Fmt.t -> unit) -> 'a)
    (fmt : ('b, Fmt.t, unit, 'a) format4) : 'b =
  let pp_fmt ppf = Fmt.fmt ppf "%t" in
  Fmt.kdly (fun acc -> k (fun ppf -> pp font pp_fmt ppf acc)) fmt

let fmt (font : t) (ppf : Fmt.t) (fmt : ('a, Fmt.t, unit, unit) format4) : 'a =
  kfmt font ignore ppf fmt

let dly (font : t) (fmt : ('a, Fmt.t, unit, Fmt.t -> unit) format4) : 'a =
  kdly font Fun.id fmt
