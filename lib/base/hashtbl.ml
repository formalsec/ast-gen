include Hashtbl

let equals (eq_f : 'b -> 'b -> bool) (htbl1 : ('a, 'b) Hashtbl.t)
    (htbl2 : ('a, 'b) Hashtbl.t) : bool =
  let check_htbl_key_f key v1 =
    match Hashtbl.find_opt htbl2 key with
    | Some v2 -> eq_f v1 v2
    | None -> false in
  if Hashtbl.length htbl1 != Hashtbl.length htbl2 then false
  else Hashtbl.fold (fun key v acc -> acc && check_htbl_key_f key v) htbl1 true
