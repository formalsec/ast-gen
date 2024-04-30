(* open Auxiliary.Functions *)
open Auxiliary.GraphJS
open Structures

type state = {
  graph : Graph.t;
  store : Store.t;
  this  : LocationSet.t;
}

let empty_state : state = { 
  graph = Graph.empty; 
  store = Store.empty; 
  this  = Store.this_loc
}

let rec program ((_, {body}) : m Program.t) : Graph.t * Store.t = 
  let state = empty_state in 
  List.iter (analyse state) body; 
  state.graph, state.store

and analyse (state : state) (statement : m Statement.t) : unit =
  let graph = state.graph in 
  let store = state.store in 
  let eval_expr = eval_expr store state.this in 

  match statement with
    (* -------- A S S I G N - E X P R -------- *)
    | _, AssignSimple {left; right} -> 
      let _L = eval_expr right in 
      Store.update store left _L

    (* ??? 
    | _, AssignArray _ -> ()
    | _, AssignFunCall _ -> () 
    *)

    (* -------- A S S I G N - O P -------- *)
    | _, AssignBinary {(*left;*) opLeft; opRght; id; _} -> 
      let _L1, _L2 = eval_expr opLeft, eval_expr opRght in 
      let _ = Graph.alloc graph id in 
      ()

    (* -------- N E W   O B J E C T -------- *)
    | _, AssignObject {id; left} -> 
      let l_i = Graph.alloc graph id in
      Store.update store left (LocationSet.singleton l_i);
      Graph.addNode graph l_i;
      

    (* -------- S T A T I C   P R O P E R T Y    L O O K U P -------- *)
    | _, AssignStaticMember _ -> ()

    (* -------- D Y N A M I C   P R O P E R T Y    L O O K U P -------- *)
    | _, AssignDynmicMember _ -> ()

    (* -------- S T A T I C   P R O P E R T Y    U P D A T E -------- *)
    | _, StaticMemberAssign _ -> ()

    (* -------- D Y N A M I C   P R O P E R T Y    U P D A T E -------- *)
    | _, DynmicMemberAssign _ -> ()

    (* -------- C A L L -------- *)
    | _, AssignFunCall _ -> ()
    | _, AssignNew _ -> ()

    (* -------- I F -------- *)
    | _, If _ ->
      (* let consq_state = analyse_sequence state consequent in 
         let altrn_state = map_default (analyse_sequence state) empty_state alternate in 
       TODO : graph and store union *)
      ()

    (* -------- W H I L E -------- *)
    | _, While _ -> ()

    | _ -> ()
          (* failwith "statement node analysis not defined" *) 

and eval_expr (store : Store.t) (this : LocationSet.t) (expr : m Expression.t) : LocationSet.t = 
  match expr with
    | (_, Identifier _) as id -> 
      let id = Identifier.from_expression id in 
      Store.get store id 
    
    | _, Literal _ -> Store.literal_loc

    | _, This _ -> this

    | _, TemplateLiteral {expressions; _} -> 
      List.fold_left (fun acc elem -> LocationSet.union acc (eval_expr store this elem)) LocationSet.empty expressions



