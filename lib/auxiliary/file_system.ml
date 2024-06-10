let rec create_dir (path : string) : unit =
  match String.rindex_opt path '/' with
  | Some index ->
    let parent = String.sub path 0 index in
    if not (Sys.file_exists parent) then (
      create_dir parent;
      Unix.mkdir parent 0o755
    )
  | None -> ()


let write_to_file (file : string) (contents : string) =
  let oc = open_out file in
  output_string oc contents;
  close_out oc