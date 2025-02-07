open Format

type t = formatter

let kfmt (k : t -> 'a) (ppf : t) (fmt : ('b, t, unit, 'a) format4) : 'b =
  kfprintf k ppf fmt

let kignore (k : t -> 'a) (ppf : t) (fmt : ('b, t, unit, 'a) format4) : 'b =
  ikfprintf k ppf fmt

let kdly (k : (t -> unit) -> 'a) (fmt : ('b, t, unit, 'a) format4) : 'b =
  kdprintf k fmt

let kstr (k : string -> 'a) (fmt : ('b, t, unit, 'a) format4) : 'b =
  kfprintf (fun _ -> k (flush_str_formatter ())) str_formatter fmt

let ksstr (k : string -> 'a) (fmt : ('b, t, unit, 'a) format4) : 'b =
  kasprintf k fmt

let fmt (ppf : t) (fmt : ('a, t, unit, unit) format4) : 'a = kfmt ignore ppf fmt
let ignore (ppf : t) (fmt : ('a, t, unit) format) : 'a = kignore ignore ppf fmt
let dly (fmt : ('a, t, unit, t -> unit) format4) : 'a = kdly Fun.id fmt
let str (fmt : ('a, t, unit, string) format4) : 'a = kstr Fun.id fmt
let sstr (fmt : ('a, t, unit, string) format4) : 'a = ksstr Fun.id fmt

(* Pretty printer formatters *)

let ( !> ) (fmt : ('a, t, unit, t -> unit) format4) : 'a = dly fmt
let pp_none (_ : t) (_ : 'a) : unit = ()
let pp_flush (ppf : t) (() : unit) : unit = pp_print_flush ppf ()
let pp_newline (ppf : t) (() : unit) : unit = pp_print_newline ppf ()
let pp_int (ppf : t) (i : int) : unit = pp_print_int ppf i
let pp_float (ppf : t) (f : float) : unit = pp_print_float ppf f
let pp_char (ppf : t) (c : char) : unit = pp_print_char ppf c
let pp_str (ppf : t) (s : string) : unit = pp_print_string ppf s
let pp_bool (ppf : t) (b : bool) : unit = pp_print_bool ppf b
let pp_bytes (ppf : t) (bts : bytes) : unit = pp_print_bytes ppf bts

let pp_opt (pp_v : t -> 'a -> unit) (ppf : t) (v : 'a option) : unit =
  pp_print_option pp_v ppf v

let pp_result ~(ok : t -> 'a -> unit) ~(error : t -> 'e -> unit) (ppf : t)
    (v : ('a, 'e) result) : unit =
  pp_print_result ~ok ~error ppf v

let pp_iter (iter_f : ('a -> unit) -> 'b -> unit) (pp_sep : t -> unit)
    (pp_v : t -> 'a -> unit) (ppf : t) (v : 'b) : unit =
  pp_print_iter ~pp_sep:(fun ppf () -> pp_sep ppf) iter_f pp_v ppf v

let pp_lst (pp_sep : t -> unit) (pp_v : t -> 'a -> unit) (ppf : t)
    (lst : 'a list) : unit =
  pp_iter List.iter pp_sep pp_v ppf lst

let pp_seq (pp_sep : t -> unit) (pp_v : t -> 'a -> unit) (ppf : t)
    (seq : 'a Seq.t) : unit =
  pp_iter Seq.iter pp_sep pp_v ppf seq

let pp_arr (pp_sep : t -> unit) (pp_v : t -> 'a -> unit) (ppf : t)
    (arr : 'a array) =
  pp_iter Array.iter pp_sep pp_v ppf arr

let pp_htbl (pp_sep : t -> unit) (pp_v : t -> 'a * 'b -> unit) (ppf : t)
    (htbl : ('a, 'b) Hashtbl.t) =
  pp_iter (fun f -> Hashtbl.iter (fun a b -> f (a, b))) pp_sep pp_v ppf htbl
