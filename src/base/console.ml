type system =
  | Unknown
  | Linux
  | MacOS
  | WSL

open struct
  let command_input (ic : in_channel) : string =
    let rec command_input' sep res =
      match input_line ic with
      | exception End_of_file -> Buffer.contents res
      | line ->
        Buffer.add_string res sep;
        Buffer.add_string res line;
        command_input' "\n" res in
    command_input' "" (Buffer.create Config.(!dflt_buf_sz))
end

let execute (cmd : string) : string =
  let ic = Unix.open_process_in cmd in
  let execute () = command_input ic in
  let finally () = ignore (Unix.close_process_in ic) in
  Fun.protect ~finally execute

let is_console (fd : Unix.file_descr) : bool = Unix.isatty fd

let console_attribute (fd : Unix.file_descr) (cmd : string) : string option =
  if is_console fd then Some (execute cmd) else None

open struct
  let get_system () : system =
    match execute "uname" with
    | "Darwin" -> MacOS
    | "Linux" -> (
      match execute "grep -qi microsoft /proc/version && echo \"WSL\"" with
      | "WSL" -> WSL
      | _ -> Linux )
    | _ -> Unknown
end

module Config = struct
  include Config

  let required_colors : int t = constant 256
  let system : system t = constant (get_system ())
end

let pwd : unit -> string =
  let pwd = Unix.getcwd () in
  fun () -> pwd

let longname (fd : Unix.file_descr) : string =
  let res = console_attribute fd "tput longname" in
  Option.fold ~none:"" ~some:Fun.id res

let width (fd : Unix.file_descr) : int option =
  let width' width = int_of_string width in
  let res = console_attribute fd "tput cols" in
  Option.map width' res

let height (fd : Unix.file_descr) : int option =
  let height' height = int_of_string height in
  let res = console_attribute fd "tput lines" in
  Option.map height' res

let colored (fd : Unix.file_descr) : bool =
  let colored' colors = int_of_string colors >= Config.(!required_colors) in
  let res = console_attribute fd "tput colors" in
  Option.fold ~none:false ~some:colored' res

let attributes (fd : Unix.file_descr) : int option * int option * bool =
  if is_console fd then (width fd, height fd, colored fd)
  else (None, None, false)

let url ?(anchor : string option) (url : string) : string =
  let pp_url ppf url = Fmt.fmt ppf "file:/%s" url in
  let pp_wsl ppf url = Fmt.fmt ppf "file:`wslpath -m %s`" url in
  let pp_anchor pp_url ppf (url, anchor) =
    Fmt.fmt ppf "\\e]8;;%a\\a%s\\e]8;;\\a" pp_url url anchor in
  match (Config.(!system), anchor) with
  | ((Unknown | Linux | MacOS), None) -> Fmt.str "%a" pp_url url
  | (WSL, None) -> execute (Fmt.str "echo \"%a\"" pp_wsl url)
  | ((Unknown | Linux | MacOS), Some anchor') ->
    execute (Fmt.str "echo \"%a\"" (pp_anchor pp_url) (url, anchor'))
  | (WSL, Some anchor') ->
    execute (Fmt.str "echo \"%a\"" (pp_anchor pp_wsl) (url, anchor'))
