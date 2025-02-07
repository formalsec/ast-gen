open Graphjs_base
open Graphjs_mdg

module Interaction = struct
  type t' =
    | Lookup of string option
    | Invoke

  type t = t' list

  let extend (prev : t) (next : t) : t = prev @ next [@@inline]

  let pp_interaction (ppf : Fmt.t) : t' -> unit = function
    | Lookup (Some prop) -> Fmt.fmt ppf ".%s" prop
    | Lookup None -> Fmt.pp_str ppf ".*"
    | Invoke -> Fmt.pp_str ppf "()"

  let pp (ppf : Fmt.t) (interactions : t) : unit =
    Fmt.fmt ppf "<EObj>%a" Fmt.(pp_lst !>"" pp_interaction) interactions

  let str (interactions : t) : string = Fmt.str "%a" pp interactions [@@inline]
end

type t = (Location.t, Node.t * Interaction.t) Hashtbl.t

let create () : t = Hashtbl.create Config.(!dflt_htbl_sz)
let length (interactability : t) : int = Hashtbl.length interactability

let mem (interactability : t) (node : Node.t) : bool =
  Hashtbl.mem interactability node.uid

let find_opt (interactability : t) (node : Node.t) : Interaction.t option =
  Option.map snd (Hashtbl.find_opt interactability node.uid)

let find (interactability : t) (node : Node.t) : Interaction.t =
  Option.value ~default:[] (find_opt interactability node)

let replace (interactability : t) (node : Node.t) (interaction : Interaction.t)
    : unit =
  Hashtbl.replace interactability node.uid (node, interaction)

let pp (ppf : Fmt.t) (interactability : t) : unit =
  let pp' ppf (_, (node, interaction)) =
    Fmt.fmt ppf "%a -> %a" Node.pp node Interaction.pp interaction in
  Fmt.(pp_htbl !>"@\n" pp') ppf interactability

let str (interactability : t) : string = Fmt.str "%a" pp interactability
[@@inline]

let add_interactable (interactability : t) (acc : (Node.t * Interaction.t) list)
    (node : Node.t) (interaction : Interaction.t) :
    (Node.t * Interaction.t) list =
  match find_opt interactability node with
  | Some _ -> acc
  | None ->
    replace interactability node interaction;
    (node, interaction) :: acc

let compute_lookups (interactability : t) (mdg : Mdg.t) (prev : Interaction.t)
    (ls_obj : Node.Set.t) : (Node.t * Interaction.t) list =
  let lookup_f prop = Interaction.Lookup prop in
  let props_f (props, node) acc =
    List.map lookup_f props
    |> Interaction.extend prev
    |> add_interactable interactability acc node in
  Fun.flip2 Node.Set.fold ls_obj [] (fun node acc ->
      Mdg.object_nested_traversal props_f mdg node acc )

let compute_returns (mdg : Mdg.t) (props : (Node.t * Interaction.t) list) :
    (Node.t * Interaction.t) list =
  let funcs = List.filter (fun (node, _) -> Node.is_function node) props in
  Fun.flip2 List.fold_left [] funcs (fun acc (l_func, interactions) ->
      let ls_retn = Mdg.get_function_returns mdg l_func in
      Fun.flip2 List.fold_left acc ls_retn (fun acc l_retn ->
          let interaction = Interaction.extend interactions [ Invoke ] in
          (l_retn, interaction) :: acc ) )

let rec compute_object (interactability : t) (mdg : Mdg.t)
    (prev : Interaction.t) (ls_obj : Node.Set.t) : unit =
  compute_lookups interactability mdg prev ls_obj
  |> compute_returns mdg
  |> List.iter (fun (l_retn, interaction) ->
         if not (mem interactability l_retn) then
           compute_object interactability mdg interaction
             (Node.Set.singleton l_retn) )

let set_taint (mdg : Mdg.t) (l_taint : Node.t) (node : Node.t) : unit =
  match node.kind with
  | Object _ | Function _ | Parameter _ | TaintSink _ ->
    Mdg.add_edge mdg (Edge.create_dependency () l_taint node)
  | _ -> ()

let set_tainted_param (mdg : Mdg.t) (l_taint : Node.t) (node : Node.t) : unit =
  let taint_f (_, node) () = set_taint mdg l_taint node in
  Mdg.object_nested_traversal ~final:false taint_f mdg node ()

let set_tainted_func (mdg : Mdg.t) (l_taint : Node.t) (node : Node.t) : unit =
  match node.kind with
  | Function _ ->
    let params = Mdg.get_parameters mdg node in
    Fun.flip List.iter params (fun (_, param) ->
        set_taint mdg l_taint param;
        set_tainted_param mdg l_taint param )
  | _ -> ()

let set_tainted_sources (interactability : t) (mdg : Mdg.t) : unit =
  if length interactability > 0 then (
    let l_taint = Node.create_taint_source () in
    Mdg.add_node mdg l_taint;
    Fun.flip Hashtbl.iter interactability (fun _ (node, _) ->
        set_taint mdg l_taint node;
        set_tainted_func mdg l_taint node ) )

let compute (mdg : Mdg.t) : t =
  let interactability = create () in
  let exported = Mdg.exported_object mdg in
  compute_object interactability mdg [] exported;
  set_tainted_sources interactability mdg;
  interactability
