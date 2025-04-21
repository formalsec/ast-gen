open Graphjs_base
open Graphjs_share
open Graphjs_ast
open Metadata

type 'a el = ('a, Region.t) Metadata.t
type cid = Allocator.cid

let newcid (el : 'a el) : cid = Allocator.cid el
let offset (cid : cid) (ofs : int) : cid = Allocator.offset cid ofs

let convert_literal (literal : LiteralValue.t) : Literal.t =
  match literal.value with
  | Null -> Literal.create Null literal.raw
  | String _ -> Literal.create String literal.raw
  | Number _ -> Literal.create Number literal.raw
  | Boolean _ -> Literal.create Boolean literal.raw
  | Regex _ -> Literal.create Regex literal.raw
  | BigInt _ -> Literal.create BigInt literal.raw

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
  Fun.flip Node.Set.map_flat ls_obj (fun l_obj ->
      Mdg.object_lookup state.mdg l_obj prop )

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
  let prop = Property.Dynamic in
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
  State.add_version_edge state l_obj l_node Property.Dynamic;
  Node.Set.iter (Fun.flip (State.add_dependency_edge state) l_node) ls_prop;
  Store.strong_update state.store l_obj l_node;
  Node.Set.singleton l_node

let dynamic_weak_nv (state : State.t) (name : string) (ls_obj : Node.Set.t)
    (ls_prop : Node.Set.t) (cid : cid) : Node.Set.t =
  let prop = Property.Dynamic in
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

let add_function_call (state : State.t) (call_name : string)
    (retn_name : string) (ls_func : Node.Set.t) (ls_args : Node.Set.t list)
    (call_cid : cid) (retn_cid : cid) : State.t * Node.t * Node.t =
  let l_call = State.add_call_node state call_cid call_name in
  let l_retn = State.add_return_node state retn_cid retn_name in
  let state' = { state with mdg = Mdg.add_call state.mdg l_call } in
  let add_arg_f = Fun.flip2 (State.add_argument_edge state) l_call in
  Fun.flip Node.Set.iter ls_func (fun l_func ->
      State.add_caller_edge state l_call l_func );
  State.add_dependency_edge state l_call l_retn;
  Fun.flip List.iteri ls_args (fun idx ls_arg ->
      Node.Set.iter (add_arg_f idx) ls_arg );
  (state', l_call, l_retn)

let lookup_interceptor (state : State.t) (name : string) (ls_obj : Node.Set.t)
    (prop : Property.t) (ls_lookup : Node.Set.t) : State.t =
  let ls_orig = Node.Set.map_flat (Mdg.object_orig_versions state.mdg) ls_obj in
  Fun.flip2 Node.Set.fold ls_orig state (fun l_orig state ->
      match State.get_lookup_interceptor state l_orig with
      | None -> state
      | Some interceptor_f ->
        interceptor_f state l_orig name ls_obj prop ls_lookup )

let call_interceptor (state : State.t) (name : string) (ls_func : Node.Set.t)
    (l_call : Node.t) (l_retn : Node.t) (ls_args : Node.Set.t list) : State.t =
  Fun.flip2 Node.Set.fold ls_func state (fun l_func state ->
      match State.get_call_interceptor state l_func with
      | None -> state
      | Some interceptor_f ->
        interceptor_f state name l_func l_call l_retn ls_args )

let rec eval_expr (state : State.t) (expr : 'm Expression.t) : Node.Set.t =
  let exprs_f acc expr = Node.Set.union acc (eval_expr state expr) in
  match expr.el with
  | `LiteralValue literal -> eval_literal_expr state literal (newcid expr)
  | `TemplateLiteral { exprs; _ } -> List.fold_left exprs_f Node.Set.empty exprs
  | `Identifier id -> eval_store_expr state (Identifier.name' id)
  | `This _ -> eval_store_expr state "this"

and eval_literal_expr (state : State.t) (literal : LiteralValue.t) (cid : cid) :
    Node.Set.t =
  match (state.env.literal_mode, state.literal_ctx) with
  | (Multiple, Skip) ->
    let literal' = convert_literal literal in
    let l_literal = State.add_candidate_literal_node state cid literal' in
    Node.Set.singleton l_literal
  | (Multiple, Make) | (Multiple, MakeProp) | (PropWrap, MakeProp) ->
    let literal' = convert_literal literal in
    let l_literal = State.add_literal_node state cid literal' in
    Node.Set.singleton l_literal
  | _ -> Node.Set.singleton state.mdg.literal

and eval_store_expr (state : State.t) (id : string) : Node.Set.t =
  let nodes = Store.find state.store id in
  Fun.flip Node.Set.map nodes (fun node ->
      if Node.is_invalid node then State.concretize_node state id node else node )

let rec initialize_builder (env : State.Env.t) (taint_config : Taint_config.t)
    (prog : 'm Prog.t) : State.t =
  Node.reset_generators ();
  let state = State.create env prog in
  let cbs_builder = Jslib.builder_cbs build_file in
  if not (Literal.is_multiple env.literal_mode) then
    Mdg.add_node state.mdg state.mdg.literal;
  Jslib.initialize_builder state taint_config cbs_builder

and initialize_file (state : State.t) (f : 'm File.t) (main : bool) : State.t =
  let mrel = if main then None else Some f.mrel in
  let state' = State.initialize state f.path mrel in
  let state'' = Jslib.initialize_file state' in
  initialize_hoisted_functions state'' f.body

and initialize_hoisted_functions (state : State.t) (stmts : 'm Statement.t list)
    : State.t =
  Fun.flip2 List.fold_left state stmts (fun state stmt ->
      match stmt.el with
      | `FunctionDefinition func when FunctionDefinition.is_hoisted func ->
        build_function_declaration state func.left func.params (newcid stmt)
      | _ -> state )

and build_assignment (state : State.t) (left : 'm LeftValue.t)
    (right : 'm Expression.t) : State.t =
  let name = LeftValue.name left in
  let ls_right = eval_expr (State.skip_literal state) right in
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
  let prop' = Property.Static (Prop.name prop) in
  let ls_obj = eval_expr state obj in
  let field_name = object_property_name ls_obj obj prop' in
  add_static_orig_object_property state field_name ls_obj prop' cid;
  let ls_lookup = lookup_property state ls_obj prop' in
  Store.replace state.store name ls_lookup;
  lookup_interceptor state name ls_obj prop' ls_lookup

and build_dynamic_lookup (state : State.t) (left : 'm LeftValue.t)
    (obj : 'm Expression.t) (prop : 'm Expression.t) (cid : cid) : State.t =
  let name = LeftValue.name left in
  let prop' = Property.Dynamic in
  let ls_obj = eval_expr state obj in
  let ls_prop = eval_expr state prop in
  let field_name = object_property_name ls_obj obj prop' in
  add_dynamic_orig_object_property state field_name ls_obj ls_prop cid;
  let ls_lookup = lookup_property state ls_obj prop' in
  Store.replace state.store name ls_lookup;
  lookup_interceptor state name ls_obj prop' ls_lookup

and build_static_update (state : State.t) (obj : 'm Expression.t)
    (prop : 'm Prop.t) (right : 'm Expression.t) (cid : cid) : State.t =
  let prop' = Property.Static (Prop.name prop) in
  let ls_obj = eval_expr state obj in
  let ls_obj' = Node.Set.map_flat (Mdg.object_tail_versions state.mdg) ls_obj in
  let ls_right = eval_expr (State.make_literal_prop state) right in
  let obj_name = object_name ls_obj obj in
  let ls_new = add_static_object_version state obj_name ls_obj' prop' cid in
  Fun.flip Node.Set.iter ls_new (fun l_new ->
      Fun.flip Node.Set.iter ls_right (fun l_right ->
          State.add_property_edge state l_new l_right prop' ) );
  state

and build_dynamic_update (state : State.t) (obj : 'm Expression.t)
    (prop : 'm Expression.t) (right : 'm Expression.t) (cid : cid) : State.t =
  let prop' = Property.Dynamic in
  let ls_obj = eval_expr state obj in
  let ls_obj' = Node.Set.map_flat (Mdg.object_tail_versions state.mdg) ls_obj in
  let ls_prop = eval_expr state prop in
  let ls_right = eval_expr (State.make_literal_prop state) right in
  let obj_name = object_name ls_obj obj in
  let ls_new = add_dynamic_object_version state obj_name ls_obj' ls_prop cid in
  Fun.flip Node.Set.iter ls_new (fun l_new ->
      Fun.flip Node.Set.iter ls_right (fun l_right ->
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
  let cid1 = newcid left in
  let call_name = Identifier.name callee in
  let retn_name = LeftValue.name left in
  let ls_func = eval_store_expr state call_name in
  let ls_args = List.map (eval_expr state) args in
  let ls_args' = Node.Set.empty :: ls_args in
  let add_f = add_function_call state call_name retn_name in
  let (state', l_call, l_retn) = add_f ls_func ls_args' cid cid1 in
  Store.replace state'.store retn_name (Node.Set.singleton l_retn);
  call_interceptor state' retn_name ls_func l_call l_retn ls_args'

and build_static_method_call (state : State.t) (left : 'm LeftValue.t)
    (obj : 'm Expression.t) (prop : 'm Prop.t) (args : 'm Expression.t list)
    (cid : cid) : State.t =
  let cid1 = newcid left in
  let cid2 = newcid prop in
  let retn_name = LeftValue.name left in
  let prop' = Property.Static (Prop.str prop) in
  let ls_obj = eval_expr state obj in
  let ls_args = List.map (eval_expr state) args in
  let ls_args' = ls_obj :: ls_args in
  let call_name = object_property_name ls_obj obj prop' in
  add_static_orig_object_property state call_name ls_obj prop' cid2;
  let ls_method = lookup_property state ls_obj prop' in
  let add_f = add_function_call state call_name retn_name in
  let (state', l_call, l_retn) = add_f ls_method ls_args' cid cid1 in
  Store.replace state'.store retn_name (Node.Set.singleton l_retn);
  call_interceptor state' retn_name ls_method l_call l_retn ls_args'

and build_dynamic_method_call (state : State.t) (left : 'm LeftValue.t)
    (obj : 'm Expression.t) (prop : 'm Expression.t)
    (args : 'm Expression.t list) (cid : cid) : State.t =
  let cid1 = newcid left in
  let cid2 = newcid prop in
  let retn_name = LeftValue.name left in
  let prop' = Property.Dynamic in
  let ls_obj = eval_expr state obj in
  let ls_prop = eval_expr state prop in
  let ls_args = List.map (eval_expr state) args in
  let ls_args' = ls_obj :: ls_args in
  let call_name = object_property_name ls_obj obj prop' in
  add_dynamic_orig_object_property state call_name ls_obj ls_prop cid2;
  let ls_method = lookup_property state ls_obj prop' in
  let add_f = add_function_call state call_name retn_name in
  let (state', l_call, l_retn) = add_f ls_method ls_args' cid cid1 in
  Store.replace state'.store retn_name (Node.Set.singleton l_retn);
  call_interceptor state' retn_name ls_method l_call l_retn ls_args'

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
  let cid' = newcid left in
  let l_this = State.add_parameter_node state' cid' 0 "this" in
  State.add_parameter_edge state' l_func l_this 0;
  Fun.flip List.iteri params (fun idx param ->
      let idx' = idx + 1 in
      let cid' = newcid param in
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
  let cid' = newcid left in
  let l_this = State.get_node state cid' in
  Store.replace state'''.store "this" (Node.Set.singleton l_this);
  Fun.flip List.iteri params (fun _ param ->
      let cid' = newcid param in
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
  | `NewObject { left } -> build_new state left (newcid stmt)
  | `NewArray { left } -> build_new state left (newcid stmt)
  | `Unopt { left; arg; _ } -> build_unopt state left arg (newcid stmt)
  | `Binopt { left; arg1; arg2; _ } ->
    build_binopt state left arg1 arg2 (newcid stmt)
  | `Yield { left; arg; delegate } ->
    build_yield state left arg delegate (newcid stmt)
  | `StaticLookup { left; obj; prop } ->
    build_static_lookup state left obj prop (newcid stmt)
  | `DynamicLookup { left; obj; prop } ->
    build_dynamic_lookup state left obj prop (newcid stmt)
  | `StaticUpdate { obj; prop; right } ->
    build_static_update state obj prop right (newcid stmt)
  | `DynamicUpdate { obj; prop; right } ->
    build_dynamic_update state obj prop right (newcid stmt)
  | `StaticDelete { left; obj; prop } ->
    build_static_delete state left obj prop (newcid stmt)
  | `DynamicDelete { left; obj; prop } ->
    build_dynamic_delete state left obj prop (newcid stmt)
  | `NewCall { left; callee; args } ->
    build_function_call state left callee args (newcid stmt)
  | `FunctionCall { left; callee; args } ->
    build_function_call state left callee args (newcid stmt)
  | `StaticMethodCall { left; obj; prop; args } ->
    build_static_method_call state left obj prop args (newcid stmt)
  | `DynamicMethodCall { left; obj; prop; args } ->
    build_dynamic_method_call state left obj prop args (newcid stmt)
  | `FunctionDefinition { left; params; body; hoisted; _ } ->
    build_function_definition state left params body hoisted (newcid stmt)
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

and build_file (state : State.t) (file : 'm File.t) (main : bool) : State.t =
  let state' = initialize_file state file main in
  let state'' = build_sequence state' file.body in
  Pcontext.file_built state.pcontext file.path;
  state''.env.cb_mdg file.mrel;
  state''

let build_program (env : State.Env.t) (taint_config : Taint_config.t)
    (prog : 'm Prog.t) : Mdg.t =
  let main = Prog.main prog in
  let state = initialize_builder env taint_config prog in
  let state' = build_file state main true in
  state'.mdg
