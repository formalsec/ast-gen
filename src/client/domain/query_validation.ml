open Graphjs_query
module Expected = Query_expected.Entry

type t =
  { tp : int
  ; fp : int
  ; tfp : int
  ; e_tp : int
  ; e_tfp : int
  }

let default =
  let dflt = { tp = 0; fp = 0; tfp = 0; e_tp = 0; e_tfp = 0 } in
  fun () -> dflt

let create (expected : Expected.t list) : t =
  let e_tfp = List.length (List.filter Expected.ext expected) in
  let e_tp = List.length expected - e_tfp in
  { (default ()) with e_tp; e_tfp }

let tp (valid : t) : t = { valid with tp = valid.tp + 1 }
let fp (valid : t) : t = { valid with fp = valid.fp + 1 }
let tfp (valid : t) : t = { valid with tfp = valid.tfp + 1 }
let fn (valid : t) : int = valid.tp + valid.tfp

let pp (ppf : Fmt.t) (valid : t) : unit =
  Fmt.fmt ppf "True Positives: %d@\n" valid.tp;
  Fmt.fmt ppf "False Positives: %d@\n" valid.fp;
  Fmt.fmt ppf "True False Positives: %d@\n@\n" valid.tfp;
  Fmt.fmt ppf "False Negatives: %d@\n" (max (valid.tp - valid.e_tp) 0);
  Fmt.fmt ppf "True False Negatives: %d" (max (valid.tfp - valid.e_tfp) 0)

let str (valid : t) : string = Fmt.str "%a" pp valid

let validate (expected : Expected.t list) (vulns : Vulnerability.Set.t) : t =
  let valid = create expected in
  Fun.flip2 Vulnerability.Set.fold vulns valid (fun vuln valid' ->
      let vuln' = Expected.of_vuln vuln in
      let matched = List.find_all (Expected.equal vuln') expected in
      if List.is_empty matched then fp valid'
      else if List.exists Expected.ext matched then tfp valid'
      else tp valid' )
