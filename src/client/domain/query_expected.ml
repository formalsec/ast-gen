open Graphjs_base
open Graphjs_share
open Graphjs_query

module Entry = struct
  type t =
    { kind : string
    ; file : string
    ; line : int
    ; ext : bool
    }

  let ext (entry : t) : bool = entry.ext

  let create (kind : string) (file : string) (line : int) (ext : bool) : t =
    { kind; file; line; ext }

  let of_vuln (vuln : Vulnerability.t) : t =
    let kind = Sink_kind.str vuln.sink.kind in
    let file = vuln.node.at.file in
    let line = vuln.line in
    create kind file line false

  let equal (entry1 : t) (entry2 : t) : bool =
    String.equal entry1.kind entry2.kind
    && String.equal entry1.file entry2.file
    && Int.equal entry1.line entry2.line

  let pp (ppf : Fmt.t) (entry : t) : unit =
    Fmt.fmt ppf "{@\n@[<v 2>  ";
    Fmt.fmt ppf "\"vuln_type\": %S," entry.kind;
    Fmt.fmt ppf "@\n\"sink_file\": %S," entry.file;
    Fmt.fmt ppf "@\n\"sink_line\": %d," entry.line;
    Fmt.fmt ppf "@\n\"extended\": %b@]" entry.ext;
    Fmt.fmt ppf "@\n}"

  let str (entry : t) : string = Fmt.str "%a" pp entry
end

type t = Entry.t list

let pp (ppf : Fmt.t) (vulns : t) : unit =
  Fmt.fmt ppf "[@\n@[<v 2>  %a@]@\n]" Fmt.(pp_lst !>"@\n" Entry.pp) vulns

let parse_vuln_list (ext : bool) (expected : Json.t) (acc : t) : t =
  let expected_vulns = Json.to_list expected in
  Fun.flip2 List.fold_left acc expected_vulns (fun acc vuln ->
      let kind = Json.member "vuln_type" vuln |> Json.to_string in
      let file = Json.member "sink_file" vuln |> Json.to_string in
      let line = Json.member "sink_lineno" vuln |> Json.to_string in
      let line' = int_of_string line in
      let vuln = Entry.create kind file line' ext in
      vuln :: acc )

let parse (expected : Json.t) (extended : Json.t option) : t =
  let vulns = parse_vuln_list false expected [] in
  Option.fold extended ~none:vulns ~some:(fun extended' ->
      parse_vuln_list true extended' vulns )

module Confirmation = struct
  type expected =
    { tp : int
    ; tfp : int
    }

  type t =
    { exp : expected
    ; tp : int
    ; fp : int
    ; tfp : int
    }

  let default =
    let exp = { tp = 0; tfp = 0 } in
    let dflt = { exp; tp = 0; fp = 0; tfp = 0 } in
    fun () -> dflt

  let create (expected : Entry.t list) : t =
    let tfp = List.length (List.filter Entry.ext expected) in
    let tp = List.length expected - tfp in
    { (default ()) with exp = { tp; tfp } }

  let tp (confirm : t) : t = { confirm with tp = confirm.tp + 1 }
  let fp (confirm : t) : t = { confirm with fp = confirm.fp + 1 }
  let tfp (confirm : t) : t = { confirm with tfp = confirm.tfp + 1 }

  let pp (ppf : Fmt.t) (confirm : t) : unit =
    Fmt.fmt ppf "True Positives: %d@\n" confirm.tp;
    Fmt.fmt ppf "False Positives: %d@\n" confirm.fp;
    Fmt.fmt ppf "True False Positives: %d@\n" confirm.tfp

  let str (confirm : t) : string = Fmt.str "%a" pp confirm

  let compute (expected : Entry.t list) (vulns : Vulnerability.Set.t) : t =
    let confirm = create expected in
    Fun.flip2 Vulnerability.Set.fold vulns confirm (fun vuln confirm' ->
        let vuln' = Entry.of_vuln vuln in
        let matched = List.find_all (Entry.equal vuln') expected in
        if List.is_empty matched then fp confirm'
        else if List.exists Entry.ext matched then tfp confirm'
        else tp confirm' )
end
