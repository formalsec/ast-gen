open Graphjs_query

module Entry = struct
  type t =
    { cwe : string
    ; file : string
    ; line : int
    ; ext : bool
    }

  let main (entry : t) : bool = not entry.ext

  let create (cwe : string) (file : string) (line : int) (ext : bool) : t =
    { cwe; file; line; ext }

  let of_vuln (vuln : Vulnerability.t) : t =
    let cwe = Vulnerability.Cwe.str vuln.cwe in
    let file = vuln.node.at.file in
    let line = vuln.line in
    create cwe file line false

  let equal (entry1 : t) (entry2 : t) : bool =
    String.equal entry1.cwe entry2.cwe
    && String.equal entry1.file entry2.file
    && Int.equal entry1.line entry2.line

  let pp (ppf : Fmt.t) (entry : t) : unit =
    Fmt.fmt ppf "{@\n@[<v 2>  ";
    Fmt.fmt ppf "\"cwe\": %S," entry.cwe;
    Fmt.fmt ppf "@\n\"file\": %S," entry.file;
    Fmt.fmt ppf "@\n\"line\": %d," entry.line;
    Fmt.fmt ppf "@\n\"extended\": %b@]" entry.ext;
    Fmt.fmt ppf "@\n}"

  let str (entry : t) : string = Fmt.str "%a" pp entry
end

type t = Entry.t list

let pp (ppf : Fmt.t) (vulns : t) : unit =
  Fmt.fmt ppf "[@\n@[<v 2>  %a@]@\n]" Fmt.(pp_lst !>",@\n" Entry.pp) vulns

let parse_vuln_list (ext : bool) (expected : Json.t) (acc : t) : t =
  let expected_vulns = Json.to_list expected in
  Fun.flip2 List.fold_left acc expected_vulns (fun acc vuln ->
      let kind = Json.member "vuln_type" vuln |> Json.to_string in
      let file = Json.member "file" vuln |> Json.to_string in
      let line = Json.member "sink_lineno" vuln |> Json.to_int in
      let vuln = Entry.create kind file line ext in
      vuln :: acc )

let parse_unsafe (expected : Json.t) (extended : Json.t option) : t =
  let vulns = parse_vuln_list false expected [] in
  Option.fold extended ~none:vulns ~some:(fun extended' ->
      parse_vuln_list true extended' vulns )

let parse (expected : Json.t) (extended : Json.t option) : t Exec.result =
  try Ok (parse_unsafe expected extended)
  with _ -> Exec.error "Unable to parse the expected query results."
