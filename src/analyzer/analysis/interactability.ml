open Graphjs_base
open Graphjs_mdg

module Interaction = struct
  type t' =
    | Lookup of string option
    | Invoke

  type t = t' list

  let lookup (prop : string option) : t' = Lookup prop [@@inline]
  let invoke () : t' = Invoke [@@inline]
  let extend (prev : t) (next : t) : t = prev @ next [@@inline]

  let pp_interaction (ppf : Fmt.t) : t' -> unit = function
    | Lookup (Some prop) -> Fmt.fmt ppf ".%s" prop
    | Lookup None -> Fmt.pp_str ppf ".*"
    | Invoke -> Fmt.pp_str ppf "()"

  let pp (ppf : Fmt.t) (interactions : t) : unit =
    Fmt.fmt ppf "<EObj>%a" Fmt.(pp_lst !>"" pp_interaction) interactions

  let str (interactions : t) : string = Fmt.str "%a" pp interactions [@@inline]
end

type t' = Node.t * Interaction.t
type t = (Location.t, t') Hashtbl.t

let create () : t = Hashtbl.create Config.(!dflt_htbl_sz)

let mem (interactability : t) (node : Node.t) : bool =
  Hashtbl.mem interactability node.uid

let find (interactability : t) (node : Node.t) : Interaction.t option =
  Option.map snd (Hashtbl.find_opt interactability node.uid)

let replace (interactability : t) (node : Node.t) (interaction : Interaction.t)
    : unit =
  Hashtbl.replace interactability node.uid (node, interaction)

let pp_interactable (ppf : Fmt.t) ((node, interaction) : t') : unit =
  Fmt.fmt ppf "%a -> %a" Node.pp node Interaction.pp interaction

let pp (ppf : Fmt.t) (interactability : t) : unit =
  let pp' ppf (_, interactable) = pp_interactable ppf interactable in
  Fmt.(pp_hashtbl !>"@\n" pp') ppf interactability

let str (interactability : t) : string = Fmt.str "%a" pp interactability
[@@inline]

let add_interactable (interactability : t) (acc : (Node.t * Interaction.t) list)
    (node : Node.t) (interaction : Interaction.t) :
    (Node.t * Interaction.t) list =
  match Hashtbl.find_opt interactability node.uid with
  | Some _ -> acc
  | None ->
    Hashtbl.replace interactability node.uid (node, interaction);
    (node, interaction) :: acc

let compute_props (interactability : t) (mdg : Mdg.t) (prev : Interaction.t)
    (ls_obj : Node.Set.t) : (Node.t * Interaction.t) list =
  let props_f (props, node) acc =
    List.map Interaction.lookup props
    |> Interaction.extend prev
    |> add_interactable interactability acc node in
  Fun.flip2 Node.Set.fold ls_obj [] (fun node acc ->
      Mdg.object_nested_traversal props_f mdg node acc )

let compute_calls (mdg : Mdg.t) (props : (Node.t * Interaction.t) list) :
    (Node.t * Interaction.t) list =
  let funcs = List.filter (fun (node, _) -> Node.is_function node) props in
  Fun.flip2 List.fold_left [] funcs (fun acc (l_func, interactions) ->
      let retns = Mdg.get_function_returns mdg l_func in
      Fun.flip2 List.fold_left acc retns (fun acc l_retn ->
          let interaction = Interaction.extend interactions [ Invoke ] in
          (l_retn, interaction) :: acc ) )

let rec compute_object (interactability : t) (mdg : Mdg.t)
    (prev : Interaction.t) (ls_obj : Node.Set.t) : unit =
  let props = compute_props interactability mdg prev ls_obj in
  compute_calls mdg props
  |> List.filter (fun (l_retn, _) -> not (mem interactability l_retn))
  |> List.iter (fun (l_retn, interaction) ->
         compute_object interactability mdg interaction
           (Node.Set.singleton l_retn) )

let compute (mdg : Mdg.t) : t =
  let interactability = create () in
  let exported = Mdg.exported_object mdg in
  compute_object interactability mdg [] exported;
  interactability
