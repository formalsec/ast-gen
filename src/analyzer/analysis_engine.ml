open Graphjs_base
open Graphjs_mdg

type t =
  { mdg : Mdg.t
  ; properties : Properties.t
  ; callers : Callers.t
  ; interactability : Interactability.t
  ; reachability : Reachability.t
  }

let initialize (mdg : Mdg.t) : t =
  let properties = Properties.create () in
  let callers = Callers.compute mdg in
  let interactability = Interactability.compute mdg in
  let reachability = Reachability.create () in
  { mdg; properties; callers; interactability; reachability }

let lookup (engine : t) (node : Node.t) (prop : string option) : Node.Set.t =
  Properties.compute engine.properties engine.mdg node [ prop ]

let nested_lookup (engine : t) (node : Node.t) (props : string option list) :
    Node.Set.t =
  Properties.compute engine.properties engine.mdg node props

let callers (engine : t) (node : Node.t) : Node.Set.t =
  Callers.find engine.callers node

let reachable (engine : t) (node : Node.t) : Reachability.Set.t =
  match Hashtbl.find_opt engine.reachability node.uid with
  | None -> Reachability.compute engine.reachability engine.mdg node
  | Some reaching -> reaching
