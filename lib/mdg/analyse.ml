(* open Auxiliary.Functions *)
open Auxiliary.GraphJS
open Auxiliary.Functions
open Structures
open State

let verbose = ref false;;

let rec program (is_verbose : bool) ((_, {body}) : m Program.t) : Graph.t * Store.t = 
  verbose := is_verbose;
  
  let state = empty_state () in 
  analyse_sequence state body;
  state.graph, state.store

and analyse (state : state) (statement : m Statement.t) : unit =
  let graph = state.graph in 
  let store = state.store in 

  let eval_expr = eval_expr store state.this in 

  (match statement with
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
      LocationSet.iter (flip (Graph.addDepEdge graph) l_i) (LocationSet.union _L1 _L2);
      Store.update store left (LocationSet.singleton l_i);
    
    | _, AssignUnary {left; argument; id; _} -> 
      let _L1 = eval_expr argument in 
      let l_i = Graph.alloc graph id in 
      LocationSet.iter (flip (Graph.addDepEdge graph) l_i) _L1;
      Store.update store left (LocationSet.singleton l_i)

    (* -------- N E W   O B J E C T -------- *)
    | _, AssignObject {id; left} -> 
      let l_i = Graph.alloc graph id in
      Store.update store left (LocationSet.singleton l_i);
      Graph.addNode graph l_i;

    (* -------- S T A T I C   P R O P E R T Y   L O O K U P -------- *)
    | _, AssignStaticMember {left; _object; property=(_, {name=property; _}); id} -> 
      let _L = eval_expr _object in 
      Graph.staticAddProperty graph _L property id;
      let _L' = LocationSet.map (fun loc -> Graph.lookup graph loc property) _L  in 
      Store.update store left _L'

    (* -------- D Y N A M I C   P R O P E R T Y   L O O K U P -------- *)
    | _, AssignDynmicMember {left; _object; property; id} ->
      let _L1, _L2 = eval_expr _object, eval_expr property in 
      Graph.dynamicAddProperty graph _L1 _L2 id;
      let _L' = LocationSet.map (fun loc -> Graph.lookup graph loc "*") _L1 in
      Store.update store left _L'

    (* -------- S T A T I C   P R O P E R T Y   U P D A T E -------- *)
    | _, StaticMemberAssign {_object; property=(_, {name=property; _}); right; id} -> 
      let _L1, _L2 = eval_expr _object, eval_expr right in
      let _L1' = Graph.staticNewVersion graph store _L1 property id in 
      LocationSet.iter ( fun l_1 ->
        LocationSet.iter (fun l_2 ->
            Graph.addPropEdge graph l_1 l_2 (Some property)
          ) _L2
      ) _L1'

    (* -------- D Y N A M I C   P R O P E R T Y   U P D A T E -------- *)
    | _, DynmicMemberAssign {_object; property; right; id} -> 
      let _L1, _L2, _L3 = eval_expr _object, 
                          eval_expr property, 
                          eval_expr right in
      
      let _L1' = Graph.dynamicNewVersion graph store _L1 _L2 id in 
      LocationSet.iter ( fun l_1 ->
        LocationSet.iter (fun l_3 ->
            Graph.addPropEdge graph l_1 l_3 None
          ) _L3
      ) _L1'

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

    | _ -> ());
          (* failwith "statement node analysis not defined" *)
  
  if (!verbose) then (
    print_endline "----------";
    print_string (Pp.Js.print_stmt statement 0);

    print_endline "----------";
    print_endline "Graph\n------";
    Graph.print graph; 
    
    print_endline "Store\n------";
    Store.print store; 
    print_endline "----------"; )
          
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



