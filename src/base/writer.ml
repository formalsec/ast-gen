open Format

type size = int option

type stream =
  | Unknown
  | Buffer of Buffer.t
  | Channel of out_channel

type t =
  { stream : stream
  ; ppf : formatter
  ; width : size
  ; height : size
  ; colored : bool
  }

open struct
  let reg : t list ref = ref []

  let reg_find (ppf : formatter) : t option =
    List.find_opt (fun w -> w.ppf == ppf) !reg

  let reg_add (w : t) : unit = reg := w :: !reg

  let reg_remove (w : t) : unit =
    let rec reg_remove' = function
      | [] -> []
      | w' :: reg' when w'.ppf == w.ppf -> reg'
      | w' :: reg' -> w' :: reg_remove' reg' in
    reg := reg_remove' !reg
end

let stream_attributes (stream : stream) : size * size * bool =
  match stream with
  | Unknown | Buffer _ -> (None, None, false)
  | Channel oc -> Console.attributes (Unix.descr_of_out_channel oc)

let generate (stream : stream) (ppf : formatter) : t =
  let (width, height, colored) = stream_attributes stream in
  { stream; ppf; width; height; colored }

let create (stream : stream) (ppf : formatter) : t =
  let writer = generate stream ppf in
  reg_add writer;
  writer

let remove ?(close : bool = true) (writer : t) : unit =
  reg_remove writer;
  match (writer.stream, close) with
  | (Channel oc, true) -> close_out_noerr oc
  | _ -> ()

let find (ppf : formatter) : t =
  match reg_find ppf with None -> generate Unknown ppf | Some writer -> writer

let stream (ppf : Fmt.t) : stream = (find ppf).stream
let width (ppf : Fmt.t) : size = (find ppf).width
let height (ppf : Fmt.t) : size = (find ppf).height
let colored (ppf : Fmt.t) : bool = (find ppf).colored

let to_buffer (buf : Buffer.t) : t =
  create (Buffer buf) (formatter_of_buffer buf)

let to_channel (oc : out_channel) : t =
  create (Channel oc) (formatter_of_out_channel oc)

let to_new_buffer () : t = to_buffer (Buffer.create Config.(!dflt_buf_sz))
let to_file (filename : string) : t = to_channel (open_out filename)

module Config = struct
  include Config

  let stdout = dynamic (create (Channel Stdlib.stdout) std_formatter)
  let stderr = dynamic (create (Channel Stdlib.stderr) err_formatter)
  let stdbuf = constant (create (Buffer stdbuf) str_formatter)
end

let size ~(default : int) (size : size) : int = Option.value ~default size
let ( + ) (size : size) (n : int) : size = Option.map Fun.(flip ( + ) n) size
let ( - ) (size : size) (n : int) : size = Option.map Fun.(flip ( - ) n) size
let ( * ) (size : size) (n : int) : size = Option.map Fun.(flip ( * ) n) size
let ( / ) (size : size) (n : int) : size = Option.map Fun.(flip ( / ) n) size

let ( < ) (size : size) (n : int) : bool =
  Option.fold ~none:false ~some:Fun.(flip ( < ) n) size

let ( <= ) (size : size) (n : int) : bool =
  Option.fold ~none:false ~some:Fun.(flip ( <= ) n) size

let ( > ) (size : size) (n : int) : bool =
  Option.fold ~none:true ~some:Fun.(flip ( > ) n) size

let ( >= ) (size : size) (n : int) : bool =
  Option.fold ~none:true ~some:Fun.(flip ( >= ) n) size
