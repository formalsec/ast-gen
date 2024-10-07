open Graphjs_base
open Graphjs_ast
open Graphjs_setup
module EdgeSet = Mdg.EdgeSet
module Edge = Mdg.Edge
open Grammar
open Structures
open AnalysisType
open ExternalReferences

let verbose = ref false

module GraphConstrunction (Auxiliary : AbstractAnalysis.T) = struct
  type t =
    { state : State.t
    ; auxiliary : Auxiliary.t
    }

  (* ------- I N I T I A L I Z E ------- *)
  let initialize_functions (state : State.t) (funcs_info : Functions.Info.t) :
      unit =
    let init_func_header (state : State.t) (func : Functions.Id.t)
        (info : Functions.Info.info) : unit =
      let graph = state.graph in
      let alloc_fun = Mdg.alloc_function graph in
      let add_func_node = Mdg.add_func_node graph in
      let add_param_node = Mdg.add_param_node graph in
      let add_param_edge = Mdg.add_param_edge graph in

      let l_f = alloc_fun func.uid in
      add_func_node l_f func info.params (Location.empty ());
      Store.update' state.store func.name (LocationSet.singleton l_f);

      (* add param nodes and edges *)
      List.iteri
        (fun i param ->
          let l_p = Mdg.alloc_param graph in
          add_param_node l_p param (Location.empty ());
          if param = "this" then add_param_edge l_f l_p "this"
          else add_param_edge l_f l_p (Int.to_string (i - 1)) )
        ("this" :: info.params) in

    Functions.Info.iter (init_func_header state) funcs_info

  let init (function_info : Functions.Info.t) : t =
    let state' = State.empty_state function_info in
    Mdg.add_literal_node state'.graph;
    Mdg.add_taint_source state'.graph;
    initialize_functions state' function_info;

    { state = state'; auxiliary = Auxiliary.init () }

  (* ------- C O R E   A N A L Y S I S -------*)
  let rec analyse_sequence (state : State.t) (analysis : Auxiliary.t ref) =
    List.iter (analyse state analysis)

  and analyse (state : State.t) (analysis : Auxiliary.t ref)
      (statement : m Statement.t) : unit =
    match statement with
    (* -------- I F -------- *)
    | (_, If { consequent; alternate; _ }) ->
      let state' = State.copy state in
      analyse_sequence state analysis consequent;
      Option.iter (analyse_sequence state' analysis) alternate;

      Mdg.lub state.graph state'.graph;
      Store.lub state.store state'.store
    (* -------- S W I T C H --------*)
    | (_, Switch { cases; _ }) ->
      let bodies =
        List.map (fun (_, case) -> case.Statement.Switch.Case.consequent) cases
      in
      List.iter (fun body -> analyse_sequence state analysis body) bodies
    (* -------- W H I L E  /  F O R -------- *)
    | (_, ForIn { body; _ }) | (_, ForOf { body; _ }) | (_, While { body; _ })
      ->
      let rec fixed_point_computation (state : State.t) : unit =
        State.setup ();
        let store' = Store.copy state.store in

        analyse_sequence state analysis body;
        Store.lub state.store store';
        if not (Store.equal state.store store') then
          fixed_point_computation state in

      fixed_point_computation state
    (* -------- T R Y  -  C A T C H -------- *)
    | (_, Try { body; handler; finalizer }) ->
      analyse_sequence state analysis body;
      let handler_body =
        Option.map
          (fun (_, handler) -> handler.Statement.Try.Catch.body)
          handler in
      Option.iter (analyse_sequence state analysis) handler_body;
      Option.iter (analyse_sequence state analysis) finalizer
    (* -------- W I T H  /  L A B E L E D -------- *)
    | (_, Labeled { body; _ }) | (_, With { body; _ }) ->
      analyse_sequence state analysis body
    | _ -> analyse_simple state analysis statement

  and analyse_simple (state : State.t) (analysis : Auxiliary.t ref)
      (statement : m Statement.t) : unit =
    let graph = state.graph in
    let store = state.store in
    let contx = state.context in

    (* aliases *)
    let eval_expr = Store.eval_expr store state.this in
    let add_dep_edge = Mdg.add_dep_edge graph in
    let add_arg_edge = Mdg.add_arg_edge graph in
    let add_call_edge = Mdg.add_call_edge graph in
    let add_ref_call_edge = Mdg.add_ref_call_edge graph in
    let add_ret_edge = Mdg.add_ret_edge graph in
    let store_update = Store.update store in
    let alloc = Mdg.alloc graph in
    let falloc = Mdg.alloc_function graph in
    let add_node = Mdg.add_obj_node graph in
    let add_cnode = Mdg.add_call_node graph in
    let add_ret_node = Mdg.add_return_node graph in
    let add_property = Mdg.staticAddProperty graph in
    let add_property' = Mdg.dynamicAddProperty graph in
    let lookup = Mdg.lookup graph in
    let new_version = Mdg.staticNewVersion graph in
    let new_version' = Mdg.dynamicNewVersion graph in
    let get_param_locs = Mdg.get_param_locations graph in
    let get_param_names = Functions.Context.get_param_names' contx in
    let get_func_id = Functions.Context.get_func_id contx in
    let is_last_definition = Functions.Context.is_last_definition contx in
    let visit = Functions.Context.visit contx in
    let get_curr_func = Functions.Context.get_current_function contx in

    ( match statement with
    (* -------- A S S I G N - E X P R -------- *)
    | (_, AssignSimple { left; right }) ->
      let _L = eval_expr right in
      store_update left _L
    | (_, AssignFunction { left; id; body; _ }) ->
      let func_id : Functions.Id.t =
        { uid = id; name = Identifier.get_name left } in
      (* functions with the same name can be nested inside the same context
          (only consider the last definition with such name) *)
      if is_last_definition func_id then (
        (* add function definition dependency *)
        let f_i = falloc id in
        store_update left (LocationSet.singleton f_i);

        (* setup new store with only the param and corresponding locations *)
        let param_locs = get_param_locs func_id in
        let new_state =
          { state with
            store = Store.merge store param_locs
          ; context = visit func_id
          } in
        analyse_sequence new_state analysis body )
    (* -------- A S S I G N - O P -------- *)
    | (loc, AssignBinary { left; opLeft; opRght; id; _ }) ->
      let (_L1, _L2) = (eval_expr opLeft, eval_expr opRght) in
      let l_i = alloc id in
      LocationSet.apply (Fun.flip add_dep_edge l_i) (LocationSet.union _L1 _L2);
      store_update left (LocationSet.singleton l_i);

      (* ! add node info*)
      add_node l_i (Identifier.get_name left) loc
    | (loc, AssignUnary { left; argument; id; _ }) ->
      let _L1 = eval_expr argument in
      let l_i = alloc id in
      LocationSet.apply (Fun.flip add_dep_edge l_i) _L1;
      store_update left (LocationSet.singleton l_i);

      (* ! add node info*)
      add_node l_i (Identifier.get_name left) loc
    (* -------- N E W   O B J E C T -------- *)
    | (loc, AssignArray { id; left }) | (loc, AssignObject { id; left }) ->
      let l_i = alloc id in
      store_update left (LocationSet.singleton l_i);
      add_node l_i (Identifier.get_name left) loc
    (* -------- S T A T I C   P R O P E R T Y   L O O K U P -------- *)
    | (loc, StaticLookup { left; _object; property; id; _ }) ->
      let add_node' : location -> unit =
       fun abs_loc ->
        add_node abs_loc (property_lookup_name left _object property) loc in

      let _L = eval_expr _object in
      add_property _L property id add_node';
      let _L' = LocationSet.map_flat (Fun.flip lookup property) _L in
      store_update left _L'
    (* -------- D Y N A M I C   P R O P E R T Y   L O O K U P -------- *)
    | (loc, DynmicLookup { left; _object; property; id }) ->
      let add_node' : location -> unit =
       fun abs_loc ->
        add_node abs_loc (property_lookup_name left _object "*") loc in

      let (_L1, _L2) = (eval_expr _object, eval_expr property) in
      add_property' _L1 _L2 id add_node';
      let _L' = LocationSet.map_flat (Fun.flip lookup "*") _L1 in
      store_update left _L'
    (* -------- S T A T I C   P R O P E R T Y   U P D A T E -------- *)
    | (loc, StaticUpdate { _object; property; right; id; _ }) ->
      let add_node' : location -> unit =
       fun abs_loc ->
        add_node abs_loc
          (Option.value (Expression.get_id_opt _object) ~default:"*")
          loc in

      let (_L1, _L2) = (eval_expr _object, eval_expr right) in
      let _L1' = new_version store _L1 property id add_node' in
      LocationSet.apply
        (fun l_1 ->
          LocationSet.apply
            (fun l_2 -> Mdg.add_prop_edge graph l_1 l_2 (Some property))
            _L2 )
        _L1'
    (* -------- D Y N A M I C   P R O P E§ R T Y   U P D A T E -------- *)
    | (loc, DynmicUpdate { _object; property; right; id }) ->
      let add_node' : location -> unit =
       fun abs_loc ->
        add_node abs_loc
          (Option.value (Expression.get_id_opt _object) ~default:"*")
          loc in

      let (_L1, _L2, _L3) =
        (eval_expr _object, eval_expr property, eval_expr right) in

      let _L1' = new_version' store _L1 _L2 id add_node' in
      LocationSet.apply
        (fun l_1 ->
          LocationSet.apply
            (fun l_3 -> Mdg.add_prop_edge graph l_1 l_3 None)
            _L3 )
        _L1'
    (* -------- C A L L -------- *)
    | (loc, AssignNewCall { left; callee; arguments; id_call; id_retn; _ })
    | (loc, AssignFunCall { left; callee; arguments; id_call; id_retn; _ }) ->
      let _Lss = List.map eval_expr arguments in
      let l_call = alloc id_call in
      let l_retn = alloc id_retn in

      (* get function definition information *)
      let f = Identifier.get_name callee in
      let f_id = get_func_id f in

      (* node information *)
      add_cnode l_call f loc;
      add_node l_retn (Identifier.get_name left) loc;

      (* argument edges *)
      let params = Option.apply get_param_names ~default:[] f_id in
      List.iteri
        (fun i _Ls ->
          let param_name =
            Option.value (List.nth_opt params i) ~default:"undefined" in
          LocationSet.apply
            (fun l -> add_arg_edge l l_call (string_of_int i) param_name)
            _Ls )
        _Lss;

      (* ! add ref call edge (shotcut) from function definition to this call *)
      let f_orig = get_curr_func () in
      Option.iter
        (fun id ->
          let l_f = Mdg.get_func_node graph id in
          add_ref_call_edge (Option.get l_f) l_call;
          () )
        f_orig;

      (* return edge *)
      add_ret_edge l_call l_retn;
      store_update left (LocationSet.singleton l_retn);

      (* call edge to function definition (if defined) *)
      Option.iter
        (fun id ->
          let l_f = Mdg.get_func_node graph id in
          add_call_edge l_call (Option.get l_f) )
        f_id
    | ( loc
      , AssignMetCallStatic
          { left; _object; property; arguments; id_call; id_retn; _ } ) ->
      analyse_method_call state loc left _object property arguments id_call
        id_retn
    | ( loc
      , AssignMetCallDynmic { left; _object; arguments; id_call; id_retn; _ } )
      ->
      analyse_method_call state loc left _object "*" arguments id_call id_retn
    (* -------- R E T U R N -------- *)
    | (loc, Return { id; argument }) ->
      let _L = Option.map eval_expr argument in
      let l_retn = alloc id in

      ( if Option.is_some _L then
          let _L = Option.get _L in
          LocationSet.apply (Fun.flip add_dep_edge l_retn) _L );

      add_ret_node l_retn loc
    | (_, AssignYield _)
    (* -------- O T H E R   C O N S T R U C T S -------- *)
    | (_, ExportDefaultDecl _)
    | (_, ExportNamedDecl _)
    | (_, ImportDecl _)
    | (_, VarDecl _)
    | (_, Throw _)
    | (_, Break _)
    | (_, Continue _)
    | (_, Debugger _) ->
      ()
    | _ -> failwith "[ERROR] Statement node analysis not defined" );

    analysis := Auxiliary.analyse !analysis state statement

  and property_lookup_name (left : m Identifier.t) (_object : m Expression.t)
      (property : string) : string =
    let obj_name = Option.value (Expression.get_id_opt _object) ~default:"*" in
    let obj_prop = obj_name ^ "." ^ property in
    if Identifier.is_generated left then obj_prop
    else Identifier.get_name left ^ ", " ^ obj_prop

  and analyse_method_call (state : State.t) (loc : Location.t)
      (left : m Identifier.t) (_object : m Expression.t) (property : property)
      (arguments : m Expression.t list) (id_call : int) (id_retn : int) : unit =
    (* aliases *)
    let graph = state.graph in
    let eval_expr = Store.eval_expr state.store state.this in
    let store_update = Store.update state.store in
    let alloc = Mdg.alloc graph in
    let add_node = Mdg.add_obj_node graph in
    let add_cnode = Mdg.add_call_node graph in
    let add_ret_edge = Mdg.add_ret_edge graph in
    let add_arg_edge = Mdg.add_arg_edge graph in
    let add_call_edge = Mdg.add_call_edge graph in
    let add_ref_call_edge = Mdg.add_ref_call_edge graph in
    let get_curr_func = Functions.Context.get_current_function state.context in
    let lookup = Mdg.lookup graph in

    let _Lss = List.map eval_expr arguments in

    let _Lthis = eval_expr _object in
    let l_call = alloc id_call in
    let l_retn = alloc id_retn in

    (* get function definition information *)
    let obj_name = Option.value (Expression.get_id_opt _object) ~default:"*" in
    let f = obj_name ^ "." ^ property in

    (* node information *)
    add_cnode l_call f loc;
    add_node l_retn (Identifier.get_name left) loc;

    (* ! graphjs only adds edge for this property *)
    LocationSet.apply
      (fun l_this -> add_arg_edge l_this l_call "this" "this")
      _Lthis;

    (* lookup function header node associated with the property *)
    let found_func = ref false in
    ( if property != "*" then
        let _Lfunc = LocationSet.map_flat (Fun.flip lookup property) _Lthis in
        if LocationSet.cardinal _Lfunc = 1 then
          let l_func = LocationSet.min_elt _Lfunc in
          let func_node = Mdg.find_node_opt graph l_func in
          match func_node with
          | Some { _type = Function (_, params); _ } ->
            ();
            List.iteri
              (fun i _Ls ->
                let param_name =
                  Option.value (List.nth_opt params i) ~default:"undefined"
                in
                LocationSet.apply
                  (fun l -> add_arg_edge l l_call (string_of_int i) param_name)
                  _Ls )
              _Lss;
            add_call_edge l_call l_func;
            found_func := true
          | _ -> () );

    if not !found_func then
      List.iteri
        (fun i _Ls ->
          LocationSet.apply
            (fun l -> add_arg_edge l l_call (string_of_int i) "undefined")
            _Ls )
        _Lss;

    (* ! add ref call edge (shotcut) from function definition to this call
       ! did this to be comaptible with graphjs queries *)
    let f_orig = get_curr_func () in
    Option.iter
      (fun id ->
        let l_f = Mdg.get_func_node state.graph id in
        add_ref_call_edge (Option.get l_f) l_call;
        () )
      f_orig;

    (* return edge *)
    add_ret_edge l_call l_retn;
    store_update left (LocationSet.singleton l_retn)

  let run (init : t) (statements : m Statement.t list) : State.t * Auxiliary.t =
    let auxiliary = ref init.auxiliary in
    let state = init.state in

    analyse_sequence state auxiliary statements;
    (state, !auxiliary)
end

let rec add_taint_sinks (state : State.t) (config : Tainted_config.t)
    (ext_calls : ExternalReferences.t) : unit =
  let graph = state.graph in

  Mdg.iter_nodes
    (fun loc node ->
      match node._type with
      | Call callee ->
        (* function sink *)
        let sink_info = Tainted_config.get_function_sink_info config callee in
        Option.iter
          (fun (sink_info : Tainted_config.functionSink) ->
            add_taink_sink graph loc node sink_info.sink sink_info.args )
          sink_info;

        (* package sink *)
        let referece_info = ExternalReferences.get_opt ext_calls loc in
        Option.iter
          (fun ref ->
            (* check if there is only one property *)
            if List.length ref.properties = 1 then
              let method_name = List.nth ref.properties 0 in
              let package_name = ref._module in
              let sink_info =
                Tainted_config.get_package_sink_info config package_name method_name
              in
              Option.iter
                (fun (sink_info : Tainted_config.package) ->
                  add_taink_sink graph loc node method_name sink_info.args )
                sink_info )
          referece_info
      | _ -> () )
    graph

and add_taink_sink (graph : Mdg.t) (loc : location) (node : Mdg.Node.t)
    (sink_name : string) (sink_args : int list) : unit =
  let salloc = Mdg.alloc_tsink graph in
  let add_tsink = Mdg.add_taint_sink graph in
  let add_sink_edge = Mdg.add_sink_edge graph in
  let add_dep_edge = Mdg.add_dep_edge graph in

  (* add taint sink *)
  let l_tsink = salloc node.id in
  add_tsink l_tsink sink_name node.loc;
  add_sink_edge loc l_tsink sink_name;

  (* add depedency edges from dangerous inputs (arguments) to taint sink *)
  let args = Mdg.get_arg_locations graph loc in
  List.iter
    (fun dangerous_index ->
      let dangerous_index = string_of_int (dangerous_index - 1) in
      let arg_locs = List.filter Fun.(( = ) dangerous_index << fst) args in
      List.iter (fun (_, l) -> add_dep_edge l l_tsink) arg_locs )
    sink_args

let add_taint_sources (state : State.t) (_config : Tainted_config.t) (mode : Mode.t)
    (is_main : bool) (exportsObject : ExportedObject.t) : unit =
  let graph = state.graph in
  let l_tsource = loc_taint_source in
  let add_taint_edge = Mdg.add_taint_edge graph in

  (* BASIC ATTACKER MODEL :
       -> the attacker controlls all function parameters
     .*)
  if Mode.is_basic mode then
    Mdg.iter_nodes
      (fun location node ->
        match node._type with
        | Function _ ->
          let edges = Mdg.get_edges graph location in
          EdgeSet.iter
            (fun (edge : Edge.t) ->
              match edge._type with
              | Edge.Parameter _ -> add_taint_edge l_tsource edge._to
              | _ -> () )
            edges
        | _ -> () )
      graph
    (* SINGLE-FILE ATTACKER MODEL
         -> the attacker controlls all exported functions of the input file

         MULTI-FILE ATTACKER MODEL
         ->  the attacker controlls all exported functions of the main file
       .*)
  else if Mode.is_single_file mode || (Mode.is_multi_file mode && is_main) then
    let exported_funcs = ExportedObject.get_all_values exportsObject in
    List.iter
      (fun l_func ->
        let func_node = Mdg.find_node graph l_func in
        match func_node._type with
        | Function _ ->
          let edges = Mdg.get_edges graph l_func in
          EdgeSet.iter
            (fun (edge : Edge.t) ->
              match edge._type with
              | Edge.Parameter _ -> add_taint_edge l_tsource edge._to
              | _ -> () )
            edges
        | _ -> () )
      exported_funcs

let rec buildExportsObject (state : State.t) (info : buildExportsObject) :
    ExportedObject.t =
  (* module.exports is assigned to a variable *)
  let exportsObject = ref (ExportedObject.create 10) in
  Option.iter
    (fun loc -> exportsObject := construct_object state loc)
    info.moduleExportsObject;

  (* assignments to the properties of module.exports *)
  Hashtbl.iter
    (fun property loc ->
      let object' = construct_object state loc in
      exportsObject :=
        ExportedObject.add_property !exportsObject property object' )
    info.moduleExportsAssigns;

  (* assignments to the properties of exports *)
  Hashtbl.iter
    (fun property loc ->
      let object' = construct_object state loc in
      exportsObject :=
        ExportedObject.add_property !exportsObject property object' )
    info.exportsAssigns;

  !exportsObject

and construct_object (state : State.t) (loc : LocationSet.t) : ExportedObject.t
    =
  let graph = state.graph in
  if LocationSet.cardinal loc = 1 then
    let loc = LocationSet.min_elt loc in
    let node = Mdg.find_node state.graph loc in
    match node._type with
    | Object _ ->
      let object' = ref (ExportedObject.create 10) in
      let all_properties = Mdg.get_static_properties graph loc in
      List.iter
        (fun property ->
          let _L = Mdg.lookup graph loc property in
          let object'' = construct_object state _L in
          object' := ExportedObject.add_property !object' property object'' )
        all_properties;

      (* return *)
      !object'
    | Function _ -> ExportedObject.Value loc
    | _ -> ExportedObject.empty ()
  else if LocationSet.is_empty loc then ExportedObject.empty ()
  else failwith "[ERROR] exported object has a property with multiple locations"

let rec program (mode : Mode.t) (is_verbose : bool) (config_path : string)
    (program : m Program.t) : Mdg.t * ExportedObject.t * ExternalReferences.t =
  verbose := is_verbose;

  let module Analysis =
    AbstractAnalysis.Combine
      (BuildExportsObject.Analysis)
      (AbstractAnalysis.Combine
         (CollectExternalCalls.Analysis)
         (SinkAliases.Analysis (struct
           let filename = config_path
         end)))
  in
  let module BuildMDG = GraphConstrunction (Analysis) in
  let init_state = BuildMDG.init (Program.get_functions program) in
  let (state, analysis) = BuildMDG.run init_state (Program.get_body program) in

  (* process auxiliary analysis outputs*)
  let (exportsObjectInfo, config, external_calls) =
    get_analysis_output (Analysis.finish analysis) in

  let exportsObject = buildExportsObject state exportsObjectInfo in
  add_taint_sinks state config external_calls;
  add_taint_sources state config mode (Program.is_main program) exportsObject;

  (state.graph, exportsObject, external_calls)

and get_analysis_output (result : AnalysisType.t) :
    buildExportsObject * sinkAliases * collectExternalCalls =
  match result with
  | Combined
      ( BuildExportsObject exportsObject
      , Combined (CollectExternalCalls ext_calls, SinkAliases config) ) ->
    (exportsObject, config, ext_calls)
  | _ -> failwith "[ERROR] Unable to extract analysis output"
