open Graphjs_base
open Graphjs_share

module Template = struct
  type el =
    | Source of Tainted.source
    | Sink of Tainted.sink

  let pp_el (ppf : Fmt.t) (el : el) : unit =
    match el with
    | Source source -> Tainted.pp_source ppf source
    | Sink sink -> Tainted.pp_sink ppf sink

  type t =
    { sources : Tainted.source list
    ; sinks : Tainted.sink list
    }

  let create () : t = { sources = []; sinks = [] }

  let add_source (source : Tainted.source) (template : t) : t =
    { template with sources = source :: template.sources }

  let add_sink (sink : Tainted.sink) (template : t) : t =
    { template with sinks = sink :: template.sinks }

  let to_list (template : t) : el list =
    List.map (fun source -> Source source) template.sources
    @ List.map (fun sink -> Sink sink) template.sinks

  let pp (ppf : Fmt.t) (template : t) : unit =
    Fmt.fmt ppf "@\n@[<v 2>  %a@]" Fmt.(pp_lst !>"@\n" pp_el) (to_list template)

  let str (template : t) : string = Fmt.str "%a" pp template
end

type package =
  | Built of Node.t
  | Template of Template.t

type t = (string, package) Hashtbl.t

let set_source (npm : t) (package_source : Taint_config.package_source) : unit =
  Fun.flip List.iter package_source.packages (fun package ->
      let source = Tainted.package_source package.package package_source in
      match Hashtbl.find_opt npm package.package with
      | None ->
        let template = Template.create () |> Template.add_source source in
        Hashtbl.replace npm package.package (Template template)
      | Some (Template template) ->
        let template' = Template.add_source source template in
        Hashtbl.replace npm package.package (Template template')
      | Some (Built _) ->
        Log.fail "unexpected built npm package during initialization" )

let set_sink (npm : t) (package_sink : Taint_config.package_sink) : unit =
  Fun.flip List.iter package_sink.packages (fun package ->
      let sink = Tainted.package_sink package.package package_sink in
      match Hashtbl.find_opt npm package.package with
      | None ->
        let template = Template.create () |> Template.add_sink sink in
        Hashtbl.replace npm package.package (Template template)
      | Some (Template template) ->
        let template' = Template.add_sink sink template in
        Hashtbl.replace npm package.package (Template template')
      | Some (Built _) ->
        Log.fail "unexpected built npm package during initialization" )

let create (tconf : Taint_config.t) : t =
  let npm = Hashtbl.create Config.(!dflt_htbl_sz) in
  List.iter (set_source npm) tconf.package_sources;
  List.iter (set_sink npm) tconf.package_sinks;
  npm

let pp_package (ppf : Fmt.t) (package : package) : unit =
  match package with
  | Built node -> Node.pp ppf node
  | Template template -> Template.pp ppf template

let pp (ppf : Fmt.t) (npm : t) : unit =
  let pp_pkg ppf (name, package) =
    Fmt.fmt ppf "%S: %a" name pp_package package in
  Fmt.(pp_htbl !>"@\n") pp_pkg ppf npm

let str (npm : t) : string = Fmt.str "%a" pp npm

let resolve (_npm : t) (_mdg : Mdg.t) (package : string) : Node.t option =
  Log.debug "Resolving package %S..." package;
  None
