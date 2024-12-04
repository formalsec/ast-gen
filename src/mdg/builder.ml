open Graphjs_base
open Graphjs_shared
open Graphjs_ast
open Metadata

type cid = State.CodeCache.id

let cid : 'm Statement.t -> cid = State.CodeCache.cid
let offset : cid -> int -> cid = State.CodeCache.offset

type func =
  | Func of (Node.t * Node.t list)
  | Sink of Node.t
(* | Requires *)

let object_name (ls_obj : Node.Set.t) (obj : 'm Expression.t) : string =
  (* TODO: add a flag to disable compound object names *)
  if Node.Set.cardinal ls_obj == 1 then Node.name (Node.Set.choose ls_obj)
  else Expression.str obj

let object_property_name (ls_obj : Node.Set.t) (obj : 'm Expression.t)
    (prop : string option) : string =
  let obj_name = object_name ls_obj obj in
  let prop_name = Option.value ~default:"*" prop in
  match String.split_on_char '=' obj_name with
  | [ obj_name' ] -> Fmt.str "%s.%s" obj_name' prop_name
  | [ _; obj_name' ] -> Fmt.str "%s.%s" obj_name' prop_name
  | _ -> Log.fail "unexpected object name' %S" obj_name

let object_lookup_name (left : 'm LeftValue.t) (ls_obj : Node.Set.t)
    (obj : 'm Expression.t) (prop : string option) : string =
  let left_name = LeftValue.name left in
  let obj_prop_name = object_property_name ls_obj obj prop in
  Fmt.str "%s=%s" left_name obj_prop_name

let lookup_property (state : State.t) (ls_obj : Node.Set.t)
    (prop' : string option) : Node.Set.t =
  let lookup_f = Fun.flip (Mdg.object_lookup_property state.mdg) prop' in
  Node.Set.map_flat lookup_f ls_obj

let available_functions (state : State.t) (ls_funcs : Node.Set.t) : func list =
  let available_function_f l_func acc =
    match Node.kind l_func with
    | Function _ -> Func (l_func, Mdg.get_parameters state.mdg l_func) :: acc
    | TaintSink _ ->
      Mdg.add_node state.mdg l_func;
      Sink l_func :: acc
    | _ -> acc in
  Node.Set.fold available_function_f ls_funcs []

let update_scope (state : State.t) (left : 'm LeftValue.t) (nodes : Node.Set.t)
    : unit =
  match LeftValue.kind left with
  | None -> Store.update state.store (LeftValue.name left) nodes
  | Var | Let | Const -> Store.replace state.store (LeftValue.name left) nodes

let add_tainted_sink (make_sink_f : 'a -> Tainted.sink) (state : State.t)
    (generic_sink : 'a) : unit =
  let sink = make_sink_f generic_sink in
  let sink_name = Tainted.(name !sink) in
  let sink_node = Node.create_sink sink in
  Store.set state.store sink_name sink_node

let add_static_orig_object_property (state : State.t) (cid : cid)
    (name : string) (ls_obj : Node.Set.t) (prop : string option) : unit =
  Fun.flip Node.Set.iter ls_obj @@ fun l_obj ->
  let ls_orig = Mdg.object_orig_versions state.mdg l_obj in
  Fun.flip Node.Set.iter ls_orig @@ fun l_orig ->
  if not (Mdg.has_property state.mdg l_orig prop) then
    let l_node = State.add_object_node state cid name in
    State.add_property_edge state l_orig l_node prop

let add_dynamic_orig_object_property (state : State.t) (cid : cid)
    (name : string) (ls_obj : Node.Set.t) (ls_prop : Node.Set.t) : unit =
  Fun.flip Node.Set.iter ls_obj @@ fun l_obj ->
  let ls_orig = Mdg.object_orig_versions state.mdg l_obj in
  Fun.flip Node.Set.iter ls_orig @@ fun l_orig ->
  match Mdg.get_property state.mdg l_orig None with
  | Some l_node ->
    Node.Set.iter (Fun.flip (State.add_dependency_edge state) l_node) ls_prop
  | None ->
    let l_node = State.add_object_node state cid name in
    State.add_property_edge state l_orig l_node None;
    Node.Set.iter (Fun.flip (State.add_dependency_edge state) l_node) ls_prop

let static_nv_strong_update (state : State.t) (cid : cid) (name : string)
    (l_obj : Node.t) (prop : string option) : Node.Set.t =
  let l_node = State.add_object_node state cid name in
  State.add_version_edge state l_obj l_node prop;
  Store.strong_update state.store l_obj l_node;
  Node.Set.singleton l_node

let static_nv_weak_update (state : State.t) (cid : cid) (name : string)
    (ls_obj : Node.Set.t) (prop : string option) : Node.Set.t =
  let l_node = State.add_object_node state cid name in
  ( Fun.flip Node.Set.iter ls_obj @@ fun l_obj ->
    let new' = Node.Set.of_list [ l_obj; l_node ] in
    State.add_version_edge state l_obj l_node prop;
    Store.weak_update state.store l_obj new' );
  let ls_nodes = Node.Set.singleton l_node in
  Store.update state.store name ls_nodes;
  ls_nodes

let dynamic_nv_strong_update (state : State.t) (cid : cid) (name : string)
    (l_obj : Node.t) (ls_prop : Node.Set.t) : Node.Set.t =
  let l_node = State.add_object_node state cid name in
  State.add_version_edge state l_obj l_node None;
  Node.Set.iter (Fun.flip (State.add_dependency_edge state) l_node) ls_prop;
  Store.strong_update state.store l_obj l_node;
  Node.Set.singleton l_node

let dynamic_nv_weak_update (state : State.t) (cid : cid) (name : string)
    (ls_obj : Node.Set.t) (ls_prop : Node.Set.t) : Node.Set.t =
  let l_node = State.add_object_node state cid name in
  ( Fun.flip Node.Set.iter ls_obj @@ fun l_obj ->
    let new' = Node.Set.of_list [ l_obj; l_node ] in
    State.add_version_edge state l_obj l_node None;
    Store.weak_update state.store l_obj new' );
  Node.Set.iter (Fun.flip (State.add_dependency_edge state) l_node) ls_prop;
  let ls_nodes = Node.Set.singleton l_node in
  Store.update state.store name ls_nodes;
  ls_nodes

let add_static_object_version (state : State.t) (cid : cid) (name : string)
    (ls_obj : Node.Set.t) (prop : string option) : Node.Set.t =
  let get_obj_f = Node.Set.choose in
  match Node.Set.cardinal ls_obj with
  | 0 -> Node.Set.empty
  | 1 -> static_nv_strong_update state cid name (get_obj_f ls_obj) prop
  | _ -> static_nv_weak_update state cid name ls_obj prop

let add_dynamic_object_version (state : State.t) (cid : cid) (name : string)
    (ls_obj : Node.Set.t) (ls_prop : Node.Set.t) : Node.Set.t =
  let get_obj_f = Node.Set.choose in
  match Node.Set.cardinal ls_obj with
  | 0 -> Node.Set.empty
  | 1 -> dynamic_nv_strong_update state cid name (get_obj_f ls_obj) ls_prop
  | _ -> dynamic_nv_weak_update state cid name ls_obj ls_prop

let add_function_caller (state : State.t) (call_cid : cid) (retn_cid : cid)
    (call_name : string) (retn_name : string) (ls_args : Node.Set.t list) :
    Node.t * Node.t =
  let l_call = State.add_call_node state call_cid call_name in
  let l_retn = State.add_return_node state retn_cid retn_name in
  State.add_return_edge state l_call l_retn;
  ( Fun.flip List.iteri ls_args @@ fun idx ls_arg ->
    let idx' = idx + 1 in
    Node.Set.iter (Fun.flip (State.add_argument_edge state idx') l_call) ls_arg
  );
  (l_call, l_retn)

let rec add_argument_connections (state : State.t) (l_params : Node.t list)
    (ls_args : Node.Set.t list) : unit =
  match (l_params, ls_args) with
  | (l_param :: l_params', ls_arg :: ls_args') ->
    Node.Set.iter (State.add_ref_argument_edge state l_param) ls_arg;
    add_argument_connections state l_params' ls_args'
  | _ -> ()

let add_call_connections (state : State.t) (l_call : Node.t)
    (ls_args : Node.Set.t list) (funcs : func list) : unit =
  Fun.flip List.iter funcs @@ function
  | Func (l_func, l_params) ->
    State.add_call_edge state l_call l_func;
    add_argument_connections state l_params ls_args
  | Sink l_sink ->
    State.add_call_edge state l_call l_sink;
    let l_params = List.map (fun _ -> l_sink) ls_args in
    add_argument_connections state l_params ls_args

let rec eval_expr (state : State.t) (expr : 'm Expression.t) : Node.Set.t =
  let exprs_f acc expr = Node.Set.union acc (eval_expr state expr) in
  match expr.el with
  | `Literal _ -> Node.Set.singleton state.literal
  | `TemplateLiteral { exprs; _ } -> List.fold_left exprs_f Node.Set.empty exprs
  | `Identifier id -> Store.retrieve state.store (Identifier.name' id)
  | `This _ -> Log.fail "TODO: Implement the this"

let rec initialize_state (tconf : Taint_config.t) (stmts : 'm Statement.t list)
    : State.t =
  let state = State.create () in
  Mdg.add_node state.mdg state.literal;
  initialize_tainted_sinks state tconf;
  initialize_hoisted_functions state stmts

and initialize_tainted_sinks (state : State.t) (tconf : Taint_config.t) : unit =
  let make_fun_sink_f sink = `FunctionSink sink in
  let make_new_sink_f sink = `NewSink sink in
  List.iter (add_tainted_sink make_fun_sink_f state) tconf.function_sinks;
  List.iter (add_tainted_sink make_new_sink_f state) tconf.new_sinks

and initialize_hoisted_functions (state : State.t) (stmts : 'm Statement.t list)
    : State.t =
  List.fold_left initialize_hoisted_function state stmts

and initialize_hoisted_function (state : State.t) (stmt : 'm Statement.t) :
    State.t =
  match stmt.el with
  | `AssignFunctionDefinition fundef when fundef.hoisted ->
    build_assign_function_definition state fundef.left fundef.params fundef.body
      (cid stmt)
  | _ -> state

and build_assign_simple (state : State.t) (left : 'm LeftValue.t)
    (right : 'm Expression.t) : State.t =
  let ls_right = eval_expr state right in
  update_scope state left ls_right;
  state

and build_assign_new (state : State.t) (left : 'm LeftValue.t) (cid : cid) :
    State.t =
  let l_node = State.add_object_node state cid (LeftValue.name left) in
  update_scope state left (Node.Set.singleton l_node);
  state

and build_assign_unopt (state : State.t) (left : 'm LeftValue.t)
    (arg : 'm Expression.t) (cid : cid) : State.t =
  let ls_arg = eval_expr state arg in
  let l_node = State.add_object_node state cid (LeftValue.name left) in
  update_scope state left (Node.Set.singleton l_node);
  Node.Set.iter (Fun.flip (State.add_dependency_edge state) l_node) ls_arg;
  state

and build_assign_binopt (state : State.t) (left : 'm LeftValue.t)
    (arg1 : 'm Expression.t) (arg2 : 'm Expression.t) (cid : cid) : State.t =
  let ls_arg1 = eval_expr state arg1 in
  let ls_arg2 = eval_expr state arg2 in
  let l_node = State.add_object_node state cid (LeftValue.name left) in
  update_scope state left (Node.Set.singleton l_node);
  Node.Set.iter (Fun.flip (State.add_dependency_edge state) l_node) ls_arg1;
  Node.Set.iter (Fun.flip (State.add_dependency_edge state) l_node) ls_arg2;
  state

and build_assign_yield (state : State.t) (_left : 'm LeftValue.t)
    (_arg : 'm Expression.t option) (_delegate : bool) (_cid : cid) : State.t =
  (* TODO: implement the yield construct *)
  (* similar to the return, but does not stop the analysis of the remainder of the body *)
  (* uses the left as something similar to a function parameter (taintness) *)
  state

and build_static_lookup (state : State.t) (left : 'm LeftValue.t)
    (obj : 'm Expression.t) (prop : 'm Prop.t) (cid : cid) : State.t =
  let ls_obj = eval_expr state obj in
  let prop' = Some (Prop.name prop) in
  let name = object_lookup_name left ls_obj obj prop' in
  (* TODO: add a flag to only create property on orig when needed *)
  add_static_orig_object_property state cid name ls_obj prop';
  let ls_fields = lookup_property state ls_obj prop' in
  update_scope state left ls_fields;
  state

and build_dynamic_lookup (state : State.t) (left : 'm LeftValue.t)
    (obj : 'm Expression.t) (prop : 'm Expression.t) (cid : cid) : State.t =
  let ls_obj = eval_expr state obj in
  let ls_prop = eval_expr state prop in
  let name = object_lookup_name left ls_obj obj None in
  (* TODO: check what to do with dynamic properties, and where to add them *)
  add_dynamic_orig_object_property state cid name ls_obj ls_prop;
  let ls_fields = lookup_property state ls_obj None in
  update_scope state left ls_fields;
  state

and build_static_update (state : State.t) (obj : 'm Expression.t)
    (prop : 'm Prop.t) (right : 'm Expression.t) (cid : cid) : State.t =
  (* FIXME: resolve the issue of assigning a value to a literal property *)
  let ls_obj = eval_expr state obj in
  let ls_right = eval_expr state right in
  let prop' = Some (Prop.name prop) in
  let name = object_name ls_obj obj in
  let ls_new = add_static_object_version state cid name ls_obj prop' in
  ( Fun.flip Node.Set.iter ls_new @@ fun l_new ->
    Fun.flip Node.Set.iter ls_right @@ fun l_right ->
    State.add_property_edge state l_new l_right prop' );
  state

and build_dynamic_update (state : State.t) (obj : 'm Expression.t)
    (prop : 'm Expression.t) (right : 'm Expression.t) (cid : cid) : State.t =
  (* FIXME: resolve the issue of assigning a value to a literal property *)
  let ls_obj = eval_expr state obj in
  let ls_prop = eval_expr state prop in
  let ls_right = eval_expr state right in
  let name = object_name ls_obj obj in
  let ls_new = add_dynamic_object_version state cid name ls_obj ls_prop in
  ( Fun.flip Node.Set.iter ls_new @@ fun l_new ->
    Fun.flip Node.Set.iter ls_right @@ fun l_right ->
    State.add_property_edge state l_new l_right None );
  state

and build_static_delete (state : State.t) (_left : 'm LeftValue.t)
    (_obj : 'm Expression.t) (_prop : 'm Prop.t) (_cid : cid) : State.t =
  (* TODO: implement the static delete construct *)
  (* we treat static property deletes as assigning undefined to the static property *)
  state

and build_dynamic_delete (state : State.t) (_left : 'm LeftValue.t)
    (_obj : 'm Expression.t) (_prop : 'm Expression.t) (_cid : cid) : State.t =
  (* TODO: implement the dynamic delete construct *)
  (* we treat dynamic property deletes as assigning undefined to the dynamic property *)
  state

and build_function_call (state : State.t) (left : 'm LeftValue.t)
    (callee : 'm Identifier.t) (args : 'm Expression.t list) (cid0 : cid) :
    State.t =
  (* TODO: handle dynamic function calls (callee evaluates to the literal object) *)
  let (call, retn) = (Identifier.name callee, LeftValue.name left) in
  let ls_funcs = Store.retrieve state.store call in
  let funcs = available_functions state ls_funcs in
  let ls_args = List.map (eval_expr state) args in
  let cid1 = offset cid0 1 in
  let (l_call, l_retn) = add_function_caller state cid0 cid1 call retn ls_args in
  add_call_connections state l_call ls_args funcs;
  update_scope state left (Node.Set.singleton l_retn);
  state

and build_static_method_call (state : State.t) (left : 'm LeftValue.t)
    (obj : 'm Expression.t) (prop : 'm Prop.t) (args : 'm Expression.t list)
    (cid0 : cid) : State.t =
  let ls_obj = eval_expr state obj in
  let ls_args = List.map (eval_expr state) args in
  let prop' = Some (Prop.str prop) in
  let call = object_property_name ls_obj obj prop' in
  let retn = object_lookup_name left ls_obj obj prop' in
  (* TODO: add a flag to only create property on orig when needed *)
  add_static_orig_object_property state cid0 call ls_obj prop';
  let ls_mthds = lookup_property state ls_obj prop' in
  let mthds = available_functions state ls_mthds in
  let cid1 = offset cid0 1 in
  let cid2 = offset cid0 2 in
  let (l_call, l_retn) = add_function_caller state cid1 cid2 call retn ls_args in
  add_call_connections state l_call ls_args mthds;
  (* TODO: properly set the this binding *)
  update_scope state left (Node.Set.singleton l_retn);
  state

and build_dynamic_method_call (state : State.t) (left : 'm LeftValue.t)
    (obj : 'm Expression.t) (prop : 'm Expression.t)
    (args : 'm Expression.t list) (cid0 : cid) : State.t =
  let ls_obj = eval_expr state obj in
  let ls_prop = eval_expr state prop in
  let ls_args = List.map (eval_expr state) args in
  let call = object_property_name ls_obj obj None in
  let retn = object_lookup_name left ls_obj obj None in
  (* TODO: check what to do with dynamic properties, and where to add them *)
  add_dynamic_orig_object_property state cid0 call ls_obj ls_prop;
  let ls_mthds = lookup_property state ls_obj None in
  let mthds = available_functions state ls_mthds in
  let cid1 = offset cid0 1 in
  let cid2 = offset cid0 2 in
  let (l_call, l_retn) = add_function_caller state cid1 cid2 call retn ls_args in
  add_call_connections state l_call ls_args mthds;
  (* TODO: properly set the this binding *)
  update_scope state left (Node.Set.singleton l_retn);
  state

and build_if (state : State.t) (consequent : 'm Statement.t list)
    (alternate : 'm Statement.t list option) : State.t =
  match alternate with
  | None -> build_sequence state consequent
  | Some alternate' ->
    let state_altr = State.copy state in
    let state' = build_sequence state consequent in
    let state_altr' = build_sequence state_altr alternate' in
    State.lub state' state_altr'

and build_switch (state : State.t) (cases : 'm SwitchCase.t list) : State.t =
  (* TODO: implement flow control to the builder *)
  (* this statement can be improved by reasoning about the control flow of the break and return statements *)
  (* additionally, we should account for the initial states of the switch not being processed *)
  List.map SwitchCase.body cases |> List.fold_left build_sequence state

and build_loop (state : State.t) (body : 'm Statement.t list) : State.t =
  (* TODO: handle the assignment in the forin and forof statement *)
  (* we treat this assignment as a lookup on all properties of the expression *)
  let store' = Store.copy state.store in
  let state' = build_sequence state body in
  Store.lub state'.store store';
  if Store.equal state'.store store' then state' else build_loop state' body

and build_assign_function_definition (state : State.t) (left : 'm LeftValue.t)
    (params : 'm Identifier.t list) (body : 'm Statement.t list) (cid : cid) :
    State.t =
  let func_name = LeftValue.name left in
  let l_func = State.add_function_node state cid func_name in
  Store.set state.store func_name l_func;
  let store' = Store.extend state.store in
  let state' = { state with store = store'; curr_func = Some l_func } in
  ( Fun.flip List.iteri params @@ fun idx param ->
    let idx' = idx + 1 in
    let cid' = offset cid idx' in
    let param_name = Identifier.name param in
    let l_param = State.add_parameter_node state' cid' idx' param_name in
    State.add_parameter_edge state' idx' l_func l_param;
    Store.set state'.store param_name l_param );
  let _state'' = build_sequence state' body in
  (* TODO: store the context difference generated by the function body in the environment *)
  (* this context should be used when calling the function to modify the current context accordingly *)
  state

and build_loop_break (state : State.t) (_label : 'm Identifier.t option) :
    State.t =
  (* TODO: implement flow control to the builder *)
  (* TODO: implement labels on the loop breaks *)
  state

and build_try (state : State.t) (body : 'm Statement.t list)
    (handler : 'm Catch.t option) (finalizer : 'm Statement.t list option) :
    State.t =
  (* TODO: implement the try construct *)
  (* the catch body should only be analysed if an exception is thrown *)
  let handler' = Option.map Catch.body handler in
  let state' = build_sequence state body in
  let state'' = build_sequence_opt state' handler' in
  let state''' = build_sequence_opt state'' finalizer in
  state'''

and build_with (state : State.t) (_expr : 'm Expression.t)
    (body : 'm Statement.t list) : State.t =
  (* TODO: implement the with construct *)
  (* extend the current scope with the statement's expression *)
  build_sequence state body

and build_labeled (state : State.t) (_label : 'm Identifier.t)
    (body : 'm Statement.t list) : State.t =
  (* TODO: implement the labeled construct *)
  (* store the labels in the environment, and then use them in the break and continue statements *)
  build_sequence state body

and build_return (state : State.t) (arg : 'm Expression.t option) : State.t =
  (* TODO: implement flow control to the builder *)
  (* the return statement should prevent all code afterwards from being analysed *)
  let ls_arg = Option.map (eval_expr state) arg in
  match (state.curr_func, ls_arg) with
  | (None, _) | (Some _, None) -> state
  | (Some l_func, Some ls_arg') ->
    Node.Set.iter (State.add_ref_return_edge state l_func) ls_arg';
    state

and build_throw (state : State.t) (_arg : 'm Expression.t) : State.t =
  (* TODO: implement the throw construct *)
  (* similar to the return, but set a flag in the environment that tells that an exception may have been thrown *)
  state

and build_statement (state : State.t) (stmt : 'm Statement.t) : State.t =
  match stmt.el with
  | `AssignSimple { left; right } -> build_assign_simple state left right
  | `AssignNewObject { left } | `AssignNewArray { left } ->
    build_assign_new state left (cid stmt)
  | `AssignUnopt { left; arg; _ } ->
    build_assign_unopt state left arg (cid stmt)
  | `AssignBinopt { left; arg1; arg2; _ } ->
    build_assign_binopt state left arg1 arg2 (cid stmt)
  | `AssignYield { left; arg; delegate } ->
    build_assign_yield state left arg delegate (cid stmt)
  | `StaticLookup { left; obj; prop } ->
    build_static_lookup state left obj prop (cid stmt)
  | `DynamicLookup { left; obj; prop } ->
    build_dynamic_lookup state left obj prop (cid stmt)
  | `StaticUpdate { obj; prop; right } ->
    build_static_update state obj prop right (cid stmt)
  | `DynamicUpdate { obj; prop; right } ->
    build_dynamic_update state obj prop right (cid stmt)
  | `StaticDelete { left; obj; prop } ->
    build_static_delete state left obj prop (cid stmt)
  | `DynamicDelete { left; obj; prop } ->
    build_dynamic_delete state left obj prop (cid stmt)
  | `AssignNewCall { left; callee; args }
  | `AssignFunctionCall { left; callee; args } ->
    build_function_call state left callee args (cid stmt)
  | `AssignStaticMethodCall { left; obj; prop; args } ->
    build_static_method_call state left obj prop args (cid stmt)
  | `AssignDynamicMethodCall { left; obj; prop; args } ->
    build_dynamic_method_call state left obj prop args (cid stmt)
  (* hoisted functions are handled during scope initialization *)
  | `AssignFunctionDefinition { hoisted; _ } when hoisted -> state
  | `AssignFunctionDefinition { left; params; body; _ } ->
    build_assign_function_definition state left params body (cid stmt)
  | `If { consequent; alternate; _ } -> build_if state consequent alternate
  | `Switch { cases; _ } -> build_switch state cases
  | `While { body; _ } | `ForIn { body; _ } | `ForOf { body; _ } ->
    build_loop state body
  | `Break { label } | `Continue { label } -> build_loop_break state label
  | `Return { arg } -> build_return state arg
  | `Throw { arg } -> build_throw state arg
  | `Try { body; handler; finalizer } -> build_try state body handler finalizer
  | `With { expr; body } -> build_with state expr body
  | `Labeled { label; body } -> build_labeled state label body
  | `VarDecl _ | `ExprStmt _ | `AssignDynamicImport _ | `Debugger _
  | `ImportDecl _ | `ExportDecl _ ->
    state

and build_sequence (state : State.t) (stmts : 'm Statement.t list) : State.t =
  List.fold_left build_statement state stmts

and build_sequence_opt (state : State.t) (stmts : 'm Statement.t list option) :
    State.t =
  Option.fold ~none:state ~some:(build_sequence state) stmts

let build_file (conf : Taint_config.t) (file : 'm File.t) : Mdg.t =
  let state' = initialize_state conf file in
  let state'' = build_sequence state' file in
  state''.mdg
