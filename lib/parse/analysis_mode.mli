type t = Basic | Single_file | Multi_file

val basic : t

val single_file : t

val multi_file : t

val is_basic : t -> bool

val is_single_file : t -> bool

val is_multi_file : t -> bool

val of_string : string -> (t, string) result

val to_string : t -> string

val pp : Format.formatter -> t -> unit
