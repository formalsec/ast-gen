(* open Auxiliary.Functions *)
open Normalizer.Structures
open Auxiliary.Functions
open Structures
open State

let verbose = ref false;;

let register, setup, was_changed =
  let bs : bool list ref = ref [] in 
 
  let reg = fun () -> match !bs with 
  	| _ :: bs' -> bs := true :: bs'
  	| _ -> () in
  	
  let push = fun () -> bs := false :: !bs in
   
  let pop = fun () -> match !bs with 
  	| b :: bs' -> bs := bs'; b
  	| _ -> failwith "no element to pop" in 
  
  reg, push, pop;;
  

let rec program (is_verbose : bool) ((_, {body; functions}) : m Program.t) : Graph.t * Store.t = 
  verbose := is_verbose;
  let state = empty_state functions in 
  analyse_sequence state body;
  state.graph, state.store

and analyse (state : state) (statement : m Statement.t) : unit =
  let graph = state.graph in 
  let store = state.store in 
  let funcs = state.functions in 

  (* aliases *)
  let eval_expr = eval_expr store state.this in 
  let add_dep_edge = Graph.addDepEdge register graph in 
  let add_prop_edge = Graph.addPropEdge register graph in 
  let add_arg_edge = Graph.addArgEdge register graph in 
  let store_update = Store.update register store in 
  let alloc = Graph.alloc graph in 
  let add_node = Graph.addNode register graph in 
  let add_property = Graph.staticAddProperty register graph in 
  let add_property' = Graph.dynamicAddProperty register graph in
  let lookup = Graph.lookup graph in  
  let new_version = Graph.staticNewVersion register graph in 
  let new_version' = Graph.dynamicNewVersion register graph in 
  let get_param_name = FunctionInfo.get_param_name funcs in 

  (match statement with
    (* -------- A S S I G N - E X P R -------- *)
    | _, AssignSimple {left; right} -> 
      let _L = eval_expr right in 
      store_update left _L

    (* -------- A S S I G N - O P -------- *)
    | _, AssignBinary {left; opLeft; opRght; id; _} -> 
      let _L1, _L2 = eval_expr opLeft, eval_expr opRght in 
      let l_i = alloc id in 
      LocationSet.iter (flip add_dep_edge l_i) (LocationSet.union _L1 _L2);
      store_update left (LocationSet.singleton l_i);
    
    | _, AssignUnary {left; argument; id; _} -> 
      let _L1 = eval_expr argument in 
      let l_i = alloc id in 
      LocationSet.iter (flip add_dep_edge l_i) _L1;
      store_update left (LocationSet.singleton l_i)

    (* -------- N E W   O B J E C T -------- *)
    | _, AssignObject {id; left} -> 
      let l_i = alloc id in
      store_update left (LocationSet.singleton l_i);
      add_node l_i;

    (* -------- S T A T I C   P R O P E R T Y   L O O K U P -------- *)
    | _, AssignStaticMember {left; _object; property=(_, {name=property; _}); id} -> 
      let _L = eval_expr _object in 
      add_property _L property id;
      let _L' = LocationSet.map (fun loc -> lookup loc property) _L  in 
      store_update left _L'

    (* -------- D Y N A M I C   P R O P E R T Y   L O O K U P -------- *)
    | _, AssignDynmicMember {left; _object; property; id} ->
      let _L1, _L2 = eval_expr _object, eval_expr property in 
      add_property' _L1 _L2 id;
      let _L' = LocationSet.map (fun loc -> lookup loc "*") _L1 in
      store_update left _L'

    (* -------- S T A T I C   P R O P E R T Y   U P D A T E -------- *)
    | _, StaticMemberAssign {_object; property=(_, {name=property; _}); right; id} -> 
      let _L1, _L2 = eval_expr _object, eval_expr right in
      let _L1' = new_version store _object _L1 property id in 
      LocationSet.iter ( fun l_1 ->
        LocationSet.iter (fun l_2 ->
            add_prop_edge l_1 l_2 (Some property)
          ) _L2
      ) _L1'

    (* -------- D Y N A M I C   P R O P E R T Y   U P D A T E -------- *)
    | _, DynmicMemberAssign {_object; property; right; id} -> 
      let _L1, _L2, _L3 = eval_expr _object, 
                          eval_expr property, 
                          eval_expr right in
       
      let _L1' = new_version' store _object _L1 _L2 id in 
      LocationSet.iter ( fun l_1 ->
        LocationSet.iter (fun l_3 ->
            add_prop_edge l_1 l_3 None
          ) _L3
      ) _L1'

    (* -------- C A L L -------- *)
    | _, AssignNew {left; callee; arguments; id; _}
    | _, AssignFunCall {left; callee; arguments; id; _} -> 
      let _Lss = List.map eval_expr arguments in 
      let l_call = alloc id in 
      List.iteri ( fun i _Ls -> 
        LocationSet.iter (fun l -> add_arg_edge l l_call (get_param_name (Identifier.get_name callee) i)) _Ls
      ) _Lss;
      
      (* TODO : add call edge from l_call to function definition node *)
      (* TODO : function definition node not yet implemented *)
      
      store_update left (LocationSet.singleton l_call);

    (* -------- I F -------- *)
    | _, If {consequent; alternate; _} ->
      let state' = State.copy state in 
      analyse_sequence state consequent;
      option_may (analyse_sequence state') alternate;
      
      Graph.lub register state.graph state'.graph;
      Store.lub register state.store state'.store;

    (* -------- W H I L E -------- *)
    | _, While {body; _} -> 
      ifp (flip analyse_sequence body) state
        
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

and ifp (f : state -> unit) (state : state) : unit =
  setup ();
  f state;
  if not (was_changed ()) 
    then ifp f state


and eval_expr (store : Store.t) (this : LocationSet.t) (expr : m Expression.t) : LocationSet.t = 
  match expr with
    | (_, Identifier _) as id -> 
      let id = Identifier.from_expression id in 
      Store.get store id 
    
    | _, Literal _ -> Store.literal_loc

    | _, This _ -> this

    | _, TemplateLiteral {expressions; _} -> 
      List.fold_left (fun acc elem -> LocationSet.union acc (eval_expr store this elem)) LocationSet.empty expressions



