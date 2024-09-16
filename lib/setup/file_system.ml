let rec create_dir (path : string) : unit =
  match String.rindex_opt path '/' with
  | Some index ->
      let parent = String.sub path 0 index in
      if not (Sys.file_exists parent) then (
        create_dir parent;
        Unix.mkdir parent 0o755)
  | None -> ()

let clean_dir (path : string) : unit =
  let rec clean_dir' (path : string) (parent : bool) : unit =
    if Sys.file_exists path then
      if Sys.is_directory path then (
        Sys.readdir path
        |> Array.iter (fun name -> clean_dir' (Filename.concat path name) false);
        if not parent then Unix.rmdir path)
      else Sys.remove path
  in
  clean_dir' path true

let write_to_file (file : string) (contents : string) =
  let oc = open_out file in
  output_string oc contents;
  close_out oc

let run_command (command : string) : string =
  let ic = Unix.open_process_in command in
  let buf = Buffer.create 16 in
  (try
     while true do
       Buffer.add_channel buf ic 1
     done
   with End_of_file -> ());
  close_in ic;
  Buffer.contents buf

let run_command' (command : Bos.Cmd.t) =
  let open Graphjs_std.Result in
  let run_out = Bos.OS.Cmd.run_out command in
  let* out_string, (_, status) = Bos.OS.Cmd.out_string run_out in
  (* FIXME: is the error in the out_string or `stderr`? I forget *)
  match status with `Exited 0 -> Ok out_string | _ -> Error (`Msg out_string)

let real_path : string -> string = Unix.realpath
let file_name : string -> string = Filename.basename
