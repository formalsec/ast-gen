module Map = Map.Make (String)

type t = Node.Set.t Map.t

let create () : t = Map.empty

let copy (store : t) : t =
  (* Hashtbl.copy store *)
  (* assert false *)
  store

let equal (store_a : t) (store_b : t) =
  (* Hashtbl.equal Node.Set.equal store1 store2 *)
  (* Immutable datastrctures should only be equal when physically equal. Right? *)
  (* store1 == store2 *)
  Map.equal Node.Set.equal store_a store_b

(** When [name] does not exist it returns Node.Set.empty *)
let find (store : t) (name : string) : Node.Set.t =
  match Map.find_opt name store with Some set -> set | None -> Node.Set.empty

let replace (store : t) (name : string) (nodes : Node.Set.t) : t =
  Map.add name nodes store

let pp (ppf : Fmt.t) (store : t) : unit =
  let pp_bind ppf (name, ls_value) =
    Fmt.fmt ppf "%s -> %a" name Node.Set.pp ls_value in
  let iter f = Map.iter (fun k v -> f (k, v)) in
  Fmt.(pp_iter iter !>"@\n" pp_bind) ppf store

let str (store : t) : string = Fmt.str "%a" pp store

let strong_update (store : t) (l_old : Node.t) (l_new : Node.t) : t =
  (* let replace_f l_value = if Node.equal l_old l_value then l_new else l_value in *)
  (* Fun.flip Hashtbl.iter store (fun name ls_value -> *)
  (*     replace store name (Node.Set.map replace_f ls_value) ) *)
  Map.map
    (fun ls_value ->
      (* If orig is not in the set just return the same set *)
      if not (Node.Set.mem l_old ls_value) then ls_value
      else
        (* Otherwise, replace the original node with the new one in this set *)
        Node.Set.(add l_new (remove l_old ls_value)) )
    store

let weak_update (store : t) (l_old : Node.t) (ls_new : Node.Set.t) : t =
  (* let replace_f l_value acc = *)
  (*   if Node.equal l_old l_value then Node.Set.union ls_new acc *)
  (*   else Node.Set.add l_value acc in *)
  (* Fun.flip Hashtbl.iter store (fun name ls_value -> *)
  (*     replace store name (Node.Set.fold replace_f ls_value Node.Set.empty) ) *)
  Map.map
    (fun ls_value ->
      if not (Node.Set.mem l_old ls_value) then ls_value
      else
        (* FIXME: Confirm with André. This is not exactly what was above, because above it removes the l_old  *)
        Node.Set.(union ls_new (remove l_old ls_value)) )
    store

let lub (store_a : t) (store_b : t) : t =
  (* Fun.flip Hashtbl.iter store2 (fun name ls_value2 -> *)
  (*     let ls_value1 = find store1 name in *)
  (*     replace store1 name (Node.Set.union ls_value1 ls_value2) ); *)
  (* store1 *)
  (* FIXME: I think this is computationally worse than the one above? *)
  Map.merge
    (fun _name a b ->
      match (a, b) with
      | (Some a, Some b) -> Some (Node.Set.union a b)
      | (None, Some _) -> b
      | ((Some _ | None), None) -> a )
    store_a store_b
