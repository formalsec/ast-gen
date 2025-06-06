open Graphjs_ast

module Package = struct
  type t =
    | Built of Node.t
    | Template of Jsmodel.Package.t

  let pp (ppf : Fmt.t) (package : t) : unit =
    match package with
    | Built node -> Node.pp ppf node
    | Template template -> Jsmodel.Package.pp ppf template

  let str (package : t) : string = Fmt.str "%a" pp package
end

type t = (string, Package.t) Hashtbl.t

let create (jsmodel : Jsmodel.t) : t =
  let npmlib = Hashtbl.create Config.(!dflt_htbl_sz) in
  Fun.flip List.iter jsmodel.packages (fun package ->
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

let build_sink (mdg : Mdg.t) (id_f : Taint.Id.maker) (sink : Jsmodel.Sink.t) :
    Node.t option -> Node.t =
  let taint_sink = Taint.Sink.create id_f sink in
  build_node mdg (Node.create_taint_sink taint_sink)

let build_source (node_f : Mdg.t -> string -> Node.t option -> Node.t)
    (mdg : Mdg.t) (jslib : Jslib.t) (id_f : Taint.Id.maker)
    (source : Jsmodel.Source.t) (l_parent : Node.t option) : Node.t =
  let taint_source = Taint.Source.create id_f source in
  let name = Taint.Source.name taint_source in
  let l_source = node_f mdg name l_parent in
  let l_taint = Jslib.find mdg jslib "taint" in
  Mdg.add_edge mdg (Edge.create_dependency () l_taint l_source);
  l_source

let build_package_self (mdg : Mdg.t) (jslib : Jslib.t)
    (package : Jsmodel.Package.t) : Node.t =
  let id_f = Taint.Id.package_self in
  match package.self with
  | None -> build_module mdg package.name None
  | Some self -> (
    match self with
    | `Sink sink -> build_sink mdg id_f sink None
    | `Source source -> build_source build_module mdg jslib id_f source None )

let build_package_prop (id_f : Taint.Id.maker) (mdg : Mdg.t) (jslib : Jslib.t)
    (component : Jsmodel.Component.t) (l_parent : Node.t option) : Node.t =
  match component with
  | `Sink sink -> build_sink mdg id_f sink l_parent
  | `Source source -> build_source build_object mdg jslib id_f source l_parent

let build_unknown_package (mdg : Mdg.t) (npmlib : t) (name : string) : Node.t =
  let l_npmlib = build_module mdg name None in
  Hashtbl.replace npmlib name (Built l_npmlib);
  l_npmlib

let build_template_package (mdg : Mdg.t) (jslib : Jslib.t) (npmlib : t)
    (name : string) (package : Jsmodel.Package.t) : Node.t =
  let l_npmlib = build_package_self mdg jslib package in
  let l_parent = Some l_npmlib in
  Fun.flip List.iter package.props (fun component ->
      let id_f = Taint.Id.package_prop package.name in
      let name = Jsmodel.Component.name component in
      let prop = Property.Static name in
      let l_prop = build_package_prop id_f mdg jslib component l_parent in
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
