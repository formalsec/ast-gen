open Format

type t = formatter

let kfmt (k : t -> 'a) (ppf : t) (format : ('b, t, unit, 'a) format4) : 'b =
  kfprintf k ppf format
[@@inline]

let kinv (k : (t -> unit) -> 'a) (format : ('b, t, unit, 'a) format4) : 'b =
  kdprintf k format
[@@inline]

let kstr (k : string -> 'a) (format : ('b, t, unit, 'a) format4) : 'b =
  kfprintf (fun _ -> k (flush_str_formatter ())) str_formatter format
[@@inline]

let ksstr (k : string -> 'a) (format : ('b, t, unit, 'a) format4) : 'b =
  kasprintf k format
[@@inline]

let fmt (ppf : t) (format : ('a, t, unit) format) : 'a = kfmt ignore ppf format
[@@inline]

let inv (format : ('a, t, unit, t -> unit) format4) : 'a = kinv Fun.id format
[@@inline]

let str (format : ('a, t, unit, string) format4) : 'a = kstr Fun.id format
[@@inline]

let sstr (format : ('a, t, unit, string) format4) : 'a = ksstr Fun.id format
[@@inline]

let ( !> ) : ('a, t, unit, t -> unit) format4 -> 'a = inv
let pp_none : t -> unit -> unit = fun _ () -> ()
let pp_space : t -> unit -> unit = pp_print_space
let pp_tab : t -> unit -> unit = pp_print_tab
let pp_newline : t -> unit -> unit = pp_force_newline
let pp_flush : t -> unit -> unit = pp_print_flush
let pp_int : t -> int -> unit = pp_print_int
let pp_float : t -> float -> unit = pp_print_float
let pp_char : t -> char -> unit = pp_print_char
let pp_str : t -> string -> unit = pp_print_string
let pp_bool : t -> bool -> unit = pp_print_bool
let pp_bytes : t -> bytes -> unit = pp_print_bytes
let pp_opt : (t -> 'a -> unit) -> t -> 'a option -> unit = pp_print_option

let pp_iter (iter_f : ('a -> unit) -> 'b -> unit) (pp_sep : t -> unit)
    (pp_v : t -> 'a -> unit) (ppf : t) : 'b -> unit =
  let is_fst = ref true in
  iter_f @@ fun v ->
  if !is_fst then is_fst := false else pp_sep ppf;
  pp_v ppf v

let pp_lst (pp_sep : t -> unit) (pp_v : t -> 'a -> unit) (ppf : t)
    (lst : 'a list) : unit =
  pp_print_list ~pp_sep:(fun ppf () -> pp_sep ppf) pp_v ppf lst
[@@inline]

let pp_seq (pp_sep : t -> unit) (pp_v : t -> 'a -> unit) (ppf : t)
    (seq : 'a Seq.t) : unit =
  pp_print_seq ~pp_sep:(fun ppf () -> pp_sep ppf) pp_v ppf seq
[@@inline]

let pp_arr (pp_sep : t -> unit) (pp_v : t -> 'a -> unit) (ppf : t)
    (arr : 'a array) =
  pp_iter Array.iter pp_sep pp_v ppf arr
[@@inline]

let pp_hashtbl (pp_sep : t -> unit) (pp_v : t -> 'a * 'b -> unit) (ppf : t)
    (htbl : ('a, 'b) Hashtbl.t) =
  pp_iter (fun f -> Hashtbl.iter (fun a b -> f (a, b))) pp_sep pp_v ppf htbl
[@@inline]