let search (locations : string list) (filename : string) : string option =
  Fun.flip List.find_map locations (fun dir ->
      let path = Filename.concat dir filename in
      if Sys.file_exists path then Some path else None )

let default_jsmodel () : Fpath.t =
  match search Site.Sites.config "jsmodel.jsonc" with
  | Some file -> Fpath.v file
  | None -> Log.fail "unable to find the default jsmodel file"
