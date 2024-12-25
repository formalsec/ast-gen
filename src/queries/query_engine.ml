open Graphjs_base
open Graphjs_mdg

type t =
  { mdg : Mdg.t
  ; local_flow : Local_flow.t
  }

let initialize (mdg : Mdg.t) : t =
  let local_flow = Hashtbl.create Config.(!dflt_htbl_sz) in
  { mdg; local_flow }

let local_sources (engine : t) (node : Node.t) : Local_flow.Set.t =
  match Hashtbl.find_opt engine.local_flow node.uid with
  | None -> Local_flow.compute engine.mdg engine.local_flow node
  | Some reaching -> reaching
