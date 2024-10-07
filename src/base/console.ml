module Config = struct
  include Config

  let required_colors : int t = constant 256
end

open struct
  let console_cmd (fd : Unix.file_descr) (cmd : string) : string option =
    if Unix.isatty fd then
      let ic = Unix.open_process_in cmd in
      let execute () = input_line ic in
      let finally () = ignore (Unix.close_process_in ic) in
      Some (Fun.protect ~finally execute)
    else None
end

let is_console (fd : Unix.file_descr) : bool = Unix.isatty fd [@@inline]

let longname (fd : Unix.file_descr) : string =
  let res = console_cmd fd "tput longname" in
  Option.fold ~none:"" ~some:Fun.id res

let width (fd : Unix.file_descr) : int option =
  let width' width = int_of_string width in
  let res = console_cmd fd "tput cols" in
  Option.map width' res

let height (fd : Unix.file_descr) : int option =
  let height' height = int_of_string height in
  let res = console_cmd fd "tput lines" in
  Option.map height' res

let colored (fd : Unix.file_descr) : bool =
  let colored' colors = int_of_string colors >= Config.(!required_colors) in
  let res = console_cmd fd "tput colors" in
  Option.fold ~none:false ~some:colored' res

let attributes (fd : Unix.file_descr) : int option * int option * bool =
  if is_console fd then (width fd, height fd, colored fd)
  else (None, None, false)
