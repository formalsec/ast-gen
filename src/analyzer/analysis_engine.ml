open Graphjs_base
open Graphjs_ast
open Graphjs_mdg

module Worklist = struct
  type t =
    { queue : Node.t Queue.t
    ; visited : Node.Set.t
    ; result : Node.t option
    }

  let create () : t =
    { queue = Queue.create (); visited = Node.Set.empty; result = None }

  let dequeue (worklist : t) : Node.t option = Queue.take_opt worklist.queue

  let enqueue (worklist : t) (node : Node.t) : t =
    if not (Node.Set.mem node worklist.visited) then
      let _ = Queue.push node worklist.queue in
      { worklist with visited = Node.Set.add node worklist.visited }
    else worklist

  let get_result (worklist : t) : Node.t option = worklist.result

  let set_result (worklist : t) (result : Node.t) =
    { worklist with result = Some result }
end

type t =
  { mdg : Mdg.t
  ; properties : Properties.t
  ; callers : Callers.t
  ; exported : Exported.t
  ; sources : Sources.t
  ; worklist : Worklist.t
  }

let initialize (mdg : Mdg.t) : t =
  let properties = Properties.create () in
  let callers = Callers.compute mdg in
  let exported = Exported.compute mdg in
  let sources = Sources.compute mdg in
  let worklist = Worklist.create () in
  { mdg; properties; callers; exported; sources; worklist }

let rec run (f : Node.t -> t) (engine : t) : Node.t option =
  match Worklist.get_result engine.worklist with
  | Some _ as result -> result
  | None -> (
    match Worklist.dequeue engine.worklist with
    | Some node -> f node |> (run f [@tailcall])
    | None -> None )

let enqueue (engine : t) (node : Node.t) : t =
  { engine with worklist = Worklist.enqueue engine.worklist node }

let enqueue_all (engine : t) (nodes : Node.Set.t) : t =
  Node.Set.fold (fun node engine -> enqueue engine node) nodes engine

let result (engine : t) (node : Node.t) : t =
  { engine with worklist = Worklist.set_result engine.worklist node }

let lookup (engine : t) (node : Node.t) (prop : Property.t) : Node.Set.t =
  Properties.compute engine.mdg engine.properties node [ prop ]

let nested_lookup (engine : t) (node : Node.t) (props : Property.t list) :
    Node.Set.t =
  Properties.compute engine.mdg engine.properties node props

let callers (engine : t) (node : Node.t) : Node.Set.t =
  Callers.get engine.callers node

let returns (engine : t) (node : Node.t) : Node.Set.t =
  Mdg.get_called_functions engine.mdg node
  |> List.fold_left (fun a n -> Mdg.get_function_returns engine.mdg n @ a) []
  |> Node.Set.of_list

let schemes (engine : t) (node : Node.t) : Exported.Scheme.t list =
  Exported.get engine.exported node

let sources (engine : t) (node : Node.t) : Sources.Set.t =
  Sources.get engine.sources node

let is_attacker_controlled (sources : Sources.Set.t) : bool =
  Sources.Set.exists Sources.Source.is_taint_source sources

let get_sinks (engine : t) : Node.Set.t =
  Fun.flip2 Node.Set.fold engine.mdg.calls Node.Set.empty (fun l_call acc ->
      let ls_func = Mdg.get_called_functions engine.mdg l_call in
      Fun.flip2 List.fold_right ls_func acc (fun l_func acc ->
          if Node.is_taint_sink l_func then Node.Set.add l_func acc else acc ) )

let get_sink_args (engine : t) (l_sink : Node.t) : Node.Set.t =
  match l_sink.kind with
  | TaintSink sink ->
    let sensitive_args = Tainted.args sink in
    let callers = callers engine l_sink in
    Fun.flip2 Node.Set.fold callers Node.Set.empty (fun l_call acc ->
        Mdg.get_arguments engine.mdg l_call
        |> List.filter (fun (idx, _) -> List.mem idx sensitive_args)
        |> List.map (fun (_, l_arg) -> l_arg)
        |> List.fold_left (fun acc l_arg -> Node.Set.add l_arg acc) acc )
  | _ -> Log.fail "unexpected node kind in injection sink"

let vulnerability (engine : t) (sink : Tainted.sink) (node : Node.t) :
    Vulnerability.t =
  (* HACK: vulnerabilities without a lineno are update with the lineno of the corresponding property *)
  (* this is useful, for example, when a sensitive sink is exported by the module *)
  let vuln = Vulnerability.make sink node in
  if Region.is_invalid vuln.line then
    Mdg.get_property_owners engine.mdg node
    |> List.hd_opt
    |> Option.fold ~none:vuln ~some:(Vulnerability.update vuln)
  else vuln
