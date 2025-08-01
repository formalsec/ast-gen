open Graphjs_query
module Expected = Query_expected.Entry

type t =
  { tp : int
  ; tpe : int
  ; fp : int
  ; e_tp : int
  ; e_tpe : int
  }

let default =
  let dflt = { tp = 0; tpe = 0; fp = 0; e_tp = 0; e_tpe = 0 } in
  fun () -> dflt

let create (expected : Expected.t list) : t =
  let e_tp = List.length (List.filter Expected.main expected) in
  let e_tpe = List.length expected - e_tp in
  { (default ()) with e_tp; e_tpe }

let tp (valid : t) : t = { valid with tp = valid.tp + 1 }
let tpe (valid : t) : t = { valid with tpe = valid.tpe + 1 }
let fp (valid : t) : t = { valid with fp = valid.fp + 1 }

let pp (ppf : Fmt.t) (valid : t) : unit =
  Fmt.fmt ppf "True Positives: %d@\n" valid.tp;
  Fmt.fmt ppf "True Positives (Extended): %d@\n" valid.tpe;
  Fmt.fmt ppf "True Positives (All): %d@\n@\n" (valid.tp + valid.tpe);
  Fmt.fmt ppf "False Positives (True): %d@\n" valid.fp;
  Fmt.fmt ppf "False Positives (All): %d@\n@\n" (valid.tpe + valid.fp);
  Fmt.fmt ppf "False Negatives: %d@\n" (max (valid.e_tp - valid.tp) 0);
  Fmt.fmt ppf "False Negatives (Extended): %d@\n"
    (max (valid.e_tpe - valid.tpe) 0);
  Fmt.fmt ppf "False Negatives (All): %d"
    (max (valid.e_tp + valid.e_tpe - (valid.tp + valid.tpe)) 0)

let str (valid : t) : string = Fmt.str "%a" pp valid

let validate (expected : Expected.t list) (vulns : Vulnerability.Set.t) : t =
  let valid = create expected in
  Fun.flip2 Vulnerability.Set.fold vulns valid (fun vuln valid' ->
      let vuln' = Expected.of_vuln vuln in
      let matched = List.find_all (Expected.equal vuln') expected in
      if List.is_empty matched then fp valid'
      else if List.exists Expected.main matched then tp valid'
      else tpe valid' )
