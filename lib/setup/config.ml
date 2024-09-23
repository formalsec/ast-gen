open Yojson.Basic
open Yojson.Basic.Util

type package =
  { package : string
  ; args : int list
  }

type package_source =
  { source : string
  ; packages : package list
  }

type package_sink =
  { sink : string
  ; packages : package list
  }

type function_sink =
  { sink : string
  ; args : int list
  }

type new_sink =
  { sink : string
  ; args : int list
  }

type t =
  { package_sources : package_source list
  ; package_sinks : package_sink list
  ; function_sinks : function_sink list
  ; new_sinks : new_sink list
  }

(* -------- C O N F I G   F U N C T I O N S -------- *)

let to_package (package : Yojson.Basic.t) : package =
  let package_name = package |> member "package" |> to_string in
  let args = List.map to_int (package |> member "args" |> to_list) in
  { package = package_name; args }

let read_source (package_sources : package_source list ref)
    (source : Yojson.Basic.t) : unit =
  let source_name = source |> member "source" |> to_string in
  let source_type = source |> member "type" |> to_string in
  match source_type with
  | "package" ->
    let packages' = source |> member "packages" |> to_list in
    let packages = List.map to_package packages' in
    let package_source : package_source = { source = source_name; packages } in
    package_sources := package_source :: !package_sources
  | _ -> failwith ("[ERROR] Source type " ^ source_type ^ " not allowed")

let read_sink (package_sinks : package_sink list ref)
    (function_sinks : function_sink list ref) (new_sinks : new_sink list ref)
    (sink : Yojson.Basic.t) : unit =
  let sink_name = sink |> member "sink" |> to_string in
  let sink_type = sink |> member "type" |> to_string in
  match sink_type with
  | "package" ->
    let packages' = sink |> member "packages" |> to_list in
    let packages = List.map to_package packages' in
    let package_sink : package_sink = { sink = sink_name; packages } in
    package_sinks := package_sink :: !package_sinks
  | "function" ->
    let args = List.map to_int (sink |> member "args" |> to_list) in
    let function_sink : function_sink = { sink = sink_name; args } in
    function_sinks := function_sink :: !function_sinks
  | "new" ->
    let args = List.map to_int (sink |> member "args" |> to_list) in
    let new_sink : new_sink = { sink = sink_name; args } in
    new_sinks := new_sink :: !new_sinks
  | _ -> failwith ("[ERROR] Sink type " ^ sink_type ^ " not allowed")

let read (config_path : string) : t =
  let package_sources : package_source list ref = ref [] in
  let package_sinks : package_sink list ref = ref [] in
  let function_sinks : function_sink list ref = ref [] in
  let new_sinks : new_sink list ref = ref [] in
  let config = from_file config_path in
  let read_source' = read_source package_sources in
  let read_sink' = read_sink package_sinks function_sinks new_sinks in
  let read_sink'' (_, sinks) = List.iter read_sink' (to_list sinks) in
  let sources = member "sources" config in
  if sources != `Null then List.iter read_source' (to_list sources);
  let sinks = member "sinks" config in
  if sinks != `Null then List.iter read_sink'' (to_assoc sinks);
  { package_sources = !package_sources
  ; package_sinks = !package_sinks
  ; function_sinks = !function_sinks
  ; new_sinks = !new_sinks
  }

let add_function_sink (config : t) (function_sink : function_sink) : t =
  { config with function_sinks = function_sink :: config.function_sinks }
[@@inline]

let get_package_sink (config : t) (package : string) (property : string) :
    package option =
  let filter_pkg_f pkg = String.equal pkg.package package in
  let filter_pkg_sink_f (pkg : package_sink) = String.equal pkg.sink property in
  let package_sinks = List.filter filter_pkg_sink_f config.package_sinks in
  Option.apply ~default:None
    (fun pkg_sink ->
      List.filter filter_pkg_f pkg_sink.packages |> Fun.flip List.nth_opt 0 )
    (List.nth_opt package_sinks 0)

let get_function_sink (config : t) (function_name : string) :
    function_sink option =
  let filter_func_sink_f (func_sink : function_sink) =
    String.equal func_sink.sink function_name in
  let function_sinks = List.filter filter_func_sink_f config.function_sinks in
  List.nth_opt function_sinks 0
