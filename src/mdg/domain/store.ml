open Graphjs_base

type t = (string, Node.Set.t) Hashtbl.t

let create () : t = Hashtbl.create Config.(!dflt_htbl_sz)
let copy (store : t) : t = Hashtbl.copy store
let equal (store1 : t) (store2 : t) = Hashtbl.equal Node.Set.equal store1 store2

let find (store : t) (name : string) : Node.Set.t =
  Option.value ~default:Node.Set.empty (Hashtbl.find_opt store name)

let replace (store : t) (name : string) (ls_value : Node.Set.t) : unit =
  Hashtbl.replace store name ls_value

let pp (ppf : Fmt.t) (store : t) : unit =
  let pp_bind ppf (name, ls_value) =
    Fmt.fmt ppf "%s -> %a" name Node.Set.pp ls_value in
  Fmt.(pp_htbl !>"@\n" pp_bind) ppf store

let str (store : t) : string = Fmt.str "%a" pp store

let strong_update (store : t) (l_old : Node.t) (l_new : Node.t) : unit =
  let replace_f l_value = if Node.equal l_old l_value then l_new else l_value in
  Fun.flip Hashtbl.iter store (fun name ls_value ->
      replace store name (Node.Set.map replace_f ls_value) )

let weak_update (store : t) (l_old : Node.t) (ls_new : Node.Set.t) : unit =
  let replace_f l_value acc =
    if Node.equal l_old l_value then Node.Set.union ls_new acc
    else Node.Set.add l_value acc in
  Fun.flip Hashtbl.iter store (fun name ls_value ->
      replace store name (Node.Set.fold replace_f ls_value Node.Set.empty) )

let lub (store1 : t) (store2 : t) : t =
  Fun.flip Hashtbl.iter store2 (fun name ls_value2 ->
      let ls_value1 = find store1 name in
      replace store1 name (Node.Set.union ls_value1 ls_value2) );
  store1
