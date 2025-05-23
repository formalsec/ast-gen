open Graphjs_base
open Graphjs_share
open Graphjs_ast

type t = (string, Node.t) Hashtbl.t

let resolve_name (file : Fpath.t option) (name : string) : string =
  let pp_file = Fmt.pp_opt (fun ppf -> Fmt.fmt ppf "#%a" Fpath.pp) in
  Fmt.str "%s%a" name pp_file file

let find_template (jslib : t) (name : string) : Node.t =
  match Hashtbl.find_opt jslib name with
  | None -> Log.fail "expecting jslib symbol with name '%s'" name
  | Some node -> node

let find (mdg : Mdg.t) (jslib : t) (name : string) : Node.t =
  Mdg.get_node mdg (find_template jslib name).loc

let pp (ppf : Fmt.t) (jslib : t) : unit =
  let pp_item ppf (name, l_jslib) =
    Fmt.fmt ppf "%s -> %a" name Node.pp l_jslib in
  Fmt.(pp_htbl !>"@\n") pp_item ppf jslib

let str (jslib : t) : string = Fmt.str "%a" pp jslib

let add_tainted_sink (mdg : Mdg.t) (store : Store.t) (jslib : t)
    (make_generic_sink_f : 'a -> Taint.sink) (generic_sink : 'a) : unit =
  let sink = make_generic_sink_f generic_sink in
  let name_jslib = resolve_name None sink.name in
  let l_sink = Node.create_taint_sink sink None (Region.default ()) in
  Hashtbl.replace jslib name_jslib l_sink;
  Mdg.add_node mdg l_sink;
  Store.replace store sink.name (Node.Set.singleton l_sink)

let initialize_tainted_sinks (tconf : Taint_config.t) (mdg : Mdg.t)
    (store : Store.t) (jslib : t) : unit =
  List.iter (add_tainted_sink mdg store jslib Taint.function_sink) tconf.f_sinks

let initialize_module (mdg : Mdg.t) (store : Store.t) (jslib : t)
    (file : Fpath.t option) (l_parent : Node.t option) : unit =
  let name = "module" in
  let name_jslib = resolve_name file "module" in
  let l_module = Node.create_object name l_parent (Region.default ()) in
  Hashtbl.replace jslib name_jslib l_module;
  Mdg.add_node mdg l_module;
  Fun.flip Option.iter l_parent (fun l_parent' ->
      Mdg.add_edge mdg (Edge.create l_parent' l_module Dependency) );
  Store.replace store name (Node.Set.singleton l_module)

let initialize_exports (mdg : Mdg.t) (store : Store.t) (jslib : t)
    (file : Fpath.t option) (l_parent : Node.t option) : unit =
  let name = "exports" in
  let prop = Property.Static "exports" in
  let name_module = resolve_name file "module" in
  let name_jslib = resolve_name file "exports" in
  let l_module = find mdg jslib name_module in
  let l_exports = Node.create_object name l_parent (Region.default ()) in
  Hashtbl.replace jslib name_jslib l_exports;
  Mdg.add_node mdg l_exports;
  Mdg.add_edge mdg (Edge.create l_module l_exports (Property prop));
  Store.replace store name (Node.Set.singleton l_exports)

let create (tconf : Taint_config.t) (mdg : Mdg.t) (store : Store.t) : t =
  let jslib = Hashtbl.create Config.(!dflt_htbl_sz) in
  initialize_tainted_sinks tconf mdg store jslib;
  jslib

let initialize (mdg : Mdg.t) (store : Store.t) (jslib : t)
    (file : Fpath.t option) (l_parent : Node.t option) : unit =
  initialize_module mdg store jslib file l_parent;
  initialize_exports mdg store jslib file l_parent

let exported_object ?(mrel : Fpath.t option) (mdg : Mdg.t) (jslib : t) :
    Node.Set.t =
  let l_module = find mdg jslib (resolve_name mrel "module") in
  Node.Set.map_flat
    (Fun.flip (Mdg.object_static_lookup mdg) "exports")
    (Mdg.(object_tail_versions mdg) l_module)
