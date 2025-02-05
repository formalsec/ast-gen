include Stdlib.Hashtbl

let equal (eq : 'b -> 'b -> bool) (ht1 : ('a, 'b) t) (ht2 : ('a, 'b) t) : bool =
  let check_key_f key v1 =
    match find_opt ht2 key with Some v2 -> eq v1 v2 | None -> false in
  if length ht1 != length ht2 then false
  else fold (fun key value acc -> acc && check_key_f key value) ht1 true
