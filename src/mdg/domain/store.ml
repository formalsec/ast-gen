open Graphjs_base
open Graphjs_ast

type t = (string, Node.Set.t) Hashtbl.t

let create () : t = Hashtbl.create Config.(!dflt_htbl_sz)
let copy (store : t) : t = Hashtbl.copy store
let equal (store1 : t) (store2 : t) = Hashtbl.equal Node.Set.equal store1 store2

let pp (ppf : Fmt.t) (store : t) : unit =
  let pp_bind ppf (key, values) =
    Fmt.fmt ppf "%s -> %a" key Node.Set.pp values in
  Fmt.(pp_htbl !>"@\n" pp_bind) ppf store

let str (store : t) : string = Fmt.str "%a" pp store [@@inline]

let find (store : t) (key : string) : Node.Set.t =
  Option.value ~default:Node.Set.empty (Hashtbl.find_opt store key)

let replace (store : t) (key : string) (values : Node.Set.t) : unit =
  Hashtbl.replace store key values

let strong_update (store : t) (old : Node.t) (new' : Node.t) : unit =
  Fun.flip Hashtbl.iter store (fun key values ->
      let replace_f value = if Node.equal value old then new' else value in
      let values' = Node.Set.map replace_f values in
      replace store key values' )

let weak_update (store : t) (old : Node.t) (new' : Node.Set.t) : unit =
  Fun.flip Hashtbl.iter store (fun key values ->
      let replace_f value acc =
        if Node.equal value old then Node.Set.union new' acc
        else Node.Set.add value acc in
      let values' = Node.Set.fold replace_f values Node.Set.empty in
      replace store key values' )

let lub (store1 : t) (store2 : t) : t =
  Fun.flip Hashtbl.iter store2 (fun key values_2 ->
      let values_1 = find store1 key in
      replace store1 key (Node.Set.union values_1 values_2) );
  store1
