open Graphjs_base
open Graphjs_mdg

type t = (Location.t, Node.t * Node.Set.t) Hashtbl.t

let create () : t = Hashtbl.create Config.(!dflt_htbl_sz)
let mem (cache : t) (l_func : Node.t) : bool = Hashtbl.mem cache l_func.uid

let find (cache : t) (l_func : Node.t) : Node.Set.t option =
  Option.map snd (Hashtbl.find_opt cache l_func.uid)

let replace (cache : t) (l_func : Node.t) (ls_calls : Node.Set.t) : unit =
  Hashtbl.replace cache l_func.uid (l_func, ls_calls)

let get (cache : t) (l_func : Node.t) : Node.Set.t =
  Option.value ~default:Node.Set.empty (find cache l_func)

let add (cache : t) (l_func : Node.t) (l_call : Node.t) : unit =
  get cache l_func |> Node.Set.add l_call |> replace cache l_func

let pp (ppf : Fmt.t) (cache : t) : unit =
  let pp_callers ppf (l_func, ls_calls) =
    Fmt.fmt ppf "%a -> %a" Node.pp l_func Node.Set.pp ls_calls in
  Fmt.(pp_htbl !>"@\n" (fun ppf (_, value) -> pp_callers ppf value)) ppf cache

let str (cache : t) : string = Fmt.str "%a" pp cache

let compute_call_arguments (mdg : Mdg.t) (cache : t) (l_func : Node.t)
    (l_call : Node.t) : unit =
  let params = Mdg.get_parameters mdg l_func in
  let args = Mdg.get_arguments mdg l_call in
  Fun.flip List.iter params (fun (idx, l_param) ->
      List.filter (fun (idx', _) -> idx == idx') args
      |> List.map (fun (_, l_arg) -> l_arg)
      |> List.iter (add cache l_param) )

let compute_call (mdg : Mdg.t) (cache : t) (l_call : Node.t) : unit =
  let ls_func = Mdg.get_called_functions mdg l_call in
  Fun.flip List.iter ls_func (fun l_func ->
      add cache l_func l_call;
      compute_call_arguments mdg cache l_func l_call )

let compute (mdg : Mdg.t) : t =
  let cache = create () in
  Node.Set.iter (compute_call mdg cache) mdg.calls;
  cache
