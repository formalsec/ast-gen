open Graphjs_base
open Graphjs_mdg

type t =
  { mdg : Mdg.t
  ; interactability : Interactability.t
  ; reachability : Reachability.t
  }

let initialize (mdg : Mdg.t) : t =
  let interactability = Interactability.compute mdg in
  let reachability = Reachability.create () in
  { mdg; interactability; reachability }

let reachable (engine : t) (node : Node.t) : Reachability.Set.t =
  match Hashtbl.find_opt engine.reachability node.uid with
  | None -> Reachability.compute engine.mdg engine.reachability node
  | Some reaching -> reaching
