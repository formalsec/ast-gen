open Graphjs_base

open struct
  let taint_config_site : string list = Site.Sites.config

  let search (locations : string list) (filename : string) : string option =
    Fun.flip List.find_map locations (fun dir ->
        let path = Filename.concat dir filename in
        if Sys.file_exists path then Some path else None )
end

let default_taint_config () =
  match search taint_config_site "config.json" with
  | Some file -> Fpath.v file
  | None -> Log.fail "unable to find the default config.js file"

include Config

let mode = static Mode.SingleFile
