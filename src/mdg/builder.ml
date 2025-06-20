open Graphjs_ast
open Metadata

type cid = Allocator.cid

let newcid (el : ('a, Region.t) Metadata.t) : cid = Allocator.cid el
let offset (cid : cid) (ofs : int) : cid = Allocator.offset cid ofs

let create_literal (literal : LiteralValue.t) : Literal.t =
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
  Node.Set.map_flat (Fun.flip (Mdg.object_lookup state.mdg) prop) ls_obj

let new_object_version (state : State.t) (name : string) (ls_obj : Node.Set.t)
    (cid : cid) : Node.t =
  let l_funcs = Node.Set.filter Node.is_function ls_obj in
  if Node.Set.cardinal l_funcs == 1 then (
    let l_func = Node.Set.choose l_funcs in
    let func = Pcontext.func state.pcontext l_func in
    let l_func' = State.add_function_node state cid name in
    Option.iter (Pcontext.set_func state.pcontext l_func') func;
    l_func' )
  else State.add_object_node state cid name

let add_static_orig_object_property (state : State.t) (name : string)
    (ls_obj : Node.Set.t) (prop : Property.t) (cid : cid) : unit =
  Fun.flip Node.Set.iter ls_obj (fun l_obj ->
      let ls_orig = Mdg.object_orig_versions state.mdg l_obj in
      Fun.flip Node.Set.iter ls_orig (fun l_orig ->
          if not (Mdg.has_property state.mdg l_orig prop) then
            let l_prop = State.add_blank_node state cid name in
            State.add_property_edge state l_orig l_prop prop ) )

let add_dynamic_orig_object_property (state : State.t) (name : string)
    (ls_obj : Node.Set.t) (ls_prop : Node.Set.t) (cid : cid) : unit =
  let prop = Property.Dynamic in
  let set_deps_f l_prop = Fun.flip (State.add_dependency_edge state) l_prop in
  Fun.flip Node.Set.iter ls_obj (fun l_obj ->
      let ls_orig = Mdg.object_orig_versions state.mdg l_obj in
      Fun.flip Node.Set.iter ls_orig (fun l_orig ->
          match Mdg.get_property state.mdg l_orig prop with
          | [] ->
            let l_prop = State.add_blank_node state cid name in
            State.add_property_edge state l_orig l_prop prop;
            Node.Set.iter (set_deps_f l_prop) ls_prop
          | l_prop :: _ -> Node.Set.iter (set_deps_f l_prop) ls_prop ) )

let static_strong_nv (state : State.t) (name : string) (l_obj : Node.t)
    (prop : Property.t) (cid : cid) : Node.Set.t =
  let l_new = new_object_version state name (Node.Set.singleton l_obj) cid in
  State.add_version_edge state l_obj l_new prop;
  Store.strong_update state.store l_obj l_new;
  Node.Set.singleton l_new

let static_weak_nv (state : State.t) (name : string) (ls_obj : Node.Set.t)
    (prop : Property.t) (cid : cid) : Node.Set.t =
  let l_new = new_object_version state name ls_obj cid in
  Fun.flip Node.Set.iter ls_obj (fun l_obj ->
      let ls_new = Node.Set.of_list [ l_obj; l_new ] in
      State.add_version_edge state l_obj l_new prop;
      Store.weak_update state.store l_obj ls_new );
  let ls_node = Node.Set.singleton l_new in
  Store.write state.store name ls_node;
  ls_node

let dynamic_strong_nv (state : State.t) (name : string) (l_obj : Node.t)
    (ls_prop : Node.Set.t) (cid : cid) : Node.Set.t =
  let l_new = new_object_version state name (Node.Set.singleton l_obj) cid in
  State.add_version_edge state l_obj l_new Property.Dynamic;
  Node.Set.iter (Fun.flip (State.add_dependency_edge state) l_new) ls_prop;
  Store.strong_update state.store l_obj l_new;
  Node.Set.singleton l_new

let dynamic_weak_nv (state : State.t) (name : string) (ls_obj : Node.Set.t)
    (ls_prop : Node.Set.t) (cid : cid) : Node.Set.t =
  let prop = Property.Dynamic in
  let l_new = new_object_version state name ls_obj cid in
  Fun.flip Node.Set.iter ls_obj (fun l_obj ->
      let ls_new = Node.Set.of_list [ l_obj; l_new ] in
      State.add_version_edge state l_obj l_new prop;
      Store.weak_update state.store l_obj ls_new );
  Node.Set.iter (Fun.flip (State.add_dependency_edge state) l_new) ls_prop;
  let ls_node = Node.Set.singleton l_new in
  Store.write state.store name ls_node;
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
    (retn_name : string) (call_cid : cid) (retn_cid : cid) (l_func : Node.t)
    (ls_args : Node.Set.t list) : State.t * Node.t * Node.t =
  let l_call = State.add_call_node state call_cid call_name in
  let l_retn = State.add_return_node state retn_cid retn_name in
  let add_arg_f = Fun.flip2 (State.add_argument_edge state) l_call in
  State.add_caller_edge state l_call l_func;
  State.add_dependency_edge state l_call l_retn;
  Fun.flip List.iteri ls_args (fun idx ls_arg ->
      Node.Set.iter (add_arg_f idx) ls_arg );
  (state, l_call, l_retn)

let call_interceptor (state : State.t) (left : 'm LeftValue.t)
    (args : 'm Expression.t list) (call_name : string)
    (call_cid : Allocator.cid) ?(prop : Property.t option)
    (ls_func : Node.Set.t) (ls_args : Node.Set.t list) : State.t =
  let function_f = State.get_function_interceptor state in
  let method_f = State.get_method_interceptor state in
  Fun.flip2 Node.Set.fold ls_func state (fun l_func state ->
      match (Option.bind prop (method_f l_func ls_args), function_f l_func) with
      | (Some f, _) -> f state left args call_name call_cid l_func ls_args
      | (None, Some f) -> f state left args call_name call_cid l_func ls_args
      | (None, None) -> state )

let connect_prototype_properties (state : State.t) (l_func : Node.t)
    (l_this : Node.t) : unit =
  let ls_proto = Mdg.object_static_lookup state.mdg l_func "prototype" in
  Fun.flip Node.Set.iter ls_proto (fun l_proto ->
      let props = Mdg.object_dynamic_property_lookup state.mdg l_proto in
      Fun.flip List.iter props (fun (prop, ls_prop) ->
          Fun.flip Node.Set.iter ls_prop (fun l_prop ->
              State.add_property_edge state l_this l_prop prop ) ) )

let rec eval_expr (state : State.t) (expr : 'm Expression.t) : Node.Set.t =
  match expr.el with
  | `LiteralValue literal -> eval_literal_expr state literal (newcid expr)
  | `TemplateLiteral { exprs; _ } -> eval_template_literal_expr state expr exprs
  | `Identifier id -> eval_store_expr state (Identifier.name' id) (newcid expr)
  | `This _ -> eval_store_expr state "this" (newcid expr)

and eval_literal_expr (state : State.t) (literal : LiteralValue.t) (cid : cid) :
    Node.Set.t =
  let literal' = create_literal literal in
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
  match Store.read state.store id with
  | None -> Node.Set.singleton (State.add_blank_node state cid id)
  | Some ls_expr -> ls_expr

let unfoldable_function (state : State.t) (l_func : Node.t) : bool =
  Node.is_function l_func
  && List.count (Node.equal l_func) state.curr_stack < state.env.unfold_depth

let unfoldable_callbacks (state : State.t) (ls_args : Node.Set.t list) :
    Node.Set.t =
  Fun.flip2 List.fold_right ls_args Node.Set.empty (fun ls_arg acc ->
      Fun.flip2 Node.Set.fold ls_arg acc (fun l_arg acc ->
          if unfoldable_function state l_arg then Node.Set.add l_arg acc
          else acc ) )

let rec unfold_function_call (state : State.t) (call_name : string)
    (retn_name : string) (call_cid : cid) (retn_cid : cid) (new_ : bool)
    (ls_func : Node.Set.t) (ls_args : Node.Set.t list) : State.t * Node.Set.t =
  Fun.flip2 Node.Set.fold ls_func (state, Node.Set.empty)
    (fun l_func (state, ls_retn) ->
      let unfoldable = unfoldable_function state l_func in
      let func = Pcontext.func state.pcontext l_func in
      match (unfoldable, func) with
      | (false, _) | (true, None) ->
        unfold_callbacks state (List.tl ls_args);
        let call_f = add_function_call state call_name retn_name in
        let (state', _, l_retn) = call_f call_cid retn_cid l_func ls_args in
        let ls_retn' = Node.Set.add l_retn ls_retn in
        (state', ls_retn')
      | (true, Some { floc; func; store; _ }) ->
        let curr_floc = floc in
        let curr_stack = l_func :: state.curr_stack in
        let curr_parent = Some l_func in
        let state' = State.extend_func state store in
        let state'' = { state' with curr_floc; curr_stack; curr_parent } in
        let this_f = unfold_function_this state'' retn_name retn_cid in
        let ls_this = this_f new_ func l_func (List.hd ls_args) in
        Store.set state''.store "this" ls_this;
        Fun.flip List.iteri (List.tl ls_args) (fun idx ls_arg ->
            Fun.flip Option.iter (List.nth_opt func.params idx) (fun param ->
                let param_name = Identifier.name param in
                Store.set state''.store param_name ls_arg ) );
        let state''' = build_sequence state'' func.body in
        let ls_retn' = unfold_function_return state''' new_ l_func ls_this in
        let ls_retn' = Node.Set.union ls_retn ls_retn' in
        let state'''' = State.reduce_func state state''' in
        (state'''', ls_retn') )

and unfold_function_this (state : State.t) (retn_name : string) (retn_cid : cid)
    (new_ : bool) (func : 'm FunctionDefinition.t) (l_func : Node.t)
    (ls_this : Node.Set.t) : Node.Set.t =
  if new_ then
    let l_new = State.add_object_node state retn_cid retn_name in
    Node.Set.add l_new ls_this
  else if Node.Set.is_empty ls_this then (
    let this_cid = newcid func.left in
    let l_this = State.add_parameter_node state this_cid "this" in
    State.add_parameter_edge state l_func l_this 0;
    Node.Set.singleton l_this )
  else ls_this

and unfold_function_return (state : State.t) (new_ : bool) (l_func : Node.t)
    (ls_this : Node.Set.t) : Node.Set.t =
  if new_ then (
    let l_this = Node.Set.choose ls_this in
    connect_prototype_properties state l_func l_this;
    Node.Set.map_flat (Mdg.object_tail_versions state.mdg) ls_this )
  else state.curr_return

and unfold_callbacks (state : State.t) (ls_args : Node.Set.t list) : unit =
  let ls_callbacks = unfoldable_callbacks state ls_args in
  let ls_this = Store.read state.store "this" in
  let ls_this' = Option.value ~default:Node.Set.empty ls_this in
  Fun.flip Node.Set.iter ls_callbacks (fun l_func ->
      ignore (unfold_entry_function state l_func ls_this' false) )

and unfold_entry_function (state : State.t) (l_func : Node.t)
    (ls_this : Node.Set.t) (new_ : bool) : State.t * Node.Set.t =
  match Pcontext.func state.pcontext l_func with
  | None -> (state, Node.Set.empty)
  | Some { floc; func; store; _ } ->
    let retn_name = Node.name l_func in
    let retn_cid = newcid func.left in
    let curr_floc = floc in
    let curr_stack = l_func :: state.curr_stack in
    let curr_parent = Some l_func in
    let state' = State.extend_func state store in
    let state'' = { state' with curr_floc; curr_stack; curr_parent } in
    let this_f = unfold_function_this state'' retn_name retn_cid in
    let ls_this' = this_f new_ func l_func ls_this in
    Store.set state''.store "this" ls_this';
    Fun.flip List.iteri func.params (fun idx param ->
        let param_cid = newcid param in
        let param_name = Identifier.name param in
        let l_param = State.add_parameter_node state'' param_cid param_name in
        State.add_parameter_edge state'' l_func l_param (idx + 1);
        Store.set state''.store param_name (Node.Set.singleton l_param) );
    let state''' = build_sequence state'' func.body in
    let ls_retn = unfold_function_return state''' new_ l_func ls_this' in
    let ls_retn' = Node.Set.union state'''.curr_return ls_retn in
    let state'''' = State.reduce_func state state''' in
    (state'''', ls_retn')

and build_vardecl (state : State.t) (left : 'm LeftValue.t) : State.t =
  let name = LeftValue.name left in
  let kind = LeftValue.kind left in
  Store.write state.store name ~kind Node.Set.empty;
  state

and build_assignment (state : State.t) (left : 'm LeftValue.t)
    (right : 'm Expression.t) : State.t =
  let name = LeftValue.name left in
  let kind = LeftValue.kind left in
  let ls_right = eval_expr state right in
  Store.write state.store name ~kind ls_right;
  state

and build_new (state : State.t) (left : 'm LeftValue.t) (cid : cid) : State.t =
  let name = LeftValue.name left in
  let kind = LeftValue.kind left in
  let l_obj = State.add_object_node state cid name in
  Store.write state.store name ~kind (Node.Set.singleton l_obj);
  state

and build_unopt (state : State.t) (left : 'm LeftValue.t)
    (arg : 'm Expression.t) (cid : cid) : State.t =
  let name = LeftValue.name left in
  let kind = LeftValue.kind left in
  let ls_arg = eval_expr state arg in
  let l_unopt = State.add_object_node state cid name in
  Store.write state.store name ~kind (Node.Set.singleton l_unopt);
  Node.Set.iter (Fun.flip (State.add_dependency_edge state) l_unopt) ls_arg;
  state

and build_binopt (state : State.t) (left : 'm LeftValue.t)
    (arg1 : 'm Expression.t) (arg2 : 'm Expression.t) (cid : cid) : State.t =
  let name = LeftValue.name left in
  let kind = LeftValue.kind left in
  let ls_arg1 = eval_expr state arg1 in
  let ls_arg2 = eval_expr state arg2 in
  let l_binopt = State.add_object_node state cid name in
  Store.write state.store name ~kind (Node.Set.singleton l_binopt);
  Node.Set.iter (Fun.flip (State.add_dependency_edge state) l_binopt) ls_arg1;
  Node.Set.iter (Fun.flip (State.add_dependency_edge state) l_binopt) ls_arg2;
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
  let kind = LeftValue.kind left in
  let prop = Property.Static (Prop.name prop) in
  let ls_obj = eval_expr state obj in
  let prop_name = object_property_name ls_obj obj prop in
  add_static_orig_object_property state prop_name ls_obj prop cid;
  let ls_lookup = lookup_property state ls_obj prop in
  Store.write state.store name ~kind ls_lookup;
  state

and build_dynamic_lookup (state : State.t) (left : 'm LeftValue.t)
    (obj : 'm Expression.t) (prop : 'm Expression.t) (cid : cid) : State.t =
  let name = LeftValue.name left in
  let kind = LeftValue.kind left in
  let prop' = Property.Dynamic in
  let ls_obj = eval_expr state obj in
  let ls_prop = eval_expr state prop in
  let prop_name = object_property_name ls_obj obj prop' in
  add_dynamic_orig_object_property state prop_name ls_obj ls_prop cid;
  let ls_lookup = lookup_property state ls_obj prop' in
  Store.write state.store name ~kind ls_lookup;
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
    (callee : 'm Identifier.t) (args : 'm Expression.t list) (call_cid : cid) :
    State.t =
  let retn_cid = newcid left in
  let call_name = Identifier.name callee in
  let retn_name = LeftValue.name left in
  let retn_kind = LeftValue.kind left in
  let ls_func = eval_store_expr state call_name (newcid callee) in
  let ls_args = List.map (eval_expr state) args in
  let ls_args' = Node.Set.empty :: ls_args in
  let call_f = unfold_function_call state call_name retn_name in
  let (state', ls_retn) = call_f call_cid retn_cid true ls_func ls_args' in
  Store.write state'.store retn_name ~kind:retn_kind ls_retn;
  call_interceptor state' left args call_name call_cid ls_func ls_args'

and build_function_call (state : State.t) (left : 'm LeftValue.t)
    (callee : 'm Identifier.t) (args : 'm Expression.t list) (call_cid : cid) :
    State.t =
  let retn_cid = newcid left in
  let call_name = Identifier.name callee in
  let retn_name = LeftValue.name left in
  let retn_kind = LeftValue.kind left in
  let ls_func = eval_store_expr state call_name (newcid callee) in
  let ls_args = List.map (eval_expr state) args in
  let ls_args' = Node.Set.empty :: ls_args in
  let call_f = unfold_function_call state call_name retn_name in
  let (state', ls_retn) = call_f call_cid retn_cid false ls_func ls_args' in
  Store.write state'.store retn_name ~kind:retn_kind ls_retn;
  call_interceptor state' left args call_name call_cid ls_func ls_args'

and build_static_method_call (state : State.t) (left : 'm LeftValue.t)
    (obj : 'm Expression.t) (prop' : 'm Prop.t) (args : 'm Expression.t list)
    (call_cid : cid) : State.t =
  let prop_cid = newcid prop' in
  let retn_cid = newcid left in
  let retn_name = LeftValue.name left in
  let retn_kind = LeftValue.kind left in
  let prop = Property.Static (Prop.str prop') in
  let ls_obj = eval_expr state obj in
  let ls_args = List.map (eval_expr state) args in
  let ls_args' = ls_obj :: ls_args in
  let call_name = object_property_name ls_obj obj prop in
  add_static_orig_object_property state call_name ls_obj prop prop_cid;
  let ls_func = lookup_property state ls_obj prop in
  let call_f = unfold_function_call state call_name retn_name in
  let (state', ls_retn) = call_f call_cid retn_cid false ls_func ls_args' in
  Store.write state'.store retn_name ~kind:retn_kind ls_retn;
  call_interceptor state' left args call_name call_cid ~prop ls_func ls_args'

and build_dynamic_method_call (state : State.t) (left : 'm LeftValue.t)
    (obj : 'm Expression.t) (prop' : 'm Expression.t)
    (args : 'm Expression.t list) (call_cid : cid) : State.t =
  let prop_cid = newcid prop' in
  let retn_cid = newcid left in
  let retn_name = LeftValue.name left in
  let retn_kind = LeftValue.kind left in
  let prop = Property.Dynamic in
  let ls_obj = eval_expr state obj in
  let ls_prop = eval_expr state prop' in
  let ls_args = List.map (eval_expr state) args in
  let ls_args' = ls_obj :: ls_args in
  let call_name = object_property_name ls_obj obj prop in
  add_dynamic_orig_object_property state call_name ls_obj ls_prop prop_cid;
  let ls_func = lookup_property state ls_obj prop in
  let call_f = unfold_function_call state call_name retn_name in
  let (state', ls_retn) = call_f call_cid retn_cid false ls_func ls_args' in
  Store.write state'.store retn_name ~kind:retn_kind ls_retn;
  call_interceptor state' left args call_name call_cid ~prop ls_func ls_args'

and build_if (state : State.t) (consequent : 'm Statement.t list)
    (alternate : 'm Statement.t list option) : State.t =
  match alternate with
  | None ->
    let state' = State.extend_block state in
    let state'' = build_sequence state' consequent in
    State.reduce_option state state''
  | Some alternate' ->
    let state1 = State.extend_block state in
    let state2 = State.extend_block state in
    let state1' = build_sequence state1 consequent in
    let state2' = build_sequence state2 alternate' in
    State.reduce_branch state state1' state2'

and build_switch (state : State.t) (cases : 'm SwitchCase.t list) : State.t =
  (* TODO: implement flow control to the builder *)
  (* this statement can be improved by reasoning about the control flow of the break and return statements *)
  (* additionally, we should account for the initial states of the switch not being processed *)
  List.map SwitchCase.body cases |> List.fold_left build_sequence state

and build_loop (state : State.t) (body : 'm Statement.t list) : State.t =
  let rec loop_f state store =
    let state' = build_sequence state body in
    if Store.equal_flat store state'.store then state'
    else loop_f state' (Store.copy_flat state'.store) in
  let state' = State.extend_block state in
  let state'' = loop_f state' (Store.copy_flat state'.store) in
  State.reduce_option state state''

and build_forin (state : State.t) (left : 'm LeftValue.t)
    (right : 'm Expression.t) (body : 'm Statement.t list) : State.t =
  (* TODO: improve the assignment in the forin statement *)
  (* we treat this assignment as a lookup on all properties of the expression *)
  (* the left value should depend of all the properties of the right value *)
  let name = LeftValue.name left in
  let kind = LeftValue.kind left in
  let l_left = State.add_object_node state (newcid left) name in
  let ls_right = eval_expr state right in
  Store.write state.store name ~kind (Node.Set.singleton l_left);
  Node.Set.iter (Fun.flip (State.add_dependency_edge state) l_left) ls_right;
  build_loop state body

and build_forof (state : State.t) (left : 'm LeftValue.t)
    (right : 'm Expression.t) (body : 'm Statement.t list) : State.t =
  (* TODO: improve the assignment in the forof statement *)
  (* we treat this assignment as a lookup on all properties of the expression *)
  (* the left value should depend of all the properties of the right value *)
  let name = LeftValue.name left in
  let kind = LeftValue.kind left in
  let l_left = State.add_object_node state (newcid left) name in
  let ls_right = eval_expr state right in
  Store.write state.store name ~kind (Node.Set.singleton l_left);
  Node.Set.iter (Fun.flip (State.add_dependency_edge state) l_left) ls_right;
  build_loop state body

and build_function_declaration (state : State.t)
    (func : 'm FunctionDefinition.t) (cid : cid) : State.t =
  let name = LeftValue.name func.left in
  let kind = LeftValue.kind func.left in
  let l_func = State.add_function_node state cid name in
  Store.write state.store name ~kind (Node.Set.singleton l_func);
  Pcontext.declare_func state.pcontext l_func state.curr_floc func state.store;
  state

and build_function_definition (state : State.t) (func : 'm FunctionDefinition.t)
    (cid : cid) : State.t =
  if FunctionHoisting.hoisted func.hoisted then state
  else build_function_declaration state func cid

and build_hoisted_functions (state : State.t) (stmts : 'm Statement.t list) :
    State.t =
  Fun.flip2 List.fold_left state stmts (fun state stmt ->
      match stmt.el with
      | `FunctionDefinition func when FunctionDefinition.is_hoisted func ->
        build_function_declaration state func (newcid stmt)
      | _ -> state )

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

and build_export_decl (state : State.t) (specifier : 'm ExportDecl.specifier)
    (cid : cid) : State.t =
  (* TODO: implement the other types of export *)
  match specifier with
  | Default expr ->
    let (mrel, main) = (state.curr_floc.mrel, state.curr_floc.main) in
    let mrel' = if main then None else Some mrel in
    let module_jslib = Jslib.resolve_name mrel' "module" in
    let l_obj = Jslib.find_node state.mdg state.jslib module_jslib in
    let ls_obj = Mdg.object_tail_versions state.mdg l_obj in
    let prop = Property.Static "exports" in
    let ls_export = eval_expr state expr in
    let ls_new = add_static_object_version state "module" ls_obj prop cid in
    Fun.flip Node.Set.iter ls_new (fun l_new ->
        Fun.flip Node.Set.iter ls_export (fun l_export ->
            State.add_property_edge state l_new l_export prop ) );
    state
  | _ -> state

and build_statement (state : State.t) (stmt : 'm Statement.t) : State.t =
  match stmt.el with
  | `ExprStmt _ -> state
  | `VarDecl left -> build_vardecl state (left @> stmt.md)
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
  | `ForIn { left; right; body; _ } -> build_forin state left right body
  | `ForOf { left; right; body; _ } -> build_forof state left right body
  | `Break { label } -> build_loop_break state label
  | `Continue { label } -> build_loop_break state label
  | `Return { arg } -> build_return state arg
  | `Throw { arg } -> build_throw state arg
  | `Try { body; handler; finalizer } -> build_try state body handler finalizer
  | `With { expr; body } -> build_with state expr body
  | `Labeled { label; body } -> build_labeled state label body
  | `Debugger _ -> state
  | `ImportDecl _ -> state
  | `ExportDecl { specifier; _ } ->
    build_export_decl state specifier (newcid stmt)

and build_sequence (state : State.t) (stmts : 'm Statement.t list) : State.t =
  let state' = build_hoisted_functions state stmts in
  List.fold_left build_statement state' stmts

and build_sequence_opt (state : State.t) (stmts : 'm Statement.t list option) :
    State.t =
  Option.fold ~none:state ~some:(build_sequence state) stmts

and build_file (state : State.t) (file : 'm File.t) (main : bool)
    (l_parent : Node.t option) : State.t =
  let state' = State.initialize state file.path file.mrel main l_parent in
  let state'' = build_sequence state' file.body in
  Pcontext.build_file state''.pcontext file.path;
  state''.env.cb_mdg_file file.mrel;
  state''

module ExtendedMdg = struct
  type t =
    { mdg : Mdg.t
    ; exported : Exported.t
    ; tainted : Tainted.t
    }

  let compute_exported_analysis (state : State.t) : Exported.t =
    let unfold_f = unfold_entry_function in
    if not state.env.run_exported_analysis then Exported.none ()
    else Exported.compute unfold_f state

  let compute_tainted_analysis (state : State.t) (jsmodel : Jsmodel.t)
      (exported : Exported.t) : Tainted.t =
    if not state.env.run_tainted_analysis then Tainted.none ()
    else Tainted.compute state jsmodel exported

  let compute_cleaner_analysis (state : State.t) : unit =
    if state.env.run_cleaner_analysis then Cleaner.compute state

  let compute_analyses (state : State.t) (jsmodel : Jsmodel.t) : t =
    let mdg = state.mdg in
    let exported = compute_exported_analysis state in
    let tainted = compute_tainted_analysis state jsmodel exported in
    compute_cleaner_analysis state;
    { mdg; exported; tainted }
end

let reset_generators (env : State.Env.t) : unit =
  Store.reset_generator ();
  if env.reset_locations then Location.reset_generator ()

let build_program (env : State.Env.t) (jsmodel : Jsmodel.t) (prog : 'm Prog.t) :
    ExtendedMdg.t =
  reset_generators env;
  let main = Prog.main prog in
  let state = State.create env jsmodel prog in
  let cbs_builder = Interceptor.cbs_builder build_file unfold_function_call in
  Interceptor.initialize state cbs_builder;
  let state' = build_file state main true None in
  ExtendedMdg.compute_analyses state' jsmodel
