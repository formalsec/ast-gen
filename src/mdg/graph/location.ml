open Graphjs_base

module Config = struct
  include Config

  let literal_loc : int t = constant 0
end

type t = int

let make_generator ?(init : int = 1) () : t Generator.t =
  Generator.of_numbers ~init ()

open struct
  let uid_gen : t Generator.t = make_generator ~init:1 ()
end

let literal : unit -> t =
  let literal = Config.(!literal_loc) in
  fun () -> literal

let create () : t = uid_gen.next () [@@inline]
let hash (loc : t) : int = Hashtbl.hash loc [@@inline]
let equal (loc1 : t) (loc2 : t) : bool = Int.equal loc1 loc2 [@@inline]
let compare (loc1 : t) (loc2 : t) : int = Int.compare loc1 loc2 [@@inline]
let pp (ppf : Fmt.t) (loc : t) : unit = Fmt.pp_int ppf loc [@@inline]
let str (loc : t) : string = Fmt.str "%a" pp loc [@@inline]
let is_literal (loc : t) : bool = Config.(!literal_loc) == loc [@@inline]

module Set = struct
  type el = t

  include Set.Make (struct
    type t = el

    let compare : t -> t -> int = compare
  end)
end
