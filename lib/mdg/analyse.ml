(* open Auxiliary.Functions *)
module Graph = Graph'
module Functions = Ast.Functions
open Ast.Grammar
open Auxiliary.Functions
open Structures
open State


let verbose = ref false;;


let rec program (is_verbose : bool) (config : Config.t) ((_, program) : m Program.t) : Graph.t = 
  verbose := is_verbose;
  let state = empty_state config in 
  let state' = initialize_functions state program.functions in

  analyse_sequence state' program.body;
  state'.graph

and analyse (state : state) (statement : m Statement.t) : unit =
  let graph = state.graph in 
  let store = state.store in 
  let contx = state.context in
  let confg = state.config in 

  (* aliases *)
  let eval_expr = eval_expr store state.this in 
  let add_dep_edge = Graph.add_dep_edge graph in 
  let add_prop_edge = Graph.add_prop_edge graph in 
  let add_arg_edge = Graph.add_arg_edge graph in
  let add_call_edge = Graph.add_call_edge graph in 
  let add_ref_call_edge = Graph.add_ref_call_edge graph in 
  let add_ret_edge = Graph.add_ret_edge graph in 
  let store_update = Store.update store in 
  let alloc = Graph.alloc graph in 
  let falloc = Graph.alloc_function graph in 
  let add_node = Graph.add_obj_node graph in 
  let add_cnode = Graph.add_call_node graph in
  let add_ret_node = Graph.add_return_node graph in
  let add_property = Graph.staticAddProperty graph in 
  let add_property' = Graph.dynamicAddProperty graph in
  let lookup = Graph.lookup graph in  
  let new_version = Graph.staticNewVersion graph in 
  let new_version' = Graph.dynamicNewVersion graph in 
  let get_param_locs = Graph.get_param_locations graph in
  let get_param_names = Functions.Context.get_param_names' contx in 
  let get_func_id = Functions.Context.get_func_id contx in 
  let is_last_definition = Functions.Context.is_last_definition contx in 
  let visit = Functions.Context.visit contx in
  let get_curr_func = Functions.Context.get_current_function contx in 
  let get_func_sink_info = Config.get_function_sink_info confg in 

  (match statement with
    (* -------- A S S I G N - E X P R -------- *)
    | _, AssignSimple {left; right} -> 
      let _L = eval_expr right in 
      store_update left _L

    | loc, AssignFunction {left; id; body; _} ->

      let func_id : Functions.Id.t = {uid = id; name = Identifier.get_name left} in 
      (* functions with the same name can be nested inside the same context 
         (only consider the last definition with such name) *)
      if is_last_definition func_id then (
        (* ! add object that represents the function *)
        let l_i = alloc id in 
        add_node l_i (Identifier.get_name left) loc;
        store_update left (LocationSet.singleton l_i);

        (* add function definition dependency *)
        let f_i = falloc id in 
        add_dep_edge f_i l_i;
        
        (* setup new store with only the param and corresponding locations *)
        let param_locs = get_param_locs func_id in 
        let new_state = {state with store = param_locs; context = visit func_id} in
        analyse_sequence new_state body
      );
      

    (* -------- A S S I G N - O P -------- *)
    | loc, AssignBinary {left; opLeft; opRght; id; _} -> 
      let _L1, _L2 = eval_expr opLeft, eval_expr opRght in 
      let l_i = alloc id in 
      LocationSet.apply (flip add_dep_edge l_i) (LocationSet.union _L1 _L2);
      store_update left (LocationSet.singleton l_i);
      (* add node info*)
      add_node l_i (Identifier.get_name left) loc
    
    | loc, AssignUnary {left; argument; id; _} -> 
      let _L1 = eval_expr argument in 
      let l_i = alloc id in 
      LocationSet.apply (flip add_dep_edge l_i) _L1;
      store_update left (LocationSet.singleton l_i);
      (* add node info*)
      add_node l_i (Identifier.get_name left) loc


    (* -------- N E W   O B J E C T -------- *)
    | loc, AssignArray {id; left} 
    | loc, AssignObject {id; left} -> 
      let l_i = alloc id in
      store_update left (LocationSet.singleton l_i);
      add_node l_i (Identifier.get_name left) loc;
    

    (* -------- S T A T I C   P R O P E R T Y   L O O K U P -------- *)
    | loc, StaticLookup {left; _object; property; id; _} -> 
      let add_node' : location -> unit = fun abs_loc -> add_node abs_loc (property_lookup_name left _object property) loc in 
      
      let _L = eval_expr _object in 
      add_property _L property id add_node';
      let _L' = LocationSet.map_flat (flip lookup property) _L in 
      store_update left _L'

    (* -------- D Y N A M I C   P R O P E R T Y   L O O K U P -------- *)
    | loc, DynmicLookup {left; _object; property; id} ->
      let add_node' : location -> unit = fun abs_loc -> add_node abs_loc (property_lookup_name left _object "*") loc in 

      let _L1, _L2 = eval_expr _object, eval_expr property in 
      add_property' _L1 _L2 id add_node';
      let _L' = LocationSet.map_flat (flip lookup "*") _L1 in 
      store_update left _L'

    (* -------- S T A T I C   P R O P E R T Y   U P D A T E -------- *)
    | loc, StaticUpdate {_object; property; right; id; _} ->
      let add_node' : location -> unit = fun abs_loc -> add_node abs_loc (Expression.get_id _object) loc in 
      
      let _L1, _L2 = eval_expr _object, eval_expr right in
      let _L1' = new_version store _L1 property id add_node' in 
      LocationSet.apply ( fun l_1 ->
        LocationSet.apply (fun l_2 ->
            add_prop_edge l_1 l_2 (Some property)
          ) _L2
      ) _L1';

    (* -------- D Y N A M I C   P R O P E R T Y   U P D A T E -------- *)
    | loc, DynmicUpdate {_object; property; right; id} -> 
      let add_node' : location -> unit = fun abs_loc -> add_node abs_loc (Expression.get_id _object) loc in 

      let _L1, _L2, _L3 = eval_expr _object, 
                          eval_expr property, 
                          eval_expr right in

      let _L1' = new_version' store _L1 _L2 id add_node' in 
      LocationSet.apply ( fun l_1 ->
        LocationSet.apply (fun l_3 ->
            add_prop_edge l_1 l_3 None
          ) _L3
      ) _L1';


    (* -------- C A L L -------- *)
    | loc, AssignNewCall {left; callee; arguments; id_call; id_retn; _}
    | loc, AssignFunCall {left; callee; arguments; id_call; id_retn; _} -> 
      let _Lss = List.map eval_expr arguments in 
      let l_call = alloc id_call in 
      let l_retn = alloc id_retn in 

      (* get function definition information *)
      let f    = Identifier.get_name callee in 
      let f_id = get_func_id f in

      (* node information *)
      add_cnode l_call f loc;
      add_node l_retn (Identifier.get_name left) loc;
      
      (* argument edges *)
      let params = map_default get_param_names [] f_id in 
      List.iteri ( fun i _Ls -> 
        let param_name = Option.value (List.nth_opt params i) ~default:"undefined" in 
        LocationSet.apply (fun l -> add_arg_edge l l_call (string_of_int i) param_name) _Ls
      ) _Lss;

      (* checks if it is a sink and process it accordingly *)
      let sink_info = get_func_sink_info f in
      option_may (add_func_sink_node graph id_call l_call loc _Lss) sink_info;

      (* ! add ref call edge (shotcut) from function definition to this call *)
      let f_orig = get_curr_func () in
      option_may (fun id ->
        let l_f = Graph.get_func_node graph id in 
        add_ref_call_edge (Option.get l_f) l_call;
        ()
      ) f_orig;

      (* return edge *)
      add_ret_edge l_call l_retn;
      store_update left (LocationSet.singleton l_retn);

      (* call edge to function definition (if defined) *)
      option_may (fun id ->
        let l_f = Graph.get_func_node graph id in 
        add_call_edge l_call (Option.get l_f)
      ) f_id;
    
    | loc, AssignMetCallStatic {left; _object; property; arguments; id_call; id_retn; _} -> 
      analyse_method_call state loc left _object property arguments id_call id_retn;
    
    | loc, AssignMetCallDynmic {left; _object; property; arguments; id_call; id_retn; _} -> 
      let property' = Expression.get_id property in 
      analyse_method_call state loc left _object property' arguments id_call id_retn;



    (* -------- I F -------- *)
    | _, If {consequent; alternate; _} ->
      let state' = State.copy state in 
      analyse_sequence state consequent;
      option_may (analyse_sequence state') alternate;
      
      Graph.lub state.graph state'.graph;
      Store.lub state.store state'.store;
    
    (* -------- S W I T C H --------*)
    | _, Switch {cases; _} -> 
      let bodies = List.map (fun (_, case) -> case.Statement.Switch.Case.consequent) cases in 
      List.iter ( fun body -> analyse_sequence state body) bodies

    (* -------- W H I L E  /  F O R -------- *)
    | _, ForIn {body; _}
    | _, ForOf {body; _} 
    | _, While {body; _} -> 
       ifp (flip analyse_sequence body) state

    (* -------- T R Y  -  C A T C H -------- *)
    | _, Try {body; handler; finalizer} ->
      analyse_sequence state body;
      let handler_body = Option.map (fun (_, handler) -> handler.Statement.Try.Catch.body) handler in 
      option_may (analyse_sequence state) handler_body;
      option_may (analyse_sequence state) finalizer

    (* -------- W I T H  /  L A B E L E D -------- *)
    | _, Labeled {body; _}
    | _, With    {body; _} -> 
      analyse_sequence state body

    (* -------- R E T U R N -------- *)
    | loc, Return {id; argument} -> 
      let _L = Option.map eval_expr argument in 
      let l_retn = alloc id in 

      if (Option.is_some _L) then (
        let _L = Option.get _L in
        LocationSet.apply (flip add_dep_edge l_retn) _L
      );

      add_ret_node l_retn loc;


    (* -------- O T H E R   C O N S T R U C T S -------- *)
    | _, VarDecl  _
    | _, Throw    _ 
    | _, Break    _ 
    | _, Yield    _ 
    | _, Continue _ 
    | _, Debugger _ -> ()
        
    | _ -> failwith "statement node analysis not defined");
  
  if (!verbose) then (
    print_endline "--------------";
    print_string (Ast.Pp.Js.print_stmt statement 0);
    print_endline "--------------";

    print_endline "Graph: ";
    Graph.print graph; 
    
    print_endline "Store: ";
    Store.print store; )

(* ------- P R I M I T I V E   F U N C T I O N S --------*)
and analyse_sequence (state : state) = List.iter (analyse state)

and ifp (f : state -> unit) (state : state) : unit =

  setup ();
  let store' = Store.copy state.store in 
  
  f state;
  Store.lub state.store store';
  if not (Store.equal state.store store')
    then ifp f state

and eval_expr (store : Store.t) (this : LocationSet.t) (expr : m Expression.t) : LocationSet.t = 
  match expr with
    | (_, Identifier _) as id -> 
      let id = Identifier.from_expression id in 
      Store.get store id 
    
    | _, Literal _ -> Store.loc_literal

    | _, This _ -> this

    | _, TemplateLiteral {expressions; _} -> 
      List.fold_left (fun acc elem -> LocationSet.union acc (eval_expr store this elem)) LocationSet.empty expressions


(* ----- A N A L I S Y S   F U N C T I O N S ----- *)
and analyse_method_call (state : state) (loc : Location.t) (left : m Identifier.t) (_object : m Expression.t) (property : property) (arguments : m Expression.t list) (id_call : int) (id_retn : int) : unit =
  (* ! is this a way to represent it? *)
  (* aliases *)
  let eval_expr = eval_expr state.store state.this in 
  let store_update = Store.update state.store in 
  let alloc = Graph.alloc state.graph in 
  let add_node = Graph.add_obj_node state.graph in
  let add_cnode = Graph.add_call_node state.graph in
  let add_ret_edge = Graph.add_ret_edge state.graph in 
  let add_arg_edge = Graph.add_arg_edge state.graph in
  let add_ref_call_edge = Graph.add_ref_call_edge state.graph in 
  let get_curr_func = Functions.Context.get_current_function state.context in  



  let _Lss = List.map eval_expr arguments in 
      
  let _Lthis = eval_expr _object in
  let l_call = alloc id_call in 
  let l_retn = alloc id_retn in 
  
  (* get function definition information *)
  let f = Expression.get_id _object ^ "." ^ property in 

  (* node information *)
  add_cnode l_call f loc;
  add_node l_retn (Identifier.get_name left) loc;

  (* ! graphjs only adds edge for this property *)
  LocationSet.apply (fun l_this -> add_arg_edge  l_this l_call "this" "this") _Lthis;
  List.iteri ( fun i _Ls -> 
    LocationSet.apply (fun l -> add_arg_edge l l_call (string_of_int i) "undefined") _Ls
  ) _Lss;

  (* ! add ref call edge (shotcut) from function definition to this call *)
  let f_orig = get_curr_func () in
  option_may (fun id ->
    let l_f = Graph.get_func_node state.graph id in 
    add_ref_call_edge (Option.get l_f) l_call;
    ()
  ) f_orig;

  (* return edge *)
  add_ret_edge l_call l_retn;
  store_update left (LocationSet.singleton l_retn);


and initialize_functions (state : state) (funcs_info : Functions.Info.t) : state =
  let l_tsource = loc_taint_source in 
  let init_func_header (state : state) (func : Functions.Id.t) (info : Functions.Info.info) : unit =
    let graph = state.graph in 
    let alloc_fun      = Graph.alloc_function graph in 
    let add_func_node  = Graph.add_func_node  graph in 
    let add_param_node = Graph.add_param_node graph in 
    let add_param_edge = Graph.add_param_edge graph in 
    let add_taint_edge = Graph.add_taint_edge graph in

    let l_f = alloc_fun func.uid in 
    add_func_node l_f func (Location.empty ());

    (* add param nodes and edges *)
    List.iteri (fun i param -> 
      let l_p = Graph.alloc_param graph in 
      add_param_node l_p param (Location.empty ());
      (* ! what are taint sources? *)
      add_taint_edge l_tsource l_p;
      if param = "this" 
        then add_param_edge l_f l_p "this"
        else add_param_edge l_f l_p (Int.to_string (i - 1))
    ) ("this" :: info.params);
  in

  Functions.Info.iter (init_func_header state) funcs_info;
  {state with context = Functions.Context.create funcs_info }

(* ----- O T H E R   F U N C T I O N S ------ *)
and property_lookup_name (left : m Identifier.t) (_object : m Expression.t) (property : string) : string =
  let obj_prop = Expression.get_id _object ^ "." ^ property in 
  if Identifier.is_generated left then obj_prop else Identifier.get_name left ^ ", " ^ obj_prop

and add_func_sink_node (graph : Graph.t) (id_call : int) (l_call : location) (loc : Location.t) (args : LocationSet.t list) (sink_info : Config.functionSink) : unit = 
  let salloc = Graph.alloc_tsink graph in
  let add_tsink = Graph.add_taint_sink graph in 
  let add_sink_edge = Graph.add_sink_edge graph in
  let add_dep_edge = Graph.add_dep_edge graph in 
  let sink_name = sink_info.sink in 

  let l_tsink = salloc id_call in
  add_tsink l_tsink sink_name loc;
  add_sink_edge l_call l_tsink sink_name;

  (* add depedency edges from dangerous inputs (arguments) to taint sink *)
  let dangerous_inputs = sink_info.args in
  List.iter (fun dangerous_index ->
    let arg_locs = List.nth args (dangerous_index - 1)  in
    LocationSet.apply (fun l -> add_dep_edge l l_tsink) arg_locs
  ) dangerous_inputs