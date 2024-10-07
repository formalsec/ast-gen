open Graphjs_ast
open Structures

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
  { graph : Mdg.t
  ; store : Store.t
  ; this : LocationSet.t
  ; (* function information *)
    context : Functions.Context.t
  }

let empty_state (info : Functions.Info.t) =
  { graph = Mdg.empty register
  ; store = Store.empty ()
  ; this = Store.loc_this
  ; (* function information *)
    context = Functions.Context.create info
  }

let copy ({ graph; store; _ } as state : t) : t =
  { state with graph = Mdg.copy graph; store = Store.copy store }
