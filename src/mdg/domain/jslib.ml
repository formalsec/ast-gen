open Graphjs_ast

type t = (string, Node.t) Hashtbl.t

let resolve_name (file : Fpath.t option) (name : string) : string =
  let pp_file = Fmt.pp_opt (fun ppf -> Fmt.fmt ppf "#%a" Fpath.pp) in
  Fmt.str "%s%a" name pp_file file

let find_template (jslib : t) (name : string) : Node.t =
  match Hashtbl.find_opt jslib name with
  | None -> Log.fail "expecting jslib symbol with name '%s'" name
  | Some node -> node

let find_node (mdg : Mdg.t) (jslib : t) (name : string) : Node.t =
  Mdg.get_node mdg (find_template jslib name).loc

let pp (ppf : Fmt.t) (jslib : t) : unit =
  let pp_item ppf (name, l_jslib) =
    Fmt.fmt ppf "%s -> %a" name Node.pp l_jslib in
  Fmt.(pp_htbl !>"@\n") pp_item ppf jslib

let str (jslib : t) : string = Fmt.str "%a" pp jslib

let create_main_taint_source (mdg : Mdg.t) (jslib : t) : Node.t =
  let l_taint = Node.create_taint_source' () in
  Hashtbl.replace jslib "taint" l_taint;
  Mdg.add_node mdg l_taint;
  l_taint

let create_toplevel_node (store : Store.t) (jslib : t) (toplevel : bool)
    (name : string) (node : Node.t) : unit =
  if toplevel then (
    Hashtbl.replace jslib name node;
    Store.set store name (Node.Set.singleton node) )

let create_tainted_sink (mdg : Mdg.t) (store : Store.t) (jslib : t)
    (toplevel : bool) (sink : Jsmodel.TaintSink.t) : Node.t =
  let taint_sink = Taint.Sink.create sink in
  let l_sink = Node.create_taint_sink' taint_sink in
  Mdg.add_node mdg l_sink;
  create_toplevel_node store jslib toplevel sink.name l_sink;
  l_sink

let create_tainted_source (mdg : Mdg.t) (store : Store.t) (jslib : t)
    (toplevel : bool) (node_f : string -> Node.t)
    (source : Jsmodel.TaintSource.t) : Node.t =
  let l_source = node_f source.name in
  let l_taint = find_node mdg jslib "taint" in
  Mdg.add_node mdg l_source;
  Mdg.add_edge mdg (Edge.create_dependency () l_taint l_source);
  create_toplevel_node store jslib toplevel source.name l_source;
  l_source

let create_function_summary (mdg : Mdg.t) (store : Store.t)
    (pcontext : 'm Pcontext.t) (jslib : t) (toplevel : bool)
    (func : Jsmodel.FunctionSummary.t) : Node.t =
  let l_func = Node.create_function' func.name in
  let floc = Pcontext.Floc.default () in
  Mdg.add_node mdg l_func;
  Pcontext.declare_func pcontext l_func floc func.body (Store.create ());
  create_toplevel_node store jslib toplevel func.name l_func;
  l_func

let create_builtin (mdg : Mdg.t) (store : Store.t) (jslib : t) (toplevel : bool)
    (name : string) : Node.t =
  let l_builtin = Node.create_builtin' name in
  Mdg.add_node mdg l_builtin;
  create_toplevel_node store jslib toplevel name l_builtin;
  l_builtin

let create_module (mdg : Mdg.t) (store : Store.t) (jslib : t)
    (file : Fpath.t option) (l_parent : Node.t option) : Node.t =
  let name = "module" in
  let name_jslib = resolve_name file "module" in
  let l_module = Node.create_object name l_parent (Region.default ()) in
  Hashtbl.replace jslib name_jslib l_module;
  Mdg.add_node mdg l_module;
  Store.set store name (Node.Set.singleton l_module);
  Fun.flip Option.iter l_parent (fun l_parent' ->
      Mdg.add_edge mdg (Edge.create l_parent' l_module Dependency) );
  l_module

let create_exports (mdg : Mdg.t) (store : Store.t) (jslib : t)
    (file : Fpath.t option) (l_parent : Node.t option) : Node.t =
  let name = "exports" in
  let prop = Property.Static "exports" in
  let name_module = resolve_name file "module" in
  let name_jslib = resolve_name file "exports" in
  let l_module = find_node mdg jslib name_module in
  let l_exports = Node.create_object name l_parent (Region.default ()) in
  Hashtbl.replace jslib name_jslib l_exports;
  Mdg.add_node mdg l_exports;
  Mdg.add_edge mdg (Edge.create l_module l_exports (Property prop));
  Store.set store name (Node.Set.singleton l_exports);
  l_exports

let initialize_component ?(toplevel = true) ?(node_f = Node.create_object')
    (mdg : Mdg.t) (store : Store.t) (pcontext : 'm Pcontext.t) (jslib : t)
    (component : Jsmodel.Component.t) : Node.t =
  match component with
  | `Sink sink -> create_tainted_sink mdg store jslib toplevel sink
  | `Source source ->
    create_tainted_source mdg store jslib toplevel node_f source
  | `Function func ->
    create_function_summary mdg store pcontext jslib toplevel func

let initialize_builtin_self (mdg : Mdg.t) (store : Store.t)
    (pcontext : 'm Pcontext.t) (jslib : t) (builtin : Jsmodel.Collection.t) :
    Node.t =
  match builtin.self with
  | None -> create_builtin mdg store jslib true builtin.name
  | Some self ->
    let node_f = Node.create_builtin' in
    let self' = Jsmodel.Component.rename builtin.name self in
    initialize_component ~node_f mdg store pcontext jslib self'

let initialize_builtin (mdg : Mdg.t) (store : Store.t)
    (pcontext : 'm Pcontext.t) (jslib : t) (builtin : Jsmodel.Collection.t) :
    unit =
  let l_builtin = initialize_builtin_self mdg store pcontext jslib builtin in
  let component_f = initialize_component ~toplevel:false in
  Fun.flip List.iter builtin.props (fun component ->
      let name = Jsmodel.Component.name component in
      let prop = Property.Static name in
      let l_prop = component_f mdg store pcontext jslib component in
      Mdg.add_edge mdg (Edge.create_property prop l_builtin l_prop) )

let create (mdg : Mdg.t) (store : Store.t) (pcontext : 'm Pcontext.t)
    (jsmodel : Jsmodel.t) : t =
  let jslib = Hashtbl.create Config.(!dflt_htbl_sz) in
  ignore (create_main_taint_source mdg jslib);
  Fun.flip List.iter jsmodel.language (fun component ->
      ignore (initialize_component mdg store pcontext jslib component) );
  Fun.flip List.iter jsmodel.builtins (fun builtin ->
      ignore (initialize_builtin mdg store pcontext jslib builtin) );
  jslib

let initialize (mdg : Mdg.t) (store : Store.t) (jslib : t)
    (file : Fpath.t option) (l_parent : Node.t option) : unit =
  ignore (create_module mdg store jslib file l_parent);
  ignore (create_exports mdg store jslib file l_parent)

let exported_object ?(mrel : Fpath.t option) (mdg : Mdg.t) (jslib : t) :
    Node.Set.t =
  find_node mdg jslib (resolve_name mrel "module")
  |> Mdg.(object_tail_versions mdg)
  |> Node.Set.map_flat (Fun.flip (Mdg.object_static_lookup mdg) "exports")
  |> Node.Set.map_flat Mdg.(object_tail_versions mdg)
