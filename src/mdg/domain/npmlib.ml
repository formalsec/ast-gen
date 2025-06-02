open Graphjs_share
open Graphjs_ast

module Package = struct
  type t =
    | Built of Node.t
    | Template of Taint_config.Package.t

  let pp (ppf : Fmt.t) (package : t) : unit =
    match package with
    | Built node -> Node.pp ppf node
    | Template template -> Taint_config.Package.pp ppf template

  let str (package : t) : string = Fmt.str "%a" pp package
end

type t = (string, Package.t) Hashtbl.t

let create (tconf : Taint_config.t) : t =
  let npmlib = Hashtbl.create Config.(!dflt_htbl_sz) in
  Fun.flip List.iter tconf.packages (fun package ->
      Hashtbl.replace npmlib package.name (Package.Template package) );
  npmlib

let pp (ppf : Fmt.t) (npmlib : t) : unit =
  let pp_package ppf (name, package) =
    Fmt.fmt ppf "%S: %a" name Package.pp package in
  Fmt.(pp_htbl !>"@\n") pp_package ppf npmlib

let str (npmlib : t) : string = Fmt.str "%a" pp npmlib

let build_node (mdg : Mdg.t) (build_f : Node.t option -> Region.t -> Node.t)
    (l_parent : Node.t option) : Node.t =
  let node = build_f l_parent (Region.default ()) in
  Mdg.add_node mdg node;
  node

let build_object (mdg : Mdg.t) (name : string) : Node.t option -> Node.t =
  build_node mdg (Node.create_object name)

let build_module (mdg : Mdg.t) (name : string) : Node.t option -> Node.t =
  build_node mdg (fun _ _ -> Node.create_module name)

let build_sink (mdg : Mdg.t) (sink : Taint.Sink.t) : Node.t option -> Node.t =
  build_node mdg (Node.create_taint_sink sink)

let build_source (node_f : Mdg.t -> string -> Node.t option -> Node.t)
    (mdg : Mdg.t) (jslib : Jslib.t) (source : Taint.Source.t)
    (l_parent : Node.t option) : Node.t =
  let name = Taint.Source.name source in
  let l_source = node_f mdg name l_parent in
  let l_taint = Jslib.find mdg jslib "taint" in
  Mdg.add_edge mdg (Edge.create_dependency () l_taint l_source);
  l_source

let build_package_self (mdg : Mdg.t) (jslib : Jslib.t)
    (template : Taint_config.Package.t) : Node.t =
  match template.self with
  | None -> build_module mdg template.name None
  | Some self -> (
    match Taint.package_self template.name self with
    | Sink sink -> build_sink mdg sink None
    | Source source -> build_source build_module mdg jslib source None )

let build_package_prop (mdg : Mdg.t) (jslib : Jslib.t) (prop : Taint.t)
    (l_parent : Node.t option) : Node.t =
  match prop with
  | Sink sink -> build_sink mdg sink l_parent
  | Source source -> build_source build_object mdg jslib source l_parent

let build_unknown_package (mdg : Mdg.t) (npmlib : t) (name : string) : Node.t =
  let l_npmlib = build_module mdg name None in
  Hashtbl.replace npmlib name (Built l_npmlib);
  l_npmlib

let build_template_package (mdg : Mdg.t) (jslib : Jslib.t) (npmlib : t)
    (name : string) (template : Taint_config.Package.t) : Node.t =
  let l_npmlib = build_package_self mdg jslib template in
  let l_parent = Some l_npmlib in
  Fun.flip List.iter template.props (fun endpoint ->
      let prop = Property.Static endpoint.name in
      let taint = Taint.package_prop name endpoint in
      let l_prop = build_package_prop mdg jslib taint l_parent in
      Mdg.add_edge mdg (Edge.create_property prop l_npmlib l_prop) );
  Hashtbl.replace npmlib name (Built l_npmlib);
  l_npmlib

let resolve (mdg : Mdg.t) (jslib : Jslib.t) (npmlib : t) (name : string) :
    Node.t =
  match Hashtbl.find_opt npmlib name with
  | None -> build_unknown_package mdg npmlib name
  | Some (Built l_npmlib) -> l_npmlib
  | Some (Template template) ->
    build_template_package mdg jslib npmlib name template
