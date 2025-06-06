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

let initialize_tainted_source (mdg : Mdg.t) (jslib : t) : unit =
  let name_jslib = "taint" in
  let l_taint = Node.create_taint_source () in
  Hashtbl.replace jslib name_jslib l_taint;
  Mdg.add_node mdg l_taint

let initialize_tainted_sink (mdg : Mdg.t) (store : Store.t) (jslib : t)
    (sink : Jsmodel.Sink.t) : unit =
  let taint_sink = Taint.Sink.create Taint.Id.language sink in
  let name_jslib = resolve_name None sink.name in
  let l_sink = Node.create_taint_sink taint_sink None (Region.default ()) in
  Hashtbl.replace jslib name_jslib l_sink;
  Mdg.add_node mdg l_sink;
  Store.replace store sink.name (Node.Set.singleton l_sink)

let initialize_language_component (mdg : Mdg.t) (store : Store.t) (jslib : t)
    (component : Jsmodel.Component.t) =
  match component with
  | `Sink sink -> initialize_tainted_sink mdg store jslib sink
  | _ -> ()

let initialize_language_model (mdg : Mdg.t) (store : Store.t) (jslib : t)
    (jsmodel : Jsmodel.t) : unit =
  List.iter (initialize_language_component mdg store jslib) jsmodel.language

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

let create (mdg : Mdg.t) (store : Store.t) (jsmodel : Jsmodel.t) : t =
  let jslib = Hashtbl.create Config.(!dflt_htbl_sz) in
  initialize_tainted_source mdg jslib;
  initialize_language_model mdg store jslib jsmodel;
  jslib

let initialize (mdg : Mdg.t) (store : Store.t) (jslib : t)
    (file : Fpath.t option) (l_parent : Node.t option) : unit =
  initialize_module mdg store jslib file l_parent;
  initialize_exports mdg store jslib file l_parent

let exported_object ?(mrel : Fpath.t option) (mdg : Mdg.t) (jslib : t) :
    Node.Set.t =
  find mdg jslib (resolve_name mrel "module")
  |> Mdg.(object_tail_versions mdg)
  |> Node.Set.map_flat (Fun.flip (Mdg.object_static_lookup mdg) "exports")
  |> Node.Set.map_flat Mdg.(object_tail_versions mdg)
