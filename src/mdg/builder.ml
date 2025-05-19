open Graphjs_base
open Graphjs_share
open Graphjs_ast
open Metadata

type cid = Allocator.cid

let newcid (el : ('a, Region.t) Metadata.t) : cid = Allocator.cid el
let offset (cid : cid) (ofs : int) : cid = Allocator.offset cid ofs

let opaque_function_eval (env : State.Env.t) : bool =
  match env.func_eval_mode with Opaque -> true | _ -> false

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

let lookup_method (state : State.t) (call_name : string) (call_cid : cid)
    (ls_obj : Node.Set.t) (prop : Property.t) : Node.Set.t =
  let ls_func = lookup_property state ls_obj prop in
  if Node.Set.is_empty ls_func then
    let call_cid' = offset call_cid 1 in
    let l_func = State.add_blank_node state call_cid' call_name in
    Node.Set.singleton l_func
  else ls_func

let add_static_orig_object_property (state : State.t) (name : string)
    (ls_obj : Node.Set.t) (prop : Property.t) (cid : cid) : unit =
  Fun.flip Node.Set.iter ls_obj (fun l_obj ->
      let ls_orig = Mdg.object_orig_versions state.mdg l_obj in
      Fun.flip Node.Set.iter ls_orig (fun l_orig ->
          if not (Mdg.has_property state.mdg l_orig prop) then
            let l_prop = State.add_object_node state cid name in
            State.add_property_edge state l_orig l_prop prop ) )

let add_dynamic_orig_object_property (state : State.t) (name : string)
    (ls_obj : Node.Set.t) (ls_prop : Node.Set.t) (cid : cid) : unit =
  let prop = Property.Dynamic in
  let set_deps_f l_node = Fun.flip (State.add_dependency_edge state) l_node in
  Fun.flip Node.Set.iter ls_obj (fun l_obj ->
      let ls_orig = Mdg.object_orig_versions state.mdg l_obj in
      Fun.flip Node.Set.iter ls_orig (fun l_orig ->
          match Mdg.get_property state.mdg l_orig prop with
          | [] ->
            let l_prop = State.add_object_node state cid name in
            State.add_property_edge state l_orig l_prop prop;
            Node.Set.iter (set_deps_f l_prop) ls_prop
          | l_prop :: _ -> Node.Set.iter (set_deps_f l_prop) ls_prop ) )

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
  let add_arg_f = Fun.flip2 (State.add_argument_edge state) l_call in
  Fun.flip Node.Set.iter ls_func (fun l_func ->
      State.add_caller_edge state l_call l_func );
  State.add_dependency_edge state l_call l_retn;
  Fun.flip List.iteri ls_args (fun idx ls_arg ->
      Node.Set.iter (add_arg_f idx) ls_arg );
  (state, l_call, l_retn)

let call_interceptor (state : State.t) (retn_name : string)
    (ls_func : Node.Set.t) (ls_args : Node.Set.t list) : State.t =
  Fun.flip2 Node.Set.fold ls_func state (fun l_func state ->
      match State.get_call_interceptor state l_func with
      | Some call_f -> call_f state retn_name l_func ls_args
      | None -> state )

let rec eval_expr (state : State.t) (expr : 'm Expression.t) : Node.Set.t =
  match expr.el with
  | `LiteralValue literal -> eval_literal_expr state literal (newcid expr)
  | `TemplateLiteral { exprs; _ } -> eval_template_literal_expr state expr exprs
  | `Identifier id -> eval_store_expr state (Identifier.name' id) (newcid expr)
  | `This _ -> eval_store_expr state "this" (newcid expr)

and eval_literal_expr (state : State.t) (literal : LiteralValue.t) (cid : cid) :
    Node.Set.t =
  let literal' = convert_literal literal in
  let l_literal = State.add_literal_node state cid literal' in
  Node.Set.singleton l_literal

and eval_template_literal_expr (state : State.t) (expr : 'm Expression.t)
    (exprs : 'm Expression.t list) : Node.Set.t =
  let literal = Literal.create Template (Expression.str expr) in
  let l_literal = State.add_literal_node state (newcid expr) literal in
  let add_dep_f = Fun.flip (State.add_dependency_edge state) l_literal in
  Fun.flip List.iter exprs (fun expr ->
      Node.Set.iter add_dep_f (eval_expr state expr) );
  Node.Set.singleton l_literal

and eval_store_expr (state : State.t) (id : string) (cid : cid) : Node.Set.t =
  let ls_expr = Store.find state.store id in
  if Node.Set.is_empty ls_expr then
    let l_expr = State.add_blank_node state cid id in
    Node.Set.singleton l_expr
  else ls_expr

let rec initialize_builder (env : State.Env.t) (tconf : Taint_config.t)
    (prog : 'm Prog.t) : State.t =
  Location.reset_generator ();
  let state = State.create env tconf prog in
  let cbs_builder = Interceptor.cbs_builder build_file in
  Interceptor.initialize state cbs_builder;
  state

and initialize_file (state : State.t) (f : 'm File.t) (main : bool)
    (l_parent : Node.t option) : State.t =
  let state' = State.initialize state f.path f.mrel main l_parent in
  initialize_hoisted_functions state' f.body

and initialize_hoisted_functions (state : State.t) (stmts : 'm Statement.t list)
    : State.t =
  Fun.flip2 List.fold_left state stmts (fun state stmt ->
      match stmt.el with
      | `FunctionDefinition func when FunctionDefinition.is_hoisted func ->
        build_function_declaration state func (newcid stmt)
      | _ -> state )

and can_unfold_call (state : State.t) (l_func : Node.t) : bool =
  match state.env.func_eval_mode with
  | Opaque -> Log.fail "unexpected function evaluation mode"
  | Unfold -> Log.fail "not implemented (use 'unfold:rec' or 'unfold:<depth>')"
  | UnfoldRec -> not (List.mem l_func state.curr_stack)
  | UnfoldDepth depth -> List.length state.curr_stack < depth

and unfold_this_param (state : State.t) (cons : bool) (retn_name : string)
    (retn_cid : cid) (ls_args : Node.Set.t list) : Node.Set.t =
  if cons then
    let retn_cid' = offset retn_cid 1 in
    let l_this = State.add_object_node state retn_cid' retn_name in
    Node.Set.singleton l_this
  else List.hd ls_args

and unfold_this_retn (state : State.t) (cons : bool) (ls_this : Node.Set.t) :
    Node.Set.t =
  let fold_f l_this acc =
    Node.Set.union acc (Mdg.object_tail_versions state.mdg l_this) in
  if cons then Node.Set.fold fold_f ls_this Node.Set.empty
  else state.curr_return

and unfold_function_call (state : State.t) (cons : bool) (call_name : string)
    (retn_name : string) (ls_func : Node.Set.t) (ls_args : Node.Set.t list)
    (call_cid : cid) (retn_cid : cid) : State.t * Node.Set.t =
  let ls_this = unfold_this_param state cons retn_name retn_cid ls_args in
  Fun.flip2 Node.Set.fold ls_func (state, Node.Set.empty)
    (fun l_func (state, ls_retn) ->
      let unfold = can_unfold_call state l_func in
      let func = Pcontext.func state.pcontext l_func in
      match (unfold, func) with
      | (false, _) | (true, None) ->
        let add_call_f = add_function_call state call_name retn_name in
        let (state', _, l_retn) = add_call_f ls_func ls_args call_cid retn_cid in
        let ls_retn' = Node.Set.add l_retn ls_retn in
        (state', ls_retn')
      | (true, Some { floc; func; eval_store; _ }) ->
        let store = Store.copy eval_store in
        let curr_floc = floc in
        let curr_stack = l_func :: state.curr_stack in
        let curr_parent = Some l_func in
        let state' = { state with store; curr_floc; curr_stack; curr_parent } in
        let state'' = initialize_hoisted_functions state' func.body in
        Store.replace state''.store "this" ls_this;
        Fun.flip List.iteri (List.tl ls_args) (fun idx ls_arg ->
            Fun.flip Option.iter (List.nth_opt func.params idx) (fun param ->
                let name = Identifier.name param in
                Store.replace state''.store name ls_arg ) );
        let state''' = build_sequence state'' func.body in
        let ls_retn' = unfold_this_retn state''' cons ls_this in
        let ls_retn'' = Node.Set.union ls_retn ls_retn' in
        (state, ls_retn'') )

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
  let prop' = Property.Static (Prop.name prop) in
  let ls_obj = eval_expr state obj in
  let prop_name = object_property_name ls_obj obj prop' in
  add_static_orig_object_property state prop_name ls_obj prop' cid;
  let tail_lookup_f = Mdg.object_tail_versions state.mdg in
  let ls_lookup = lookup_property state ls_obj prop' in
  let ls_lookup' = Node.Set.map_flat tail_lookup_f ls_lookup in
  Store.replace state.store name ls_lookup';
  state

and build_dynamic_lookup (state : State.t) (left : 'm LeftValue.t)
    (obj : 'm Expression.t) (prop : 'm Expression.t) (cid : cid) : State.t =
  let name = LeftValue.name left in
  let prop' = Property.Dynamic in
  let ls_obj = eval_expr state obj in
  let ls_prop = eval_expr state prop in
  let prop_name = object_property_name ls_obj obj prop' in
  add_dynamic_orig_object_property state prop_name ls_obj ls_prop cid;
  let tail_lookup_f = Mdg.object_tail_versions state.mdg in
  let ls_lookup = lookup_property state ls_obj prop' in
  let ls_lookup' = Node.Set.map_flat tail_lookup_f ls_lookup in
  Store.replace state.store name ls_lookup';
  state

and build_static_update (state : State.t) (obj : 'm Expression.t)
    (prop : 'm Prop.t) (right : 'm Expression.t) (cid : cid) : State.t =
  let prop' = Property.Static (Prop.name prop) in
  let ls_obj = eval_expr state obj in
  let ls_right = eval_expr state right in
  let obj_name = object_name ls_obj obj in
  let ls_new = add_static_object_version state obj_name ls_obj prop' cid in
  Fun.flip Node.Set.iter ls_new (fun l_new ->
      Fun.flip Node.Set.iter ls_right (fun l_right ->
          State.add_property_edge state l_new l_right prop' ) );
  state

and build_dynamic_update (state : State.t) (obj : 'm Expression.t)
    (prop : 'm Expression.t) (right : 'm Expression.t) (cid : cid) : State.t =
  let prop' = Property.Dynamic in
  let ls_obj = eval_expr state obj in
  let ls_prop = eval_expr state prop in
  let ls_right = eval_expr state right in
  let obj_name = object_name ls_obj obj in
  let ls_new = add_dynamic_object_version state obj_name ls_obj ls_prop cid in
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

and build_new_call (state : State.t) (left : 'm LeftValue.t)
    (callee : 'm Identifier.t) (args : 'm Expression.t list) (cid : cid) :
    State.t =
  ( if opaque_function_eval state.env then build_function_call_opaque
    else build_function_call_unfold true )
    state left callee args cid

and build_function_call (state : State.t) (left : 'm LeftValue.t)
    (callee : 'm Identifier.t) (args : 'm Expression.t list) (cid : cid) :
    State.t =
  ( if opaque_function_eval state.env then build_function_call_opaque
    else build_function_call_unfold false )
    state left callee args cid

and build_function_call_opaque (state : State.t) (left : 'm LeftValue.t)
    (callee : 'm Identifier.t) (args : 'm Expression.t list) (call_cid : cid) :
    State.t =
  let retn_cid = newcid left in
  let call_name = Identifier.name callee in
  let retn_name = LeftValue.name left in
  let ls_func = eval_store_expr state call_name (newcid callee) in
  let ls_args = List.map (eval_expr state) args in
  let ls_args' = Node.Set.empty :: ls_args in
  let add_call_f = add_function_call state call_name retn_name in
  let (state', _, l_retn) = add_call_f ls_func ls_args' call_cid retn_cid in
  Store.replace state'.store retn_name (Node.Set.singleton l_retn);
  call_interceptor state' retn_name ls_func ls_args'

and build_function_call_unfold (cons : bool) (state : State.t)
    (left : 'm LeftValue.t) (callee : 'm Identifier.t)
    (args : 'm Expression.t list) (call_cid : cid) : State.t =
  let retn_cid = newcid left in
  let call_name = Identifier.name callee in
  let retn_name = LeftValue.name left in
  let ls_func = eval_store_expr state call_name (newcid callee) in
  let ls_args = List.map (eval_expr state) args in
  let ls_args' = Node.Set.empty :: ls_args in
  let unfold_call_f = unfold_function_call state cons call_name retn_name in
  let (state', ls_retn) = unfold_call_f ls_func ls_args' call_cid retn_cid in
  Store.replace state'.store retn_name ls_retn;
  call_interceptor state' retn_name ls_func ls_args'

and build_static_method_call (state : State.t) (left : 'm LeftValue.t)
    (obj : 'm Expression.t) (prop : 'm Prop.t) (args : 'm Expression.t list)
    (cid : cid) : State.t =
  ( if opaque_function_eval state.env then build_static_method_call_opaque
    else build_static_method_call_unfold )
    state left obj prop args cid

and build_static_method_call_opaque (state : State.t) (left : 'm LeftValue.t)
    (obj : 'm Expression.t) (prop : 'm Prop.t) (args : 'm Expression.t list)
    (call_cid : cid) : State.t =
  let prop_cid = newcid prop in
  let retn_cid = newcid left in
  let retn_name = LeftValue.name left in
  let prop' = Property.Static (Prop.str prop) in
  let ls_obj = eval_expr state obj in
  let ls_args = List.map (eval_expr state) args in
  let ls_args' = ls_obj :: ls_args in
  let call_name = object_property_name ls_obj obj prop' in
  add_static_orig_object_property state call_name ls_obj prop' prop_cid;
  let ls_func = lookup_method state call_name call_cid ls_obj prop' in
  let add_call_f = add_function_call state call_name retn_name in
  let (state', _, l_retn) = add_call_f ls_func ls_args' call_cid retn_cid in
  Store.replace state'.store retn_name (Node.Set.singleton l_retn);
  call_interceptor state' retn_name ls_func ls_args'

and build_static_method_call_unfold (state : State.t) (left : 'm LeftValue.t)
    (obj : 'm Expression.t) (prop : 'm Prop.t) (args : 'm Expression.t list)
    (call_cid : cid) : State.t =
  let prop_cid = newcid prop in
  let retn_cid = newcid left in
  let retn_name = LeftValue.name left in
  let prop' = Property.Static (Prop.str prop) in
  let ls_obj = eval_expr state obj in
  let ls_args = List.map (eval_expr state) args in
  let ls_args' = ls_obj :: ls_args in
  let call_name = object_property_name ls_obj obj prop' in
  add_static_orig_object_property state call_name ls_obj prop' prop_cid;
  let ls_func = lookup_method state call_name call_cid ls_obj prop' in
  let unfold_call_f = unfold_function_call state false call_name retn_name in
  let (state', ls_retn) = unfold_call_f ls_func ls_args' call_cid retn_cid in
  Store.replace state'.store retn_name ls_retn;
  call_interceptor state' retn_name ls_func ls_args'

and build_dynamic_method_call (state : State.t) (left : 'm LeftValue.t)
    (obj : 'm Expression.t) (prop : 'm Expression.t)
    (args : 'm Expression.t list) (cid : cid) : State.t =
  ( if opaque_function_eval state.env then build_dynamic_method_call_opaque
    else build_dynamic_method_call_unfold )
    state left obj prop args cid

and build_dynamic_method_call_opaque (state : State.t) (left : 'm LeftValue.t)
    (obj : 'm Expression.t) (prop : 'm Expression.t)
    (args : 'm Expression.t list) (call_cid : cid) : State.t =
  let prop_cid = newcid prop in
  let retn_cid = newcid left in
  let retn_name = LeftValue.name left in
  let prop' = Property.Dynamic in
  let ls_obj = eval_expr state obj in
  let ls_prop = eval_expr state prop in
  let ls_args = List.map (eval_expr state) args in
  let ls_args' = ls_obj :: ls_args in
  let call_name = object_property_name ls_obj obj prop' in
  add_dynamic_orig_object_property state call_name ls_obj ls_prop prop_cid;
  let ls_func = lookup_property state ls_obj prop' in
  let add_call_f = add_function_call state call_name retn_name in
  let (state', _, l_retn) = add_call_f ls_func ls_args' call_cid retn_cid in
  Store.replace state'.store retn_name (Node.Set.singleton l_retn);
  call_interceptor state' retn_name ls_func ls_args'

and build_dynamic_method_call_unfold (state : State.t) (left : 'm LeftValue.t)
    (obj : 'm Expression.t) (prop : 'm Expression.t)
    (args : 'm Expression.t list) (call_cid : cid) : State.t =
  let prop_cid = newcid prop in
  let retn_cid = newcid left in
  let retn_name = LeftValue.name left in
  let prop' = Property.Dynamic in
  let ls_obj = eval_expr state obj in
  let ls_prop = eval_expr state prop in
  let ls_args = List.map (eval_expr state) args in
  let ls_args' = ls_obj :: ls_args in
  let call_name = object_property_name ls_obj obj prop' in
  add_dynamic_orig_object_property state call_name ls_obj ls_prop prop_cid;
  let ls_func = lookup_property state ls_obj prop' in
  let unfold_call_f = unfold_function_call state false call_name retn_name in
  let (state', ls_retn) = unfold_call_f ls_func ls_args' call_cid retn_cid in
  Store.replace state'.store retn_name ls_retn;
  call_interceptor state' retn_name ls_func ls_args'

and build_if (state : State.t) (consequent : 'm Statement.t list)
    (alternate : 'm Statement.t list option) : State.t =
  match alternate with
  | None -> build_scoped_sequence state consequent
  | Some alternate' ->
    let state2 = State.copy state in
    let state1' = build_scoped_sequence state consequent in
    let state2' = build_scoped_sequence state2 alternate' in
    State.lub state1' state2'

and build_switch (state : State.t) (cases : 'm SwitchCase.t list) : State.t =
  (* TODO: implement flow control to the builder *)
  (* this statement can be improved by reasoning about the control flow of the break and return statements *)
  (* additionally, we should account for the initial states of the switch not being processed *)
  List.map SwitchCase.body cases |> List.fold_left build_scoped_sequence state

and build_loop (state : State.t) (body : 'm Statement.t list) : State.t =
  (* TODO: model the assignment in the forin and forof statement *)
  (* we treat this assignment as a lookup on all properties of the expression *)
  (* the left value should depend of all the properties of the right value *)
  let store = Store.copy state.store in
  let state' = build_scoped_sequence state body in
  let store' = Store.lub state'.store store in
  if Store.equal store' store then state' else build_loop state' body

and build_function_declaration (state : State.t)
    (func : 'm FunctionDefinition.t) (cid : cid) : State.t =
  ( if opaque_function_eval state.env then build_function_declaration_opaque
    else build_function_declaration_unfold )
    state func cid

and build_function_declaration_opaque (state : State.t)
    (func : 'm FunctionDefinition.t) (func_cid : cid) : State.t =
  let func_name = LeftValue.name func.left in
  let l_func = State.add_function_node state func_cid func_name in
  Store.replace state.store func_name (Node.Set.singleton l_func);
  let this_cid = newcid func.left in
  let state' = { state with curr_parent = Some l_func } in
  let l_this = State.add_parameter_node state' this_cid "this" in
  State.add_parameter_edge state' l_func l_this 0;
  Fun.flip List.iteri func.params (fun idx param ->
      let idx' = idx + 1 in
      let param_cid = newcid param in
      let param_name = Identifier.name param in
      let l_param = State.add_parameter_node state' param_cid param_name in
      State.add_parameter_edge state' l_func l_param idx' );
  state

and build_function_declaration_unfold (state : State.t)
    (func : 'm FunctionDefinition.t) (cid : cid) : State.t =
  let func_name = LeftValue.name func.left in
  let l_func = State.add_function_node state cid func_name in
  Store.replace state.store func_name (Node.Set.singleton l_func);
  Pcontext.func_decl state.pcontext l_func state.curr_floc func state.store;
  state

and build_function_definition (state : State.t) (func : 'm FunctionDefinition.t)
    (cid : cid) : State.t =
  ( if opaque_function_eval state.env then build_function_definition_opaque
    else build_function_definition_hoisted )
    state func cid

and build_function_definition_opaque (state : State.t)
    (func : 'm FunctionDefinition.t) (cid : cid) : State.t =
  let state' = build_function_definition_hoisted state func cid in
  let l_func = State.get_node state cid in
  let store' = Store.copy state'.store in
  let state'' = { state' with store = store'; curr_parent = Some l_func } in
  let state''' = initialize_hoisted_functions state'' func.body in
  let this_cid = newcid func.left in
  let l_this = State.get_node state this_cid in
  Store.replace state'''.store "this" (Node.Set.singleton l_this);
  Fun.flip List.iteri func.params (fun _ param ->
      let param_cid = newcid param in
      let param_name = Identifier.name param in
      let l_param = State.get_node state param_cid in
      Store.replace state'''.store param_name (Node.Set.singleton l_param) );
  ignore (build_sequence state''' func.body);
  state

and build_function_definition_hoisted (state : State.t)
    (func : 'm FunctionDefinition.t) (cid : cid) : State.t =
  if FunctionHoisting.hoisted func.hoisted then state
  else build_function_declaration state func cid

and build_exported_function (state : State.t) (l_func : Node.t) : State.t =
  match Pcontext.func state.pcontext l_func with
  | None -> state
  | Some { floc; func; eval_store; _ } ->
    let store = Store.copy eval_store in
    let curr_floc = floc in
    let curr_stack = l_func :: state.curr_stack in
    let curr_parent = Some l_func in
    let state' = { state with store; curr_floc; curr_stack; curr_parent } in
    let state'' = initialize_hoisted_functions state' func.body in
    let this_cid = newcid func.left in
    let l_this = State.add_parameter_node state'' this_cid "this" in
    State.add_parameter_edge state'' l_func l_this 0;
    Store.replace state''.store "this" (Node.Set.singleton l_this);
    Fun.flip List.iteri func.params (fun idx param ->
        let idx' = idx + 1 in
        let param_cid = newcid param in
        let name = Identifier.name param in
        let l_param = State.add_parameter_node state'' param_cid name in
        State.add_parameter_edge state'' l_func l_param idx';
        Store.replace state''.store name (Node.Set.singleton l_param) );
    build_sequence state'' func.body

and build_loop_break (state : State.t) (_label : 'm Identifier.t option) :
    State.t =
  (* TODO: implement flow control to the builder *)
  (* TODO: implement labels on the loop breaks *)
  state

and build_return (state : State.t) (arg : 'm Expression.t option) : State.t =
  (* TODO: implement flow control to the builder *)
  (* the return statement should prevent all code afterwards from being analyzed *)
  let ls_arg = Option.map (eval_expr state) arg in
  match (state.curr_parent, ls_arg) with
  | (None, _) | (Some _, None) -> state
  | (Some l_func, Some ls_arg') ->
    if opaque_function_eval state.env then
      Node.Set.iter (State.add_return_edge state l_func) ls_arg';
    let curr_return = Node.Set.union state.curr_return ls_arg' in
    { state with curr_return }

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
  let state' = build_scoped_sequence state body in
  let state'' = build_scoped_sequence_opt state' handler' in
  let state''' = build_scoped_sequence_opt state'' finalizer in
  state'''

and build_with (state : State.t) (_expr : 'm Expression.t)
    (body : 'm Statement.t list) : State.t =
  (* TODO: implement the with construct *)
  (* extend the current scope with the statement's expression *)
  build_scoped_sequence state body

and build_labeled (state : State.t) (_label : 'm Identifier.t)
    (body : 'm Statement.t list) : State.t =
  (* TODO: implement the labeled construct *)
  (* store the labels in the environment, and then use them in the break and continue statements *)
  build_scoped_sequence state body

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
    build_new_call state left callee args (newcid stmt)
  | `FunctionCall { left; callee; args } ->
    build_function_call state left callee args (newcid stmt)
  | `StaticMethodCall { left; obj; prop; args } ->
    build_static_method_call state left obj prop args (newcid stmt)
  | `DynamicMethodCall { left; obj; prop; args } ->
    build_dynamic_method_call state left obj prop args (newcid stmt)
  | `FunctionDefinition func ->
    build_function_definition state func (newcid stmt)
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

and build_scoped_sequence (state : State.t) (stmts : 'm Statement.t list) :
    State.t =
  let state' = initialize_hoisted_functions state stmts in
  build_sequence state' stmts

and build_scoped_sequence_opt (state : State.t)
    (stmts : 'm Statement.t list option) : State.t =
  Option.fold ~none:state ~some:(build_scoped_sequence state) stmts

and build_file (state : State.t) (file : 'm File.t) (main : bool)
    (l_parent : Node.t option) : State.t =
  let state' = initialize_file state file main l_parent in
  let state'' = build_sequence state' file.body in
  Pcontext.file_built state''.pcontext file.path;
  state''.env.cb_mdg_file file.mrel;
  state''

module ExtendedMdg = struct
  type t =
    { mdg : Mdg.t
    ; exported : Exported.t option
    ; tainted : Tainted.t
    }

  let compute_exported_analysis (state : State.t) : Exported.t option =
    if state.env.run_exported_analysis then
      let export_f =
        if opaque_function_eval state.env then Exported.compute_from_graph
        else Exported.compute_and_unfold build_exported_function in
      Some (export_f state)
    else None

  let compute_tainted_analysis (state : State.t) (exported : Exported.t option)
      : Tainted.t =
    match (state.env.run_tainted_analysis, exported) with
    | (true, Some exported') -> Tainted.compute state exported'
    | _ -> Tainted.none ()

  let compute_cleaner_analysis (state : State.t) : unit =
    if state.env.run_cleaner_analysis then Cleaner.compute state

  let compute_analyses (state : State.t) : t =
    let mdg = state.mdg in
    let exported = compute_exported_analysis state in
    let tainted = compute_tainted_analysis state exported in
    compute_cleaner_analysis state;
    { mdg; exported; tainted }
end

let build_program (env : State.Env.t) (tconf : Taint_config.t) (prog : 'm Prog.t)
    : ExtendedMdg.t =
  let main = Prog.main prog in
  let state = initialize_builder env tconf prog in
  let state' = build_file state main true None in
  ExtendedMdg.compute_analyses state'
