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
  module Registry = Map.Make (struct
    type t = formatter

    let compare (ppf1 : t) (ppf2 : t) : int = if ppf1 == ppf2 then 0 else 1
    [@@inline]
  end)

  let reg : t Registry.t ref = ref Registry.empty
  let reg_add (writer : t) : unit = reg := Registry.add writer.ppf writer !reg
  let reg_remove (writer : t) : unit = reg := Registry.remove writer.ppf !reg
  let reg_find_opt (ppf : formatter) : t option = Registry.find_opt ppf !reg
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
  match reg_find_opt ppf with
  | None -> generate Unknown ppf
  | Some writer -> writer

let stdout : t = create (Channel Stdlib.stdout) std_formatter
let stderr : t = create (Channel Stdlib.stderr) err_formatter
let stdbuf : t = create (Buffer stdbuf) str_formatter

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
