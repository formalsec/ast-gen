open struct
  let search (location : string list) (file : string) : string option =
    List.find_map
      (fun dir ->
        let path = Filename.concat dir file in
        if Sys.file_exists path then Some path else None )
      location

  let config_path : string list = Site.Sites.config
end

let config () : Fpath.t =
  match search config_path "config.json" with
  | Some file -> Fpath.v file
  | None -> failwith "Could not find 'config.json' in share site"
