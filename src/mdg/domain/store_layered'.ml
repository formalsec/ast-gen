module Map = Map.Make (String)

type t =
  { parent : t option
  ; scope : Node.Set.t Map.t
  }

let create () : t = { parent = None; scope = Map.empty }
let enter sto = { parent = Some sto; scope = Map.empty }
let leave sto = sto.parent

let protect sto f =
  let () = f (enter sto) in
  (* discards everything done in f *)
  sto

let copy (store : t) : t =
  (* Hashtbl.copy store *)
  (* assert false *)
  store

let equal ({ scope = store1; _ } : t) ({ scope = store2; _ } : t) =
  (* Hashtbl.equal Node.Set.equal store1 store2 *)
  (* Immutable datastrctures should only be equal when physically equal. Right? *)
  store1 == store2

(** When [name] does not exist it returns Node.Set.empty *)
let rec find ({ parent; scope } : t) (name : string) : Node.Set.t =
  match Map.find_opt name scope with
  | Some set -> set
  | None -> begin
    match parent with
    | None -> Node.Set.empty
    | Some parent ->
      (* TODO: Add the value here to avoid traversing the parents in the future? *)
      find parent name
  end

let replace ({ parent; scope } : t) (name : string) (nodes : Node.Set.t) : t =
  { parent; scope = Map.add name nodes scope }

let pp (ppf : Fmt.t) (store : t) : unit =
  let pp_bind ppf (name, ls_value) =
    Fmt.fmt ppf "%s -> %a" name Node.Set.pp ls_value in
  let iter f = Map.iter (fun k v -> f (k, v)) in
  Fmt.(pp_iter iter !>"@\n" pp_bind) ppf store.scope

let str (store : t) : string = Fmt.str "%a" pp store

let rec strong_update ({ parent; scope } as sto : t) (old : Node.t)
    (new_ : Node.t) : t =
  (* let replace_f l_value = if Node.equal l_old l_value then l_new else l_value in *)
  (* Fun.flip Hashtbl.iter store (fun name ls_value -> *)
  (*     replace store name (Node.Set.map replace_f ls_value) ) *)
  let scope' =
    Map.map
      (fun nodes ->
        (* If orig is not in the set just return the same set *)
        if not (Node.Set.mem old nodes) then nodes
        else
          (* Otherwise, replace the original node with the new one in this set *)
          Node.Set.(add new_ (diff nodes (singleton old))) )
      scope in
  match parent with
  | None -> { sto with scope = scope' }
  | Some parent ->
    { parent = Some (strong_update parent old new_); scope = scope' }

let weak_update ({ scope; _ } as store : t) (old : Node.t) (new_ : Node.Set.t) :
    t =
  (* let replace_f l_value acc = *)
  (*   if Node.equal l_old l_value then Node.Set.union ls_new acc *)
  (*   else Node.Set.add l_value acc in *)
  (* Fun.flip Hashtbl.iter store (fun name ls_value -> *)
  (*     replace store name (Node.Set.fold replace_f ls_value Node.Set.empty) ) *)
  let scope' =
    Map.map
      (fun nodes ->
        if not (Node.Set.mem old nodes) then nodes
        else
          (* FIXME: Confirm with André. This is not exactly what was above, because above it removes the l_old  *)
          Node.Set.union new_ nodes )
      scope in
  { store with scope = scope' }

let lub ({ scope = scope_a; _ } as store_a : t) ({ scope = scope_b; _ } : t) : t
    =
  (* Fun.flip Hashtbl.iter store2 (fun name ls_value2 -> *)
  (*     let ls_value1 = find store1 name in *)
  (*     replace store1 name (Node.Set.union ls_value1 ls_value2) ); *)
  (* store1 *)
  { store_a with
    scope =
      (* FIXME: I think this is computationally worse than the one above *)
      Map.merge
        (fun _name a b ->
          match (a, b) with
          | (Some a, Some b) -> Some (Node.Set.union a b)
          | ((Some _ | None), _) -> a )
        scope_a scope_b
  }
