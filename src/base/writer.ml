open Format

type stream =
  | Unknown
  | Buffer of Buffer.t
  | Channel of out_channel

type t =
  { stream : stream
  ; ppf : formatter
  ; width : int option
  ; height : int option
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

let stream (writer : t) : stream = writer.stream [@@inline]
let ppf (writer : t) : formatter = writer.ppf [@@inline]
let width (writer : t) : int option = writer.width [@@inline]
let height (writer : t) : int option = writer.height [@@inline]
let colored (writer : t) : bool = writer.colored [@@inline]

let stream_attributes : stream -> int option * int option * bool = function
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

let to_buffer (buffer : Buffer.t) : t =
  create (Buffer buffer) (formatter_of_buffer buffer)
[@@inline]

let to_out_channel (oc : out_channel) : t =
  create (Channel oc) (formatter_of_out_channel oc)
[@@inline]

let to_new_buffer () : t = to_buffer (Buffer.create Config.(!dflt_buf_sz))
[@@inline]

let to_file (filename : string) : t = to_out_channel (open_out filename)
[@@inline]

module Config = struct
  include Config

  let stdout = flexible (create (Channel Stdlib.stdout) std_formatter)
  let stderr = flexible (create (Channel Stdlib.stderr) err_formatter)
  let stdbuf = constant (create (Buffer stdbuf) str_formatter)
end
