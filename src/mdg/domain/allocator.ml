open Graphjs_base
open Graphjs_ast

type cid =
  { id : int
  ; offset : int
  ; at : Region.t
  }

include Hashtbl.Make (struct
  type t = cid

  let hash (key : t) : int = Hashtbl.hash (key.id, key.offset)

  let equal (key1 : t) (key2 : t) : bool =
    Int.equal key1.id key2.id && Int.equal key1.offset key2.offset
end)

let cid (el : ('a, Region.t) Metadata.t) : cid =
  { id = el.id; offset = 0; at = el.md }

let offset (cid : cid) (offset : int) : cid = { cid with offset }
let at (cid : cid) : Region.t = cid.at

let lub (alloc1 : 'a t) (alloc2 : 'a t) : 'a t =
  Fun.flip iter alloc2 (fun stmt node2 ->
      let el1 = find_opt alloc1 stmt in
      if Option.is_none el1 then replace alloc1 stmt node2 );
  alloc1
