open Graphjs_base
open Graphjs_shared
open Graphjs_ast
open Metadata

type cid = State.CodeCache.id

let cid : 'm Statement.t -> cid = State.CodeCache.cid
let offset : cid -> int -> cid = State.CodeCache.offset

let object_name (ls_obj : Node.Set.t) (obj : 'm Expression.t) : string =
  (* TODO[flag]: disable composite object names *)
  if Node.Set.cardinal ls_obj == 1 then
    try Node.name (Node.Set.choose ls_obj) with _ -> Expression.str obj
  else Expression.str obj

let object_property_name (ls_obj : Node.Set.t) (obj : 'm Expression.t)
    (prop : string option) : string =
  let obj_name = object_name ls_obj obj in
  let prop_name = Option.value ~default:"*" prop in
  match String.split_on_char '=' obj_name with
  | [ obj_name' ] -> Fmt.str "%s.%s" obj_name' prop_name
  | [ _; obj_name' ] -> Fmt.str "%s.%s" obj_name' prop_name
  | _ -> Log.fail "unexpected object name' %S" obj_name

let lookup_property (state : State.t) (ls_obj : Node.Set.t)
    (prop' : string option) : Node.Set.t =
  let lookup_f = Fun.flip (Mdg.object_lookup_property state.mdg) prop' in
  Node.Set.map_flat lookup_f ls_obj

let update_property_wrapper (state : State.t) (cid : cid)
    (ls_right : Node.Set.t) (right : 'm Expression.t) : Node.Set.t =
  (* this function prevents new versions from being created from the literal object *)
  if Builder_config.(!wrap_literal_property_updates) then
    Fun.flip2 Node.Set.fold ls_right Node.Set.empty @@ fun node acc ->
    match node.kind with
    | Literal ->
      let cid' = offset cid (Node.Set.cardinal acc + 1) in
      let l_wrapper = State.add_literal_node state cid' (Expression.str right) in
      State.add_dependency_edge state node l_wrapper;
      Node.Set.add l_wrapper acc
    | _ -> Node.Set.add node acc
  else ls_right

let known_functions (state : State.t) (ls_funcs : Node.Set.t) : Node.t list =
  Fun.flip2 Node.Set.fold ls_funcs [] @@ fun l_func acc ->
  match Node.kind l_func with
  | Function _ -> l_func :: acc
  | TaintSink _ ->
    Mdg.add_node state.mdg l_func;
    l_func :: acc
  | _ -> acc

let update_scope (state : State.t) (left : 'm LeftValue.t) (nodes : Node.Set.t)
    : unit =
  match LeftValue.kind left with
  | None -> Store.replace state.store (LeftValue.name left) nodes
  | Var | Let | Const -> Store.replace state.store (LeftValue.name left) nodes

let add_tainted_sink (make_generic_sink_f : 'a -> Tainted.sink)
    (state : State.t) (generic_sink : 'a) : unit =
  let sink = make_generic_sink_f generic_sink in
  let sink_name = Tainted.(name !sink) in
  let sink_node = Node.create_sink sink in
  Store.replace state.store sink_name (Node.Set.singleton sink_node)

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
  Store.replace state.store name ls_nodes;
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
  Store.replace state.store name ls_nodes;
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

let add_caller (state : State.t) (call_cid : cid) (retn_cid : cid)
    (call_name : string) (retn_name : string) (ls_this : Node.Set.t option)
    (ls_args : Node.Set.t list) : Node.t * Node.t =
  let add_arg_f = Fun.flip2 (State.add_argument_edge state) in
  let l_call = State.add_call_node state call_cid call_name in
  let l_retn = State.add_return_node state retn_cid retn_name in
  State.add_return_edge state l_call l_retn;
  Option.iter (Node.Set.iter (add_arg_f l_call 0)) ls_this;
  ( Fun.flip List.iteri ls_args @@ fun idx ls_arg ->
    let idx' = idx + 1 in
    Node.Set.iter (add_arg_f l_call idx') ls_arg );
  (l_call, l_retn)

let rec add_call_connections (state : State.t) (l_funcs : Node.t list)
    (l_call : Node.t) (l_this : Node.Set.t option) (ls_args : Node.Set.t list) :
    unit =
  let ls_args' = l_this :: List.map Option.some ls_args in
  Fun.flip List.iter l_funcs @@ fun l_func ->
  match Node.kind l_func with
  | Function _ ->
    let l_params = Mdg.get_parameters state.mdg l_func in
    State.add_call_edge state l_call l_func;
    add_argument_connections state l_params ls_args'
  | TaintSink _ ->
    let l_params = List.mapi (fun idx _ -> (idx, l_func)) ls_args' in
    State.add_call_edge state l_call l_func;
    add_argument_connections state l_params ls_args'
  | _ -> ()

and add_argument_connections (state : State.t) (l_params : (int * Node.t) list)
    (ls_args : Node.Set.t option list) : unit =
  Fun.flip List.iter l_params @@ fun (idx, l_param) ->
  match List.nth_opt ls_args idx with
  | Some (Some ls_arg) ->
    Node.Set.iter (State.add_ref_argument_edge state l_param) ls_arg
  | _ -> ()

let rec eval_expr (state : State.t) (expr : 'm Expression.t) : Node.Set.t =
  let exprs_f acc expr = Node.Set.union acc (eval_expr state expr) in
  match expr.el with
  | `Literal _ -> Node.Set.singleton state.literal_node
  | `TemplateLiteral { exprs; _ } -> List.fold_left exprs_f Node.Set.empty exprs
  | `Identifier id -> Store.find state.store (Identifier.name' id)
  | `This _ -> Store.find state.store "this"

let rec initialize_state (tconf : Taint_config.t) (stmts : 'm Statement.t list)
    : State.t =
  let state = State.create () in
  Mdg.add_node state.mdg state.literal_node;
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
  let name = object_property_name ls_obj obj prop' in
  add_static_orig_object_property state cid name ls_obj prop';
  let ls_fields = lookup_property state ls_obj prop' in
  update_scope state left ls_fields;
  state

and build_dynamic_lookup (state : State.t) (left : 'm LeftValue.t)
    (obj : 'm Expression.t) (prop : 'm Expression.t) (cid : cid) : State.t =
  let ls_obj = eval_expr state obj in
  let ls_prop = eval_expr state prop in
  let name = object_property_name ls_obj obj None in
  add_dynamic_orig_object_property state cid name ls_obj ls_prop;
  let ls_fields = lookup_property state ls_obj None in
  update_scope state left ls_fields;
  state

and build_static_update (state : State.t) (obj : 'm Expression.t)
    (prop : 'm Prop.t) (right : 'm Expression.t) (cid : cid) : State.t =
  let ls_obj = eval_expr state obj in
  let ls_right = eval_expr state right in
  let prop' = Some (Prop.name prop) in
  let ls_right' = update_property_wrapper state cid ls_right right in
  let name = object_name ls_obj obj in
  let ls_new = add_static_object_version state cid name ls_obj prop' in
  ( Fun.flip Node.Set.iter ls_new @@ fun l_new ->
    Fun.flip Node.Set.iter ls_right' @@ fun l_right ->
    State.add_property_edge state l_new l_right prop' );
  state

and build_dynamic_update (state : State.t) (obj : 'm Expression.t)
    (prop : 'm Expression.t) (right : 'm Expression.t) (cid : cid) : State.t =
  let ls_obj = eval_expr state obj in
  let ls_prop = eval_expr state prop in
  let ls_right = eval_expr state right in
  let name = object_name ls_obj obj in
  let ls_right' = update_property_wrapper state cid ls_right right in
  let ls_new = add_dynamic_object_version state cid name ls_obj ls_prop in
  ( Fun.flip Node.Set.iter ls_new @@ fun l_new ->
    Fun.flip Node.Set.iter ls_right' @@ fun l_right ->
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
  (* TODO: implement dynamic function calls by calling every function available in the scope *)
  (* the callee identifier evaluates to the literal object in dynamic function calls *)
  let call = Identifier.name callee in
  let retn = LeftValue.name left in
  let ls_funcs = Store.find state.store call in
  let l_funcs = known_functions state ls_funcs in
  let ls_this = None in
  let ls_args = List.map (eval_expr state) args in
  let cid1 = offset cid0 1 in
  let (l_call, l_retn) = add_caller state cid0 cid1 call retn ls_this ls_args in
  add_call_connections state l_funcs l_call ls_this ls_args;
  update_scope state left (Node.Set.singleton l_retn);
  state

and build_static_method_call (state : State.t) (left : 'm LeftValue.t)
    (obj : 'm Expression.t) (prop : 'm Prop.t) (args : 'm Expression.t list)
    (cid0 : cid) : State.t =
  let ls_obj = eval_expr state obj in
  let ls_this = Some ls_obj in
  let ls_args = List.map (eval_expr state) args in
  let prop' = Some (Prop.str prop) in
  let call = object_property_name ls_obj obj prop' in
  let retn = LeftValue.name left in
  add_static_orig_object_property state cid0 call ls_obj prop';
  let ls_mthds = lookup_property state ls_obj prop' in
  let mthds = known_functions state ls_mthds in
  let cid1 = offset cid0 1 in
  let cid2 = offset cid0 2 in
  let (l_call, l_retn) = add_caller state cid1 cid2 call retn ls_this ls_args in
  add_call_connections state mthds l_call ls_this ls_args;
  update_scope state left (Node.Set.singleton l_retn);
  state

and build_dynamic_method_call (state : State.t) (left : 'm LeftValue.t)
    (obj : 'm Expression.t) (prop : 'm Expression.t)
    (args : 'm Expression.t list) (cid0 : cid) : State.t =
  let ls_obj = eval_expr state obj in
  let ls_prop = eval_expr state prop in
  let ls_this = Some ls_obj in
  let ls_args = List.map (eval_expr state) args in
  let call = object_property_name ls_obj obj None in
  let retn = LeftValue.name left in
  add_dynamic_orig_object_property state cid0 call ls_obj ls_prop;
  let ls_mthds = lookup_property state ls_obj None in
  let mthds = known_functions state ls_mthds in
  let cid1 = offset cid0 1 in
  let cid2 = offset cid0 2 in
  let (l_call, l_retn) = add_caller state cid1 cid2 call retn ls_this ls_args in
  add_call_connections state mthds l_call ls_this ls_args;
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
  (* TODO: model the assignment in the forin and forof statement *)
  (* we treat this assignment as a lookup on all properties of the expression *)
  (* the left value should depend of all the properties of the right value *)
  let store' = Store.copy state.store in
  let state' = build_sequence state body in
  Store.lub state'.store store';
  if Store.equal state'.store store' then state' else build_loop state' body

and build_assign_function_definition (state : State.t) (left : 'm LeftValue.t)
    (params : 'm Identifier.t list) (body : 'm Statement.t list) (cid : cid) :
    State.t =
  let func_name = LeftValue.name left in
  let l_func = State.add_function_node state cid func_name in
  Store.replace state.store func_name (Node.Set.singleton l_func);
  let store' = Store.copy state.store in
  let state' = { state with store = store'; curr_func = Some l_func } in
  let cid' = offset cid (List.length params + 1) in
  let l_this = State.add_parameter_node state' cid' 0 "this" in
  State.add_parameter_edge state' l_func l_this 0;
  Store.replace state'.store "this" (Node.Set.singleton l_this);
  ( Fun.flip List.iteri params @@ fun idx param ->
    let idx' = idx + 1 in
    let cid' = offset cid idx' in
    let param_name = Identifier.name param in
    let l_param = State.add_parameter_node state' cid' idx' param_name in
    State.add_parameter_edge state' l_func l_param idx';
    Store.replace state'.store param_name (Node.Set.singleton l_param) );
  let _state'' = build_sequence state' body in
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
