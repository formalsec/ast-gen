open Graphjs_base
open Graphjs_share
open Graphjs_ast

module Template = struct
  type el =
    | Source of Taint.source
    | Sink of Taint.sink

  let pp_el (ppf : Fmt.t) (el : el) : unit =
    match el with
    | Source source -> Taint.pp_source ppf source
    | Sink sink -> Taint.pp_sink ppf sink

  type t =
    { name : string
    ; sources : Taint.source list
    ; sinks : Taint.sink list
    }

  let create (name : string) : t = { name; sources = []; sinks = [] }

  let add_source (source : Taint.source) (template : t) : t =
    { template with sources = source :: template.sources }

  let add_sink (sink : Taint.sink) (template : t) : t =
    { template with sinks = sink :: template.sinks }

  let to_list (template : t) : el list =
    let sources = List.map (fun source -> Source source) template.sources in
    let sinks = List.map (fun sink -> Sink sink) template.sinks in
    sources @ sinks

  let pp (ppf : Fmt.t) (template : t) : unit =
    Fmt.fmt ppf "@\n@[<v 2>  %a@]" Fmt.(pp_lst !>"@\n" pp_el) (to_list template)

  let str (template : t) : string = Fmt.str "%a" pp template
end

module Package = struct
  type t =
    | Built of Node.t
    | Template of Template.t

  let pp (ppf : Fmt.t) (package : t) : unit =
    match package with
    | Built node -> Node.pp ppf node
    | Template template -> Template.pp ppf template

  let str (package : t) : string = Fmt.str "%a" pp package
end

type t = (string, Package.t) Hashtbl.t

let set_source (npmlib : t) (p_source : Taint_config.package_source) : unit =
  Fun.flip List.iter p_source.pkgs (fun pkg ->
      let source = Taint.package_source pkg.name p_source in
      match Hashtbl.find_opt npmlib pkg.name with
      | None ->
        let template = Template.create pkg.name |> Template.add_source source in
        Hashtbl.replace npmlib pkg.name (Template template)
      | Some (Template template) ->
        let template' = Template.add_source source template in
        Hashtbl.replace npmlib pkg.name (Template template')
      | Some (Built _) ->
        Log.fail "unexpected built npm package during initialization" )

let set_sink (npmlib : t) (p_sink : Taint_config.package_sink) : unit =
  Fun.flip List.iter p_sink.pkgs (fun pkg ->
      let sink = Taint.package_sink pkg.name p_sink in
      match Hashtbl.find_opt npmlib pkg.name with
      | None ->
        let template = Template.create pkg.name |> Template.add_sink sink in
        Hashtbl.replace npmlib pkg.name (Template template)
      | Some (Template template) ->
        let template' = Template.add_sink sink template in
        Hashtbl.replace npmlib pkg.name (Template template')
      | Some (Built _) ->
        Log.fail "unexpected built npm package during initialization" )

let create (tconf : Taint_config.t) : t =
  let npmlib = Hashtbl.create Config.(!dflt_htbl_sz) in
  List.iter (set_source npmlib) tconf.p_sources;
  List.iter (set_sink npmlib) tconf.p_sinks;
  npmlib

let pp (ppf : Fmt.t) (npmlib : t) : unit =
  let pp_pkg ppf (name, package) =
    Fmt.fmt ppf "%S: %a" name Package.pp package in
  Fmt.(pp_htbl !>"@\n") pp_pkg ppf npmlib

let str (npmlib : t) : string = Fmt.str "%a" pp npmlib

let build_package_template (mdg : Mdg.t) (template : Template.t) : Node.t =
  let l_npmlib = Node.create_module template.name in
  Mdg.add_node mdg l_npmlib;
  Fun.flip List.iter template.sinks (fun sink ->
      let parent = Some l_npmlib in
      let at = Region.default () in
      let prop = Property.Static sink.name in
      let l_sink = Node.create_taint_sink sink parent at in
      Mdg.add_node mdg l_sink;
      Mdg.add_edge mdg (Edge.create_property prop l_npmlib l_sink) );
  l_npmlib

let resolve_package (npmlib : t) (mdg : Mdg.t) (package : string) :
    Node.t option =
  match Hashtbl.find_opt npmlib package with
  | None -> None
  | Some (Built l_npmlib) -> Some l_npmlib
  | Some (Template template) ->
    let l_npmlib = build_package_template mdg template in
    Hashtbl.replace npmlib package (Built l_npmlib);
    Some l_npmlib
