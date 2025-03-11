open Graphjs_base
open Graphjs_mdg

module Interaction = struct
  type t =
    | Lookup of Property.t
    | Invoke

  let pp (ppf : Fmt.t) (itx : t) : unit =
    match itx with
    | Lookup (Static prop) -> Fmt.fmt ppf ".%s" prop
    | Lookup Dynamic -> Fmt.pp_str ppf ".*"
    | Invoke -> Fmt.pp_str ppf "()"

  let str (itx : t) : string = Fmt.str "%a" pp itx
end

module Scheme = struct
  type t = Interaction.t list

  let extend (prev : t) (next : t) : t = prev @ next

  let pp (ppf : Fmt.t) (scheme : t) : unit =
    Fmt.fmt ppf "<EObj>%a" Fmt.(pp_lst !>"" Interaction.pp) scheme

  let str (scheme : t) : string = Fmt.str "%a" pp scheme
end

type t = (Location.t, Node.t * Scheme.t list) Hashtbl.t

let create () : t = Hashtbl.create Config.(!dflt_htbl_sz)
let mem (cache : t) (l_node : Node.t) : bool = Hashtbl.mem cache l_node.uid

let find (cache : t) (l_node : Node.t) : Scheme.t list option =
  Option.map snd (Hashtbl.find_opt cache l_node.uid)

let replace (cache : t) (l_node : Node.t) (scheme : Scheme.t list) : unit =
  Hashtbl.replace cache l_node.uid (l_node, scheme)

let get (cache : t) (l_node : Node.t) : Scheme.t list =
  Option.value ~default:[] (find cache l_node)

let add (cache : t) (l_node : Node.t) (scheme : Scheme.t) : unit =
  get cache l_node |> List.cons scheme |> replace cache l_node

let pp (ppf : Fmt.t) (cache : t) : unit =
  let pp_scheme ppf scheme = Fmt.fmt ppf "- %a" Scheme.pp scheme in
  let pp_schemes ppf schemes = Fmt.(pp_lst !>"@\n" pp_scheme) ppf schemes in
  let pp_v ppf (node, schemes) =
    Fmt.fmt ppf "%a:@\n@[<v 2>  %a@]" Node.pp node pp_schemes schemes in
  Fmt.(pp_htbl !>"@\n" (fun ppf (_, vs) -> pp_v ppf vs)) ppf cache

let str (cache : t) : string = Fmt.str "%a" pp cache

let set_taint (mdg : Mdg.t) (l_taint : Node.t) (node : Node.t) : unit =
  match node.kind with
  | Object _ | Function _ | Parameter _ | TaintSink _ ->
    Mdg.add_edge mdg (Edge.create_dependency () l_taint node)
  | _ -> ()

let set_tainted_func (mdg : Mdg.t) (l_taint : Node.t) (node : Node.t) : unit =
  let taint_f (_, node) () = set_taint mdg l_taint node in
  match node.kind with
  | Function _ ->
    Fun.flip List.iter (Mdg.get_parameters mdg node) (fun (_, l_param) ->
        set_taint mdg l_taint l_param;
        Mdg.object_nested_traversal ~final:false taint_f mdg node () )
  | _ -> ()

let set_tainted_sources (mdg : Mdg.t) (cache : t) : unit =
  let l_taint = Node.create_taint_source () in
  Mdg.add_node mdg l_taint;
  Fun.flip Hashtbl.iter cache (fun _ (node, _) ->
      set_taint mdg l_taint node;
      set_tainted_func mdg l_taint node )

let add_interactable (cache : t) (acc : (Node.t * Scheme.t) list)
    (node : Node.t) (scheme : Scheme.t) : (Node.t * Scheme.t) list =
  match find cache node with
  | Some _ -> acc
  | None ->
    replace cache node [ scheme ];
    (node, scheme) :: acc

let compute_lookups (cache : t) (mdg : Mdg.t) (prev : Scheme.t)
    (ls_obj : Node.Set.t) : (Node.t * Scheme.t) list =
  let props_f (props, node) acc =
    List.map (fun prop -> Interaction.Lookup prop) props
    |> Scheme.extend prev
    |> add_interactable cache acc node in
  Fun.flip2 Node.Set.fold ls_obj [] (fun node acc ->
      Mdg.object_nested_traversal props_f mdg node acc )

let compute_returns (mdg : Mdg.t) (props : (Node.t * Scheme.t) list) :
    (Node.t * Scheme.t) list =
  let funcs = List.filter (fun (node, _) -> Node.is_function node) props in
  Fun.flip2 List.fold_left [] funcs (fun acc (l_func, scheme) ->
      let ls_retn = Mdg.get_function_returns mdg l_func in
      Fun.flip2 List.fold_left acc ls_retn (fun acc l_retn ->
          let interaction = Scheme.extend scheme [ Invoke ] in
          (l_retn, interaction) :: acc ) )

let rec compute_object (mdg : Mdg.t) (cache : t) (prev : Scheme.t)
    (ls_obj : Node.Set.t) : unit =
  compute_lookups cache mdg prev ls_obj
  |> compute_returns mdg
  |> List.iter (fun (l_retn, scheme) ->
         if not (mem cache l_retn) then
           compute_object mdg cache scheme (Node.Set.singleton l_retn) )

let compute (mdg : Mdg.t) : t =
  let cache = create () in
  let ls_exported = Node.Set.empty in
  (* let ls_exported = mdg.exports in *)
  (* let ls_exported = Mdg.exported_object mdg in *)
  if Node.Set.is_empty ls_exported then cache
  else (
    compute_object mdg cache [] ls_exported;
    set_tainted_sources mdg cache;
    cache )
