open Graphjs_ast

module Package = struct
  type t =
    | Built of Node.t
    | Template of Jsmodel.Collection.t

  let pp (ppf : Fmt.t) (package : t) : unit =
    match package with
    | Built node -> Node.pp ppf node
    | Template template -> Jsmodel.Collection.pp ppf template

  let str (package : t) : string = Fmt.str "%a" pp package
end

type t = (string, Package.t) Hashtbl.t

let create (jsmodel : Jsmodel.t) : t =
  let npmlib = Hashtbl.create Config.(!dflt_htbl_sz) in
  Fun.flip List.iter jsmodel.packages (fun package ->
      Hashtbl.replace npmlib package.name (Package.Template package) );
  npmlib

let find_template (npmlib : t) (name : string) : Node.t =
  match Hashtbl.find_opt npmlib name with
  | Some (Built node) -> node
  | None | Some (Template _) ->
    Log.fail "expecting  constructed npmlib symbol with name '%s'" name

let find_node (mdg : Mdg.t) (npmlib : t) (name : string) : Node.t =
  Mdg.get_node mdg (find_template npmlib name).loc

let find_node_opt (mdg : Mdg.t) (npmlib : t) (name : string) : Node.t option =
  try Some (find_node mdg npmlib name) with _ -> None

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
  build_node mdg (fun _ _ -> Node.create_module' name)

let build_taint_sink (mdg : Mdg.t) (sink : Jsmodel.TaintSink.t)
    (l_parent : Node.t option) : Node.t =
  let taint_sink = Taint.Sink.create sink in
  build_node mdg (Node.create_taint_sink taint_sink) l_parent

let build_taint_source (node_f : Mdg.t -> string -> Node.t option -> Node.t)
    (mdg : Mdg.t) (jslib : Jslib.t) (source : Jsmodel.TaintSource.t)
    (l_parent : Node.t option) : Node.t =
  let l_source = node_f mdg source.name l_parent in
  let l_taint = Jslib.find_node mdg jslib "taint" in
  Mdg.add_edge mdg (Edge.create_dependency () l_taint l_source);
  l_source

let build_function_summary (mdg : Mdg.t) (pcontext : 'm Pcontext.t)
    (func : Jsmodel.FunctionSummary.t) (l_parent : Node.t option) : Node.t =
  let l_func = build_node mdg (Node.create_function func.name) l_parent in
  let floc = Pcontext.Floc.default () in
  Pcontext.declare_func pcontext l_func floc func.body pcontext.store;
  l_func

let build_package_self (mdg : Mdg.t) (pcontext : 'm Pcontext.t)
    (jslib : Jslib.t) (package : Jsmodel.Collection.t) : Node.t =
  match package.self with
  | None -> build_module mdg package.name None
  | Some self -> (
    match Jsmodel.Component.rename package.name self with
    | `Sink sink -> build_taint_sink mdg sink None
    | `Source source -> build_taint_source build_module mdg jslib source None
    | `Function func -> build_function_summary mdg pcontext func None )

let build_package_prop (mdg : Mdg.t) (pcontext : 'm Pcontext.t)
    (jslib : Jslib.t) (component : Jsmodel.Component.t)
    (l_parent : Node.t option) : Node.t =
  match component with
  | `Sink sink -> build_taint_sink mdg sink l_parent
  | `Source source -> build_taint_source build_object mdg jslib source l_parent
  | `Function func -> build_function_summary mdg pcontext func l_parent

let build_unknown_package (mdg : Mdg.t) (npmlib : t) (name : string) : Node.t =
  let l_npmlib = build_module mdg name None in
  Hashtbl.replace npmlib name (Built l_npmlib);
  l_npmlib

let build_template_package (mdg : Mdg.t) (pcontext : 'm Pcontext.t)
    (jslib : Jslib.t) (npmlib : t) (name : string)
    (package : Jsmodel.Collection.t) : Node.t =
  let l_npmlib = build_package_self mdg pcontext jslib package in
  let l_parent = Some l_npmlib in
  Fun.flip List.iter package.props (fun component ->
      let name = Jsmodel.Component.name component in
      let prop = Property.Static name in
      let l_prop = build_package_prop mdg pcontext jslib component l_parent in
      Mdg.add_edge mdg (Edge.create_property prop l_npmlib l_prop) );
  Hashtbl.replace npmlib name (Built l_npmlib);
  l_npmlib

let resolve (mdg : Mdg.t) (pcontext : 'm Pcontext.t) (jslib : Jslib.t)
    (npmlib : t) (name : string) : Node.t =
  match Hashtbl.find_opt npmlib name with
  | None -> build_unknown_package mdg npmlib name
  | Some (Built l_npmlib) -> l_npmlib
  | Some (Template template) ->
    build_template_package mdg pcontext jslib npmlib name template
