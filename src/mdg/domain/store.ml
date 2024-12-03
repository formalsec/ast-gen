open Graphjs_base
open Graphjs_ast

type t =
  { binds : (string, Node.Set.t) Hashtbl.t
  ; parent : t option
  }

let create () : t =
  let binds = Hashtbl.create Config.(!dflt_htbl_sz) in
  { binds; parent = None }

let rec copy (store : t) : t =
  let binds = Hashtbl.copy store.binds in
  let parent = Option.map copy store.parent in
  { binds; parent }

let extend (store : t) : t =
  let store' = copy store in
  let store'' = create () in
  { store'' with parent = Some store' }

let rec equal (store1 : t) (store2 : t) =
  Option.equal equal store1.parent store2.parent
  && Hashtbl.equal Node.Set.equal store1.binds store2.binds

let pp_binds (ppf : Fmt.t) (binds : (string, Node.Set.t) Hashtbl.t) : unit =
  let pp_bind ppf (key, values) =
    Fmt.fmt ppf "%s -> %a" key Node.Set.pp values in
  Fmt.(pp_hashtbl !>"@\n" pp_bind) ppf binds

let rec pp (ppf : Fmt.t) (store : t) : unit =
  match store.parent with
  | None -> Fmt.fmt ppf "%a" pp_binds store.binds
  | Some parent -> Fmt.fmt ppf "%a@\n...@\n%a" pp_binds store.binds pp parent

let str (store : t) : string = Fmt.str "%a" pp store [@@inline]

let find (store : t) (key : string) : Node.Set.t option =
  Hashtbl.find_opt store.binds key

let replace (store : t) (key : string) (values : Node.Set.t) : unit =
  Hashtbl.replace store.binds key values

let get (store : t) (key : string) : Node.Set.t =
  Option.value ~default:Node.Set.empty (find store key)

let set (store : t) (key : string) (value : Node.t) : unit =
  replace store key (Node.Set.singleton value)

let rec retrieve (store : t) (key : string) : Node.Set.t =
  match (find store key, store.parent) with
  | (Some values, _) -> values
  | (None, Some parent) -> retrieve parent key
  | (None, None) -> Node.Set.empty

let rec update (store : t) (key : string) (values : Node.Set.t) : unit =
  match (find store key, store.parent) with
  | (Some _, _) -> replace store key values
  | (None, Some parent) -> update parent key values
  | (None, None) -> replace store key values

let rec strong_update (store : t) (old : Node.t) (new' : Node.t) : unit =
  Option.iter (fun parent -> strong_update parent old new') store.parent;
  Fun.flip Hashtbl.iter store.binds @@ fun key values ->
  let replace_f value = if Node.equal value old then new' else value in
  let values' = Node.Set.map replace_f values in
  replace store key values'

let rec weak_update (store : t) (old : Node.t) (new' : Node.Set.t) : unit =
  Option.iter (fun parent -> weak_update parent old new') store.parent;
  Fun.flip Hashtbl.iter store.binds @@ fun key values ->
  let replace_f value acc =
    if Node.equal value old then Node.Set.union new' acc
    else Node.Set.add value acc in
  let values' = Node.Set.fold replace_f values Node.Set.empty in
  replace store key values'

let rec lub (store1 : t) (store2 : t) : unit =
  ( match (store1.parent, store2.parent) with
  | (Some parent1, Some parent2) -> lub parent1 parent2
  | _ -> () );
  Fun.flip Hashtbl.iter store2.binds @@ fun key values_2 ->
  let values_1 = get store1 key in
  replace store1 key (Node.Set.union values_1 values_2)
