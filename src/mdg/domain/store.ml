open Graphjs_ast

open struct
  let id_gen = Generator.of_numbers ~init:1 ()
end

let reset_generator () : unit = id_gen.reset ()

module Tag = struct
  type t =
    | Var
    | Let
    | Const
    | Outer

  let create (kind : LeftValueKind.t) : t =
    match kind with Var -> Var | Let -> Let | Const -> Const | None -> Outer

  let equal (tag1 : t) (tag2 : t) : bool = tag1 = tag2

  let pp (ppf : Fmt.t) (tag : t) : unit =
    match tag with
    | Var -> Fmt.pp_str ppf "<var>"
    | Let -> Fmt.pp_str ppf "<let>"
    | Const -> Fmt.pp_str ppf "<const>"
    | Outer -> Fmt.pp_str ppf "<outer>"

  let str (tag : t) : string = Fmt.str "%a" pp tag
end

module Entry = struct
  type t = Tag.t * Node.Set.t

  let equal ((tag1, ls_entry1) : t) ((tag2, ls_entry2) : t) : bool =
    Tag.equal tag1 tag2 && Node.Set.equal ls_entry1 ls_entry2

  let pp (ppf : Fmt.t) ((tag, ls_entry) : t) : unit =
    Fmt.fmt ppf "%a%a" Tag.pp tag Node.Set.pp ls_entry

  let str (entry : t) : string = Fmt.str "%a" pp entry
end

type t =
  { id : int
  ; map : (string, Entry.t) Hashtbl.t
  ; scope : scope
  }

and scope =
  | Global
  | Block of t
  | Function of t

let create () : t =
  { id = id_gen.next ()
  ; map = Hashtbl.create Config.(!dflt_htbl_sz)
  ; scope = Global
  }

let copy_flat (store : t) : t =
  { id = id_gen.next (); map = Hashtbl.copy store.map; scope = store.scope }

let equal_flat (store1 : t) (store2 : t) : bool =
  Hashtbl.equal Entry.equal store1.map store2.map

let rec copy (store : t) : t =
  let scope_f = function
    | Global -> Global
    | Block store' -> Block (copy store')
    | Function store' -> Function (copy store') in
  { id = id_gen.next ()
  ; map = Hashtbl.copy store.map
  ; scope = scope_f store.scope
  }

let rec equal (store1 : t) (store2 : t) : bool =
  let scope_f = function
    | (Global, Global) -> true
    | (Block store1, Block store2) -> equal store1 store2
    | (Function store1, Function store2) -> equal store1 store2
    | _ -> false in
  equal_flat store1 store2 && scope_f (store1.scope, store2.scope)

let rec within (store : t) (store' : t) : bool =
  match store'.scope with
  | _ when store.id == store'.id -> true
  | Block store'' -> within store store''
  | Global | Function _ -> false

let find (store : t) (name : string) : Entry.t option =
  Hashtbl.find_opt store.map name

let replace (store : t) (name : string) (entry : Entry.t) : unit =
  Hashtbl.replace store.map name entry

let set (store : t) (name : string) (ls_entry : Node.Set.t) : unit =
  Hashtbl.replace store.map name (Var, ls_entry)

let update (store : t) (name : string) ((tag, _) : Entry.t)
    (ls_entry : Node.Set.t) : unit =
  Hashtbl.replace store.map name (tag, ls_entry)

let pp (ppf : Fmt.t) (store : t) : unit =
  let pp_bind ppf (name, entry) = Fmt.fmt ppf "%s -> %a" name Entry.pp entry in
  Fmt.(pp_htbl !>"@\n" pp_bind) ppf store.map

let str (store : t) : string = Fmt.str "%a" pp store
let extend_block (store : t) : t = { (create ()) with scope = Block store }
let extend_func (store : t) : t = { (create ()) with scope = Function store }

let rec read ?(first = true) (store : t) (name : string) : Node.Set.t option =
  match (Hashtbl.find_opt store.map name, store.scope) with
  | (None, Global) -> None
  | (None, (Block store' | Function store')) ->
    Fun.flip Option.map (read ~first:false store' name) (fun ls_entry ->
        if first then replace store name (Outer, ls_entry);
        ls_entry )
  | (Some (_, ls_entry), _) -> Some ls_entry

let write (store : t) (name : string) ?(kind = LeftValueKind.None)
    (ls_entry : Node.Set.t) : unit =
  match (kind, find store name) with
  | ((Var | Let | Const), (None | Some ((Var, _) | (Let, _) | (Const, _)))) ->
    replace store name (Tag.create kind, ls_entry)
  | ((Var | Let | Const), Some ((Outer, _) as entry)) ->
    update store name entry ls_entry
  | (None, None) -> replace store name (Outer, ls_entry)
  | (None, Some entry) -> update store name entry ls_entry

let merge_func (store : t) (name : string) (entry : Entry.t) : unit =
  match entry with (Outer, _) -> replace store name entry | _ -> ()

let merge_option (store : t) (name : string) (entry : Entry.t) : unit =
  match (entry, find store name) with
  | (((Let, _) | (Const, _)), _) -> ()
  | ((((Var, _) | (Outer, _)) as entry'), None) -> replace store name entry'
  | ((Var, c), Some ((Var, p) | (Let, p) | (Const, p))) ->
    replace store name (Var, Node.Set.union c p)
  | ((Var, c), Some (Outer, p)) -> replace store name (Outer, Node.Set.union c p)
  | ((Outer, c), Some (tag, p)) -> replace store name (tag, Node.Set.union c p)

let merge_branch (store : t) (name : string) (entry1 : Entry.t option)
    (entry2 : Entry.t option) : unit =
  match (entry1, entry2) with
  | ( (None | Some ((Let, _) | (Const, _)))
    , (None | Some ((Let, _) | (Const, _))) ) ->
    ()
  | (Some entry, (None | Some ((Let, _) | (Const, _)))) ->
    merge_option store name entry
  | ((None | Some ((Let, _) | (Const, _))), Some entry) ->
    merge_option store name entry
  | (Some (Var, c1), Some (Var, c2)) ->
    replace store name (Var, Node.Set.union c1 c2)
  | (Some (Var, c1), Some (Outer, c2)) ->
    replace store name (Outer, Node.Set.union c1 c2)
  | (Some (Outer, c1), Some (Var, c2)) ->
    replace store name (Outer, Node.Set.union c1 c2)
  | (Some (Outer, c1), Some (Outer, c2)) ->
    replace store name (Outer, Node.Set.union c1 c2)

let reduce_func (store : t) (store1 : t) : t =
  Fun.flip Hashtbl.iter store1.map (fun name entry ->
      merge_func store name entry );
  store

let reduce_option (store : t) (store1 : t) : t =
  Fun.flip Hashtbl.iter store1.map (fun name entry ->
      merge_option store name entry );
  store

let reduce_branch (store : t) (store1 : t) (store2 : t) : t =
  let module SSet = Stdlib.Set.Make (String) in
  let names1 = Hashtbl.to_seq_keys store1.map |> SSet.of_seq in
  let names2 = Hashtbl.to_seq_keys store2.map |> SSet.of_seq in
  Fun.flip SSet.iter (SSet.union names1 names2) (fun name ->
      let entry1 = find store1 name in
      let entry2 = find store2 name in
      merge_branch store name entry1 entry2 );
  store

let strong_update (store : t) (l_old : Node.t) (l_new : Node.t) : unit =
  let replace_f l_value = if Node.equal l_old l_value then l_new else l_value in
  Fun.flip Hashtbl.iter store.map (fun name (tag, ls_value) ->
      replace store name (tag, Node.Set.map replace_f ls_value) )

let weak_update (store : t) (l_old : Node.t) (ls_new : Node.Set.t) : unit =
  let replace_f l_value acc =
    if Node.equal l_old l_value then Node.Set.union ls_new acc
    else Node.Set.add l_value acc in
  Fun.flip Hashtbl.iter store.map (fun name (tag, ls_value) ->
      replace store name (tag, Node.Set.fold replace_f ls_value Node.Set.empty) )
