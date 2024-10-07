include Stdlib.Hashtbl

let equals (eq_f : 'b -> 'b -> bool) (htbl1 : ('a, 'b) t) (htbl2 : ('a, 'b) t) :
    bool =
  let check_key_f key v1 =
    match find_opt htbl2 key with Some v2 -> eq_f v1 v2 | None -> false in
  if length htbl1 != length htbl2 then false
  else fold (fun key v acc -> acc && check_key_f key v) htbl1 true
