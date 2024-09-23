open Structures
module Function = Ast.Function
module Graph = Graph'

let (register, setup, was_changed) =
  let bs : bool list ref = ref [] in

  let reg () = match !bs with _ :: bs' -> bs := true :: bs' | _ -> () in

  let push () = bs := false :: !bs in

  let pop () =
    match !bs with
    | b :: bs' ->
      bs := bs';
      b
    | _ -> failwith "[ERROR] No element to pop" in

  (reg, push, pop)

type t =
  { graph : Graph.t
  ; store : Store.t
  ; this : LocationSet.t
  ; (* function information *)
    context : Function.Context.t
  ; currFuncNode : Graph.Node.t option
  }

let empty_state (info : Function.Info.t) =
  { graph = Graph.empty register
  ; store = Store.empty ()
  ; this = Store.loc_this
  ; (* function information *)
    context = Function.Context.create info
  ; currFuncNode = None
  }

let copy ({ graph; store; _ } as state : t) : t =
  { state with graph = Graph.copy graph; store = Store.copy store }
