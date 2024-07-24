open Yojson.Basic.Util
open Auxiliary.Functions

(* -------- T Y P E S -------- *)
type package = {
  package : string;
  args    : int list 
}

type functionSink = {
  sink    : string;
  args    : int list 
}

type newSink = {
  sink    : string;
  args    : int list 
}

type packageSink = {
  sink     : string;
  packages : package list 
}

type packageSource = {
  source   : string;
  packages : package list 
}

type t = {
  functions      : functionSink  list;
  news           : newSink       list;
  packageSinks   : packageSink   list;
  packageSources : packageSource list; 
}


(* -------- C O N F I G   F U N C T I O N S -------- *)
let rec read (config_path : string) : t = 
  let functions'      : functionSink  list ref = ref [] in 
  let news'           : newSink       list ref = ref [] in 
  let packageSinks'   : packageSink   list ref = ref [] in 
  let packageSources' : packageSource list ref = ref [] in 
  let config_json = Yojson.Basic.from_file config_path in
  
  let sinks = config_json |> member "sinks" in
  if sinks != `Null then ( 
    List.iter (fun (_vuln_type, sinks) -> 
      let sinks = sinks |> to_list in 
      
      List.iter (fun sink -> 
        let sink_name = sink |> member "sink" |> to_string in 
        let sink_type = sink |> member "type" |> to_string in 

        match sink_type with 
          | "new" -> 
            let args = List.map (to_int) (sink |> member "args" |> to_list) in 
            let new_sink : newSink = {sink = sink_name; args = args} in 
            news' := new_sink :: !news'

          | "function" -> 
            let args = List.map (to_int) (sink |> member "args" |> to_list) in 
            let func_sink : functionSink = {sink = sink_name; args = args} in
            functions' := func_sink :: !functions'

          | "package" -> 
            let packages = List.map (to_package) (sink |> member "packages" |> to_list) in 
            let package_sink : packageSink = {sink = sink_name; packages = packages} in 
            packageSinks' := package_sink :: !packageSinks'

          | _    -> failwith ("sink type " ^ sink_type ^ " not allowed")
      ) sinks
    ) (sinks |> to_assoc)
  );

  let sources = config_json |> member "sources" in 
  if sources != `Null then (
    List.iter (fun source -> 
      let source_name = source |> member "source" |> to_string in 
      let source_type = source |> member "type"   |> to_string in

      match source_type with
        | "package" -> 
          let packages = List.map (to_package) (source |> member "packages" |> to_list) in 
          let package_source : packageSource = {source = source_name; packages = packages} in 
          packageSources' := package_source :: !packageSources'

        | _    -> failwith ("source type " ^ source_type ^ " not allowed")

    ) (sources |> to_list)
  );

  (* return *)
  { functions      = !functions'     ;
    news           = !news'          ;
    packageSinks   = !packageSinks'  ;
    packageSources = !packageSources'; }

and to_package (package_json : Yojson.Basic.t) : package = 
  let package_name = package_json |> member "package" |> to_string in 
  let args = List.map (to_int) (package_json |> member "args" |> to_list) in 
  
  (* return *)
  { package = package_name;
    args    = args  }

let add_function_sink (config : t) (sink_info : functionSink) : t = 
  {config with functions = sink_info :: config.functions}

let get_function_sink_name (sink_info : functionSink) : string = sink_info.sink

let get_function_sink_info (config : t) (func_name : string) : functionSink option = 
  let sink_infos = (List.filter (((=) func_name) << get_function_sink_name) config.functions) in 
  List.nth_opt sink_infos 0

let get_package_sink_info (config : t) (package_name : string) (method_name : string) : package option = 
  let method_sink = List.filter ( fun package_sink -> package_sink.sink = method_name ) config.packageSinks |> (flip List.nth_opt 0) in 
  map_default (fun (method_sink : packageSink) ->
    let package = List.filter (fun package -> package.package = package_name) method_sink.packages |> (flip List.nth_opt 0) in
    package
  ) None method_sink




let get_package_source_info (config : t) (package : string) (property : string) : packageSource option = 
  let source_infos = (List.filter (fun source_info -> source_info.source = property && List.exists (fun pkg -> pkg.package = package) source_info.packages) config.packageSources) in 
  List.nth_opt source_infos 0


