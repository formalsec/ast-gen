open Graphjs_base

open struct
  let search (locations : string list) (file : string) : string option =
    Fun.flip List.find_map locations (fun dir ->
        let path = Filename.concat dir file in
        if Sys.file_exists path then Some path else None )

  let taint_config_site : string list = Site.Sites.config
end

let default_taint_config () =
  match search taint_config_site "config.json" with
  | Some file -> file
  | None -> Log.fail "unable to find the default config.js file"

include Config

let mode : Mode.t t = static Mode.SingleFile
