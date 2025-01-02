open Graphjs_base
open Graphjs_mdg

type t = (Location.t, Node.t * Node.Set.t) Hashtbl.t

let create () : t = Hashtbl.create Config.(!dflt_htbl_sz)
let mem (callers : t) (node : Node.t) : bool = Hashtbl.mem callers node.uid

let find_opt (callers : t) (node : Node.t) : Node.Set.t option =
  Option.map snd (Hashtbl.find_opt callers node.uid)

let find (callers : t) (node : Node.t) : Node.Set.t =
  find_opt callers node |> Option.value ~default:Node.Set.empty

let replace (callers : t) (node : Node.t) (sites : Node.Set.t) : unit =
  Hashtbl.replace callers node.uid (node, sites)

let add (callers : t) (node : Node.t) (site : Node.t) : unit =
  find callers node |> Node.Set.add site |> replace callers node

let pp (ppf : Fmt.t) (callers : t) : unit =
  let pp_sites ppf (node, sites) =
    Fmt.fmt ppf "%a -> %a" Node.pp node Node.Set.pp sites in
  Fmt.(pp_hashtbl !>"@\n" (fun ppf (_, sites) -> pp_sites ppf sites))
    ppf callers

let str (callers : t) : string = Fmt.str "%a" pp callers [@@inline]

let compute_call_arguments (callers : t) (mdg : Mdg.t) (l_func : Node.t)
    (l_call : Node.t) : unit =
  let l_params = Mdg.get_parameters mdg l_func in
  let ls_args = Mdg.get_arguments mdg l_call in
  Fun.flip List.iter l_params (fun (idx, l_param) ->
      let f = fun (idx', l_arg) -> if idx == idx' then Some l_arg else None in
      ls_args |> List.filter_map f |> List.iter (add callers l_param) )

let compute_call (callers : t) (mdg : Mdg.t) (l_call : Node.t) : unit =
  let l_func = Mdg.get_call_function mdg l_call in
  Fun.flip List.iter l_func (fun l_func' ->
      add callers l_func' l_call;
      compute_call_arguments callers mdg l_func' l_call )

let compute (mdg : Mdg.t) : t =
  Log.debug "test = %a" Node.Set.pp mdg.calls;
  let callers = create () in
  Node.Set.iter (compute_call callers mdg) mdg.calls;
  callers
