(* open Auxiliary.Functions *)
open Auxiliary.GraphJS
open Auxiliary.Functions
open Structures
open State

let rec program ((_, {body}) : m Program.t) : Graph.t * Store.t = 
  let state = empty_state () in 
  analyse_sequence state body;
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
    | _, AssignBinary {left; opLeft; opRght; id; _} -> 
      let _L1, _L2 = eval_expr opLeft, eval_expr opRght in 
      let l_i = Graph.alloc graph id in 
      LocationSet.iter (Graph.addDepEdge graph l_i) (LocationSet.union _L1 _L2);
      Store.update store left (LocationSet.singleton l_i)
    
    | _, AssignUnary {left; argument; id; _} -> 
      let _L1 = eval_expr argument in 
      let l_i = Graph.alloc graph id in 
      LocationSet.iter (Graph.addDepEdge graph l_i) _L1;
      Store.update store left (LocationSet.singleton l_i)

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
    | _, If {consequent; alternate; _} ->
      let state' = State.copy state in 
      analyse_sequence state consequent;
      option_may (analyse_sequence state') alternate;
      
      Graph.lub state.graph state'.graph;
      Store.lub state.store state'.store;

    (* -------- W H I L E -------- *)
    | _, While _ -> ()

    | _ -> ()
          (* failwith "statement node analysis not defined" *)
          
and analyse_sequence (state : state) = List.iter (analyse state)

and eval_expr (store : Store.t) (this : LocationSet.t) (expr : m Expression.t) : LocationSet.t = 
  match expr with
    | (_, Identifier _) as id -> 
      let id = Identifier.from_expression id in 
      Store.get store id 
    
    | _, Literal _ -> Store.literal_loc

    | _, This _ -> this

    | _, TemplateLiteral {expressions; _} -> 
      List.fold_left (fun acc elem -> LocationSet.union acc (eval_expr store this elem)) LocationSet.empty expressions



