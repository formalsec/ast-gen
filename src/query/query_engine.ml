open Graphjs_mdg

type t = { mdg : Mdg.t }

let initialize (mdg : Mdg.t) : t = { mdg }
