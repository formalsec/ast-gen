open Graphjs_base
open Result

module Options = struct
  type env = { mdg_env : Cmd_mdg.Options.env }

  type t =
    { inputs : Fpath.t list
    ; output : Fpath.t option
    ; env : env
    }

  let env (mdg_env : Cmd_mdg.Options.env) : env = { mdg_env }

  let cmd (inputs : Fpath.t list) (output : Fpath.t option) (env : env) : t =
    { inputs; output; env }
end

let run (_env : Options.env) (_w : Workspace.t) (_input : Fpath.t) :
    unit Exec.result =
  Ok ()

let outcome (res : 'a Exec.result) : Bulk.Instance.outcome =
  match res with Ok _ -> Success | Error _ -> Anomaly

let bulk_interface (env : Options.env) : (module Bulk.CmdInterface) =
  ( module struct
    type t = unit

    let cmd = Docs.QueryCmd.name
    let run = run env
    let outcome = outcome
  end )

let main (opts : Options.t) () : unit Exec.result =
  let w = Workspace.create ~default:`None opts.inputs opts.output in
  let* _ = Workspace.prepare w in
  let* inputs = Bulk.InputTree.generate opts.inputs in
  let module Interface = (val bulk_interface opts.env) in
  let module Executor = Bulk.Executor (Interface) in
  Executor.execute w inputs
