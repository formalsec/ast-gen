open Graphjs_base
open Graphjs_mdg

type t = (Location.t * Property.t, Node.t * Node.Set.t) Hashtbl.t

let create () : t = Hashtbl.create Config.(!dflt_htbl_sz)

let mem (cache : t) (l_obj : Node.t) (prop : Property.t) : bool =
  Hashtbl.mem cache (l_obj.uid, prop)

let find (cache : t) (obj : Node.t) (prop : Property.t) : Node.Set.t option =
  Option.map snd (Hashtbl.find_opt cache (obj.uid, prop))

let replace (cache : t) (l_obj : Node.t) (prop : Property.t)
    (ls_prop : Node.Set.t) : unit =
  Hashtbl.replace cache (l_obj.uid, prop) (l_obj, ls_prop)

let get (cache : t) (l_obj : Node.t) (prop : Property.t) : Node.Set.t =
  Option.value ~default:Node.Set.empty (find cache l_obj prop)

let pp (ppf : Fmt.t) (cache : t) : unit =
  let pp_v ppf (_, prop) (l_obj, ls_props) =
    Fmt.fmt ppf "%a.%a -> %a" Node.pp l_obj Property.pp prop Node.Set.pp
      ls_props in
  Fmt.(pp_htbl !>"@\n" (fun ppf (key, value) -> pp_v ppf key value)) ppf cache

let str (cache : t) : string = Fmt.str "%a" pp cache

let rec compute_properties (mdg : Mdg.t) (cache : t) (l_obj : Node.t)
    (props : Property.t list) (acc : Node.Set.t) : Node.Set.t =
  match props with
  | [] -> Node.Set.singleton l_obj
  | [ prop ] ->
    let ls_props = compute_property mdg cache l_obj prop in
    Node.Set.union acc ls_props
  | prop :: props' ->
    let ls_props = compute_property mdg cache l_obj prop in
    Fun.flip2 Node.Set.fold ls_props acc (fun l_obj' acc ->
        compute_properties mdg cache l_obj' props' acc )

and compute_property (mdg : Mdg.t) (cache : t) (l_obj : Node.t)
    (prop : Property.t) : Node.Set.t =
  match find cache l_obj prop with
  | Some ls_prop -> ls_prop
  | None ->
    let ls_prop = Mdg.object_lookup mdg l_obj prop in
    replace cache l_obj prop ls_prop;
    ls_prop

let compute (mdg : Mdg.t) (cache : t) (l_obj : Node.t) (props : Property.t list)
    : Node.Set.t =
  compute_properties mdg cache l_obj props Node.Set.empty
