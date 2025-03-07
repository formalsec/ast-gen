open Graphjs_base
open Graphjs_share
open Graphjs_ast
open Metadata

type cid = State.GraphRegistry.id

let cid (stmt : 'a Statement.t) : cid = State.GraphRegistry.cid stmt
let offset (cid : cid) (ofs : int) : cid = State.GraphRegistry.offset cid ofs

let object_name (ls_obj : Node.Set.t) (obj : 'm Expression.t) : string =
  if Node.Set.cardinal ls_obj == 1 then
    try Node.name (Node.Set.choose ls_obj) with _ -> Expression.str obj
  else Expression.str obj

let object_property_name (ls_obj : Node.Set.t) (obj : 'm Expression.t)
    (prop : Property.t) : string =
  let obj_name = object_name ls_obj obj in
  Fmt.str "%s.%a" obj_name Property.pp prop

let lookup_property (state : State.t) (ls_obj : Node.Set.t) (prop : Property.t)
    : Node.Set.t =
  let lookup_f = Fun.flip (Mdg.object_lookup state.mdg) prop in
  Node.Set.map_flat lookup_f ls_obj

let wrap_literal_properties (state : State.t) (right : 'm Expression.t)
    (ls_right : Node.Set.t) (cid : cid) : Node.Set.t =
  (* this function prevents new versions from being created from the literal object *)
  if not state.env.unsafe_literal_properties then
    Fun.flip2 Node.Set.fold ls_right Node.Set.empty (fun l_right acc ->
        if Node.is_literal l_right then (
          let name = Expression.str right in
          let cid' = offset cid (Node.Set.cardinal acc + 1) in
          let l_wrapper = State.add_literal_object_node state cid' name in
          State.add_dependency_edge state l_right l_wrapper;
          Node.Set.add l_wrapper acc )
        else Node.Set.add l_right acc )
  else ls_right

let add_static_orig_object_property (state : State.t) (name : string)
    (ls_obj : Node.Set.t) (prop : Property.t) (cid : cid) : unit =
  Fun.flip Node.Set.iter ls_obj (fun l_obj ->
      let ls_orig = Mdg.object_orig_versions state.mdg l_obj in
      Fun.flip Node.Set.iter ls_orig (fun l_orig ->
          if not (Mdg.has_property state.mdg l_orig prop) then
            let l_node = State.add_object_node state cid name in
            State.add_property_edge state l_orig l_node prop ) )

let add_dynamic_orig_object_property (state : State.t) (name : string)
    (ls_obj : Node.Set.t) (ls_prop : Node.Set.t) (cid : cid) : unit =
  let prop = Property.dynamic () in
  let set_deps_f l_node = Fun.flip (State.add_dependency_edge state) l_node in
  Fun.flip Node.Set.iter ls_obj (fun l_obj ->
      let ls_orig = Mdg.object_orig_versions state.mdg l_obj in
      Fun.flip Node.Set.iter ls_orig (fun l_orig ->
          match Mdg.get_property state.mdg l_orig prop with
          | [] ->
            let l_node = State.add_object_node state cid name in
            State.add_property_edge state l_orig l_node prop;
            Node.Set.iter (set_deps_f l_node) ls_prop
          | l_node :: _ -> Node.Set.iter (set_deps_f l_node) ls_prop ) )

let static_strong_nv (state : State.t) (name : string) (l_obj : Node.t)
    (prop : Property.t) (cid : cid) : Node.Set.t =
  let l_node = State.add_object_node state cid name in
  State.add_version_edge state l_obj l_node prop;
  Store.strong_update state.store l_obj l_node;
  Node.Set.singleton l_node

let static_weak_nv (state : State.t) (name : string) (ls_obj : Node.Set.t)
    (prop : Property.t) (cid : cid) : Node.Set.t =
  let l_node = State.add_object_node state cid name in
  Fun.flip Node.Set.iter ls_obj (fun l_obj ->
      let ls_new = Node.Set.of_list [ l_obj; l_node ] in
      State.add_version_edge state l_obj l_node prop;
      Store.weak_update state.store l_obj ls_new );
  let ls_node = Node.Set.singleton l_node in
  Store.replace state.store name ls_node;
  ls_node

let dynamic_strong_nv (state : State.t) (name : string) (l_obj : Node.t)
    (ls_prop : Node.Set.t) (cid : cid) : Node.Set.t =
  let l_node = State.add_object_node state cid name in
  State.add_version_edge state l_obj l_node None;
  Node.Set.iter (Fun.flip (State.add_dependency_edge state) l_node) ls_prop;
  Store.strong_update state.store l_obj l_node;
  Node.Set.singleton l_node

let dynamic_weak_nv (state : State.t) (name : string) (ls_obj : Node.Set.t)
    (ls_prop : Node.Set.t) (cid : cid) : Node.Set.t =
  let prop = Property.dynamic () in
  let l_node = State.add_object_node state cid name in
  Fun.flip Node.Set.iter ls_obj (fun l_obj ->
      let ls_new = Node.Set.of_list [ l_obj; l_node ] in
      State.add_version_edge state l_obj l_node prop;
      Store.weak_update state.store l_obj ls_new );
  Node.Set.iter (Fun.flip (State.add_dependency_edge state) l_node) ls_prop;
  let ls_node = Node.Set.singleton l_node in
  Store.replace state.store name ls_node;
  ls_node

let add_static_object_version (state : State.t) (name : string)
    (ls_obj : Node.Set.t) (prop : Property.t) (cid : cid) : Node.Set.t =
  match Node.Set.cardinal ls_obj with
  | 0 -> Node.Set.empty
  | 1 -> static_strong_nv state name (Node.Set.choose ls_obj) prop cid
  | _ -> static_weak_nv state name ls_obj prop cid

let add_dynamic_object_version (state : State.t) (name : string)
    (ls_obj : Node.Set.t) (ls_prop : Node.Set.t) (cid : cid) : Node.Set.t =
  match Node.Set.cardinal ls_obj with
  | 0 -> Node.Set.empty
  | 1 -> dynamic_strong_nv state name (Node.Set.choose ls_obj) ls_prop cid
  | _ -> dynamic_weak_nv state name ls_obj ls_prop cid

let add_function_call (state : State.t) (name_call : string)
    (name_retn : string) (ls_func : Node.Set.t) (ls_args : Node.Set.t list)
    (cid_call : cid) (cid_retn : cid) : State.t * Node.t * Node.t =
  let l_call = State.add_call_node state cid_call name_call in
  let l_retn = State.add_return_node state cid_retn name_retn in
  let state' = { state with mdg = Mdg.add_call state.mdg l_call } in
  let add_arg_f = Fun.flip2 (State.add_argument_edge state) l_call in
  Fun.flip Node.Set.iter ls_func (fun l_func ->
      State.add_caller_edge state l_call l_func );
  State.add_dependency_edge state l_call l_retn;
  Fun.flip List.iteri ls_args (fun idx ls_arg ->
      Node.Set.iter (add_arg_f idx) ls_arg );
  (state', l_call, l_retn)

let call_interceptor (state : State.t) (ls_func : Node.Set.t) (l_call : Node.t)
    (l_retn : Node.t) (ls_args : Node.Set.t list) (args : 'm Expression.t list)
    (cid : cid) : State.t =
  Fun.flip2 Node.Set.fold ls_func state (fun l_func state' ->
      match State.has_call_interceptor state' l_func with
      | None -> state'
      | Some interceptor_f ->
        interceptor_f state' l_func l_call l_retn ls_args args cid )

let rec eval_expr (state : State.t) (expr : 'm Expression.t) : Node.Set.t =
  let exprs_f acc expr = Node.Set.union acc (eval_expr state expr) in
  match expr.el with
  | `Literal _ -> eval_literal_expr state
  | `TemplateLiteral { exprs; _ } -> List.fold_left exprs_f Node.Set.empty exprs
  | `Identifier id -> eval_store_expr state (Identifier.name' id)
  | `This _ -> eval_store_expr state "this"

and eval_literal_expr (state : State.t) : Node.Set.t =
  Node.Set.singleton state.mdg.literal

and eval_store_expr (state : State.t) (id : string) : Node.Set.t =
  let nodes = Store.find state.store id in
  Fun.flip Node.Set.map nodes (fun node ->
      if Node.is_invalid node then State.concretize_node state id node else node )

let initialize_builder ?(env = State.Env.default ())
    (taint_config : Taint_config.t) : State.t =
  Node.reset_generators ();
  let state = State.create env in
  Mdg.add_node state.mdg state.mdg.literal;
  Jslib.initialize_builder state taint_config

let rec initialize_state (state : State.t) (stmts : 'm Statement.t list) :
    State.t =
  let state' = State.prepare state in
  let state'' = Jslib.initialize_state state' in
  initialize_hoisted_functions state'' stmts

and initialize_hoisted_functions (state : State.t) (stmts : 'm Statement.t list)
    : State.t =
  Fun.flip2 List.fold_left state stmts (fun state stmt ->
      match stmt.el with
      | `FunctionDefinition func when FunctionDefinition.is_hoisted func ->
        build_function_declaration state func.left func.params (cid stmt)
      | _ -> state )

and build_assignment (state : State.t) (left : 'm LeftValue.t)
    (right : 'm Expression.t) : State.t =
  let name = LeftValue.name left in
  let ls_right = eval_expr state right in
  Store.replace state.store name ls_right;
  state

and build_new (state : State.t) (left : 'm LeftValue.t) (cid : cid) : State.t =
  let name = LeftValue.name left in
  let l_node = State.add_object_node state cid name in
  Store.replace state.store name (Node.Set.singleton l_node);
  state

and build_unopt (state : State.t) (left : 'm LeftValue.t)
    (arg : 'm Expression.t) (cid : cid) : State.t =
  let name = LeftValue.name left in
  let ls_arg = eval_expr state arg in
  let l_node = State.add_object_node state cid name in
  Store.replace state.store name (Node.Set.singleton l_node);
  Node.Set.iter (Fun.flip (State.add_dependency_edge state) l_node) ls_arg;
  state

and build_binopt (state : State.t) (left : 'm LeftValue.t)
    (arg1 : 'm Expression.t) (arg2 : 'm Expression.t) (cid : cid) : State.t =
  let name = LeftValue.name left in
  let ls_arg1 = eval_expr state arg1 in
  let ls_arg2 = eval_expr state arg2 in
  let l_node = State.add_object_node state cid name in
  Store.replace state.store name (Node.Set.singleton l_node);
  Node.Set.iter (Fun.flip (State.add_dependency_edge state) l_node) ls_arg1;
  Node.Set.iter (Fun.flip (State.add_dependency_edge state) l_node) ls_arg2;
  state

and build_yield (state : State.t) (_left : 'm LeftValue.t)
    (_arg : 'm Expression.t option) (_delegate : bool) (_cid : cid) : State.t =
  (* TODO: implement the yield construct *)
  (* similar to the return, but does not stop the analysis of the remainder of the body *)
  (* the left value should also be consider a function parameter going forward *)
  state

and build_static_lookup (state : State.t) (left : 'm LeftValue.t)
    (obj : 'm Expression.t) (prop : 'm Prop.t) (cid : cid) : State.t =
  let name = LeftValue.name left in
  let prop' = Property.static (Prop.name prop) in
  let ls_obj = eval_expr state obj in
  let field_name = object_property_name ls_obj obj prop' in
  add_static_orig_object_property state field_name ls_obj prop' cid;
  let ls_lookup = lookup_property state ls_obj prop' in
  Store.replace state.store name ls_lookup;
  state

and build_dynamic_lookup (state : State.t) (left : 'm LeftValue.t)
    (obj : 'm Expression.t) (prop : 'm Expression.t) (cid : cid) : State.t =
  let name = LeftValue.name left in
  let prop' = Property.dynamic () in
  let ls_obj = eval_expr state obj in
  let ls_prop = eval_expr state prop in
  let field_name = object_property_name ls_obj obj prop' in
  add_dynamic_orig_object_property state field_name ls_obj ls_prop cid;
  let ls_lookup = lookup_property state ls_obj prop' in
  Store.replace state.store name ls_lookup;
  state

and build_static_update (state : State.t) (obj : 'm Expression.t)
    (prop : 'm Prop.t) (right : 'm Expression.t) (cid : cid) : State.t =
  let prop' = Property.static (Prop.name prop) in
  let ls_obj = eval_expr state obj in
  let ls_right = eval_expr state right in
  let ls_right' = wrap_literal_properties state right ls_right cid in
  let object_name = object_name ls_obj obj in
  let ls_new = add_static_object_version state object_name ls_obj prop' cid in
  Fun.flip Node.Set.iter ls_new (fun l_new ->
      Fun.flip Node.Set.iter ls_right' (fun l_right ->
          State.add_property_edge state l_new l_right prop' ) );
  state

and build_dynamic_update (state : State.t) (obj : 'm Expression.t)
    (prop : 'm Expression.t) (right : 'm Expression.t) (cid : cid) : State.t =
  let prop' = Property.dynamic () in
  let ls_obj = eval_expr state obj in
  let ls_prop = eval_expr state prop in
  let ls_right = eval_expr state right in
  let ls_right' = wrap_literal_properties state right ls_right cid in
  let object_name = object_name ls_obj obj in
  let ls_new = add_dynamic_object_version state object_name ls_obj ls_prop cid in
  Fun.flip Node.Set.iter ls_new (fun l_new ->
      Fun.flip Node.Set.iter ls_right' (fun l_right ->
          State.add_property_edge state l_new l_right prop' ) );
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
    (callee : 'm Identifier.t) (args : 'm Expression.t list) (cid : cid) :
    State.t =
  let name_call = Identifier.name callee in
  let name_retn = LeftValue.name left in
  let ls_func = eval_store_expr state name_call in
  let ls_args = List.map (eval_expr state) args in
  let ls_args' = Node.Set.empty :: ls_args in
  let cid1 = offset cid 1 in
  let cid2 = offset cid 2 in
  let (state', l_call, l_retn) =
    add_function_call state name_call name_retn ls_func ls_args' cid cid1 in
  Store.replace state'.store name_retn (Node.Set.singleton l_retn);
  call_interceptor state' ls_func l_call l_retn ls_args args cid2

and build_static_method_call (state : State.t) (left : 'm LeftValue.t)
    (obj : 'm Expression.t) (prop : 'm Prop.t) (args : 'm Expression.t list)
    (cid : cid) : State.t =
  let name = LeftValue.name left in
  let prop' = Property.static (Prop.str prop) in
  let ls_obj = eval_expr state obj in
  let ls_args = List.map (eval_expr state) args in
  let ls_args' = ls_obj :: ls_args in
  let method_name = object_property_name ls_obj obj prop' in
  add_static_orig_object_property state method_name ls_obj prop' cid;
  let ls_method = lookup_property state ls_obj prop' in
  let cid1 = offset cid 1 in
  let cid2 = offset cid 2 in
  let cid3 = offset cid 3 in
  let (state', l_call, l_retn) =
    add_function_call state method_name name ls_method ls_args' cid1 cid2 in
  Store.replace state'.store name (Node.Set.singleton l_retn);
  call_interceptor state' ls_method l_call l_retn ls_args' args cid3

and build_dynamic_method_call (state : State.t) (left : 'm LeftValue.t)
    (obj : 'm Expression.t) (prop : 'm Expression.t)
    (args : 'm Expression.t list) (cid : cid) : State.t =
  let name = LeftValue.name left in
  let prop' = Property.dynamic () in
  let ls_obj = eval_expr state obj in
  let ls_prop = eval_expr state prop in
  let ls_args = List.map (eval_expr state) args in
  let ls_args' = ls_obj :: ls_args in
  let method_name = object_property_name ls_obj obj prop' in
  add_dynamic_orig_object_property state method_name ls_obj ls_prop cid;
  let ls_method = lookup_property state ls_obj prop' in
  let cid1 = offset cid 1 in
  let cid2 = offset cid 2 in
  let cid3 = offset cid 3 in
  let (state', l_call, l_retn) =
    add_function_call state method_name name ls_method ls_args' cid1 cid2 in
  Store.replace state'.store name (Node.Set.singleton l_retn);
  call_interceptor state' ls_method l_call l_retn ls_args' args cid3

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
  let store = Store.copy state.store in
  let state' = build_sequence state body in
  let store' = Store.lub state'.store store in
  if Store.equal store' store then state' else build_loop state' body

and build_function_declaration (state : State.t) (left : 'm LeftValue.t)
    (params : 'm Identifier.t list) (cid : cid) : State.t =
  let name = LeftValue.name left in
  let l_func = State.add_function_node state cid name in
  Store.replace state.store name (Node.Set.singleton l_func);
  let state' = { state with curr_func = Some l_func } in
  let cid' = offset cid (List.length params + 1) in
  let l_this = State.add_parameter_node state' cid' 0 "this" in
  State.add_parameter_edge state' l_func l_this 0;
  Fun.flip List.iteri params (fun idx param ->
      let idx' = idx + 1 in
      let cid' = offset cid idx' in
      let name = Identifier.name param in
      let l_param = State.add_parameter_node state' cid' idx' name in
      State.add_parameter_edge state' l_func l_param idx' );
  state

and build_function_definition (state : State.t) (left : 'm LeftValue.t)
    (params : 'm Identifier.t list) (body : 'm Statement.t list)
    (hoisted : FunctionHoisting.t) (cid : cid) : State.t =
  let state' =
    if FunctionHoisting.hoisted hoisted then state
    else build_function_declaration state left params cid in
  let l_func = State.get_node state cid in
  let store' = Store.copy state'.store in
  let state'' = { state' with store = store'; curr_func = Some l_func } in
  let state''' = initialize_hoisted_functions state'' body in
  let cid' = offset cid (List.length params + 1) in
  let l_this = State.get_node state cid' in
  Store.replace state'''.store "this" (Node.Set.singleton l_this);
  Fun.flip List.iteri params (fun idx param ->
      let idx' = idx + 1 in
      let cid' = offset cid idx' in
      let name = Identifier.name param in
      let l_param = State.get_node state cid' in
      Store.replace state'''.store name (Node.Set.singleton l_param) );
  let state''' = build_sequence state''' body in
  State.join state state'''

and build_loop_break (state : State.t) (_label : 'm Identifier.t option) :
    State.t =
  (* TODO: implement flow control to the builder *)
  (* TODO: implement labels on the loop breaks *)
  state

and build_return (state : State.t) (arg : 'm Expression.t option) : State.t =
  (* TODO: implement flow control to the builder *)
  (* the return statement should prevent all code afterwards from being analyzed *)
  let ls_arg = Option.map (eval_expr state) arg in
  match (state.curr_func, ls_arg) with
  | (None, _) | (Some _, None) -> state
  | (Some l_func, Some ls_arg') ->
    Node.Set.iter (State.add_return_edge state l_func) ls_arg';
    state

and build_throw (state : State.t) (_arg : 'm Expression.t) : State.t =
  (* TODO: implement the throw construct *)
  (* similar to the return, but set a flag in the environment that tells that an exception may have been thrown *)
  state

and build_try (state : State.t) (body : 'm Statement.t list)
    (handler : 'm Catch.t option) (finalizer : 'm Statement.t list option) :
    State.t =
  (* TODO: implement the catch construct *)
  (* the catch body should only be analyzed if an exception is thrown *)
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

and build_statement (state : State.t) (stmt : 'm Statement.t) : State.t =
  match stmt.el with
  | `ExprStmt _ -> state
  | `VarDecl _ -> state
  | `Assignment { left; right } -> build_assignment state left right
  | `NewObject { left } -> build_new state left (cid stmt)
  | `NewArray { left } -> build_new state left (cid stmt)
  | `Unopt { left; arg; _ } -> build_unopt state left arg (cid stmt)
  | `Binopt { left; arg1; arg2; _ } ->
    build_binopt state left arg1 arg2 (cid stmt)
  | `Yield { left; arg; delegate } ->
    build_yield state left arg delegate (cid stmt)
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
  | `NewCall { left; callee; args } ->
    build_function_call state left callee args (cid stmt)
  | `FunctionCall { left; callee; args } ->
    build_function_call state left callee args (cid stmt)
  | `StaticMethodCall { left; obj; prop; args } ->
    build_static_method_call state left obj prop args (cid stmt)
  | `DynamicMethodCall { left; obj; prop; args } ->
    build_dynamic_method_call state left obj prop args (cid stmt)
  | `FunctionDefinition { left; params; body; hoisted; _ } ->
    build_function_definition state left params body hoisted (cid stmt)
  | `DynamicImport _ -> state
  | `If { consequent; alternate; _ } -> build_if state consequent alternate
  | `Switch { cases; _ } -> build_switch state cases
  | `While { body; _ } -> build_loop state body
  | `ForIn { body; _ } -> build_loop state body
  | `ForOf { body; _ } -> build_loop state body
  | `Break { label } -> build_loop_break state label
  | `Continue { label } -> build_loop_break state label
  | `Return { arg } -> build_return state arg
  | `Throw { arg } -> build_throw state arg
  | `Try { body; handler; finalizer } -> build_try state body handler finalizer
  | `With { expr; body } -> build_with state expr body
  | `Labeled { label; body } -> build_labeled state label body
  | `Debugger _ -> state
  | `ImportDecl _ -> state
  | `ExportDecl _ -> state

and build_sequence (state : State.t) (stmts : 'm Statement.t list) : State.t =
  List.fold_left build_statement state stmts

and build_sequence_opt (state : State.t) (stmts : 'm Statement.t list option) :
    State.t =
  Option.fold ~none:state ~some:(build_sequence state) stmts

let build_file (state : State.t) (file : 'm File.t) : Mdg.t =
  let state' = initialize_state state file in
  let state'' = build_sequence state' file in
  state''.mdg
