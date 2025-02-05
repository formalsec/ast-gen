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
  ; interactability : Interactability.t
  ; reachability : Reachability.t
  ; worklist : Worklist.t
  }

let initialize (mdg : Mdg.t) : t =
  let properties = Properties.create () in
  let callers = Callers.compute mdg in
  let interactability = Interactability.compute mdg in
  let reachability = Reachability.create () in
  let worklist = Worklist.create () in
  { mdg; properties; callers; interactability; reachability; worklist }

let rec run (f : Node.t -> t) (engine : t) : Node.t option =
  match Worklist.get_result engine.worklist with
  | Some _ as result -> result
  | None -> (
    match Worklist.dequeue engine.worklist with
    | Some node -> f node |> (run f [@tailcall])
    | None -> None )

let enqueue (engine : t) (node : Node.t) : t =
  { engine with worklist = Worklist.enqueue engine.worklist node }

let result (engine : t) (node : Node.t) : t =
  { engine with worklist = Worklist.set_result engine.worklist node }

let vulnerability (engine : t) (sink : Tainted.sink) (node : Node.t) :
    Vulnerability.t =
  (* HACK: vulnerabilities without a lineno are update with the lineno of the corresponding property *)
  (* this is useful, for example, when a sensitive sink is exported by the module *)
  let vuln = Vulnerability.make sink node in
  if vuln.line == Region.invalid then
    Mdg.object_of_property engine.mdg node
    |> List.hd_opt
    |> Option.fold ~none:vuln ~some:(Vulnerability.update vuln)
  else vuln

let get_sinks (engine : t) : Node.Set.t =
  Fun.flip2 Node.Set.fold engine.mdg.calls Node.Set.empty (fun l_call acc ->
      let ls_func = Mdg.get_called_functions engine.mdg l_call in
      Fun.flip2 List.fold_right ls_func acc (fun l_func acc ->
          if Node.is_taint_sink l_func then Node.Set.add l_func acc else acc ) )

let is_attacker_controlled (reachability : Reachability.Sources.t) : bool =
  Reachability.Sources.exists Reachability.Source.is_taint_source reachability

let lookup (engine : t) (node : Node.t) (prop : string option) : Node.Set.t =
  Properties.compute engine.properties engine.mdg node [ prop ]

let nested_lookup (engine : t) (node : Node.t) (props : string option list) :
    Node.Set.t =
  Properties.compute engine.properties engine.mdg node props

let callers (engine : t) (node : Node.t) : Node.Set.t =
  Callers.find engine.callers node

let interaction (engine : t) (node : Node.t) : Interactability.Interaction.t =
  Interactability.find engine.interactability node

let sources (engine : t) (node : Node.t) : Reachability.Sources.t =
  Reachability.compute engine.reachability engine.mdg node
