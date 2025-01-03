open Graphjs_base
open Graphjs_mdg

type t = (Location.t * string option, Node.t * Node.Set.t) Hashtbl.t

let create () : t = Hashtbl.create Config.(!dflt_htbl_sz)

let mem (summary : t) (node : Node.t) (prop : string option) : bool =
  Hashtbl.mem summary (node.uid, prop)

let find_opt (summary : t) (node : Node.t) (prop : string option) :
    Node.Set.t option =
  Option.map snd (Hashtbl.find_opt summary (node.uid, prop))

let find (summary : t) (node : Node.t) (prop : string option) : Node.Set.t =
  find_opt summary node prop |> Option.value ~default:Node.Set.empty

let replace (summary : t) (node : Node.t) (prop : string option)
    (sites : Node.Set.t) : unit =
  Hashtbl.replace summary (node.uid, prop) (node, sites)

let add (summary : t) (node : Node.t) (prop : string option) (site : Node.t) :
    unit =
  find summary node prop |> Node.Set.add site |> replace summary node prop

let pp (ppf : Fmt.t) (summary : t) : unit =
  let pp_prop ppf prop = Fmt.pp_str ppf (Option.value ~default:"*" prop) in
  let pp_sites ppf (_, prop) (node, sites) =
    Fmt.fmt ppf "%a.%a -> %a" Node.pp node pp_prop prop Node.Set.pp sites in
  Fmt.(pp_hashtbl !>"@\n" (fun ppf (key, sites) -> pp_sites ppf key sites))
    ppf summary

let str (summary : t) : string = Fmt.str "%a" pp summary [@@inline]

let rec compute_object (summary : t) (mdg : Mdg.t) (node : Node.t)
    (acc : Node.Set.t) : string option list -> Node.Set.t = function
  | [] -> acc
  | prop :: props' -> (
    match find_opt summary node prop with
    | Some ls_prop -> compute_prop summary mdg ls_prop acc props'
    | None ->
      let ls_prop = Mdg.object_lookup mdg node prop in
      replace summary node prop ls_prop;
      compute_prop summary mdg ls_prop acc props' )

and compute_prop (summary : t) (mdg : Mdg.t) (ls_prop : Node.Set.t)
    (acc : Node.Set.t) (props : string option list) : Node.Set.t =
  Fun.flip2 Node.Set.fold ls_prop acc (fun l_prop acc ->
      compute_object summary mdg l_prop acc props )

let compute (summary : t) (mdg : Mdg.t) (node : Node.t)
    (props : string option list) : Node.Set.t =
  compute_object summary mdg node Node.Set.empty props
