(* open Auxiliary.Functions *)
open Auxiliary.GraphJS
open Structures

type state = {
  graph : Graph.t;
  store : Store.t;
  this  : LocationSet.t;
}

let empty_state = { graph = Graph.empty; store = Store.empty; this = LocationSet.empty };;

let rec program ((_, {body}) : m Program.t) : Graph.t * Store.t = 
  let state = analyse_sequence empty_state body in 
  state.graph, state.store

and analyse (state : state) (statement : m Statement.t) : state =
  let graph = state.graph in 
  let store = state.store in 
  let eval_expr = eval_expr store in 

  match statement with
    (* -------- A S S I G N - E X P R -------- *)
    | _, AssignSimple {left; right} -> 
      let _L = eval_expr right in 
      let store' = Store.update store left _L in 
      {graph = graph; store = store'; this = LocationSet.empty}

    (* ??? 
    | _, AssignArray _ -> empty_state
    | _, AssignFunCall _ -> empty_state 
    *)

    (* -------- A S S I G N - O P -------- *)
    | _, AssignOperation {(*left;*) opLeft; opRght; id; _} -> 
      let _L1, _L2 = eval_expr opLeft, eval_expr opRght in 
      let _ = Graph.alloc graph id in 
      empty_state

    (* -------- N E W   O B J E C T -------- *)
    | _, AssignObject {id; left} -> 
      let l_i = Graph.alloc graph id in
      let store' = Store.update store left (LocationSet.singleton l_i) in
      let graph' = Graph.addNode graph l_i in 
      {graph = graph'; store = store'; this = LocationSet.empty}
      

    (* -------- S T A T I C   P R O P E R T Y    L O O K U P -------- *)
    | _, AssignStaticMember _ -> empty_state

    (* -------- D Y N A M I C   P R O P E R T Y    L O O K U P -------- *)
    | _, AssignDynmicMember _ -> empty_state

    (* -------- S T A T I C   P R O P E R T Y    U P D A T E -------- *)
    | _, StaticMemberAssign _ -> empty_state

    (* -------- D Y N A M I C   P R O P E R T Y    U P D A T E -------- *)
    | _, DynmicMemberAssign _ -> empty_state

    (* -------- C A L L -------- *)
    | _, AssignFunCall _ -> empty_state
    | _, AssignNew _ -> empty_state

    (* -------- I F -------- *)
    | _, If _ ->
      (* let consq_state = analyse_sequence state consequent in 
         let altrn_state = map_default (analyse_sequence state) empty_state alternate in 
       TODO : graph and store union *)
      empty_state

    (* -------- W H I L E -------- *)
    | _, While _ -> empty_state

    | _ -> state
          (* failwith "statement node analysis not defined" *) 

and analyse_sequence (state : state) (sequence : m Statement.t list) : state = 
  List.fold_left analyse state sequence

and eval_expr (store : Store.t) (expr : m Expression.t) : LocationSet.t = 
  match expr with
    | (_, Identifier _) as id -> 
      let id = Identifier.from_expression id in 
      Store.get store id 
    
    | _, This _ -> Store.literal_loc
    | _, TemplateLiteral _ -> Store.literal_loc

    | _ -> Store.literal_loc


