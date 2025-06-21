open Graphjs_ast

type cb_build_file =
  State.t -> Region.t File.t -> bool -> Node.t option -> State.t

type cb_unfold_function =
     State.t
  -> string
  -> string
  -> Allocator.cid
  -> Allocator.cid
  -> bool
  -> Node.Set.t
  -> Node.Set.t list
  -> State.t * Node.Set.t

type cbs_builder =
  { build_file : cb_build_file
  ; unfold_function : cb_unfold_function
  }

let cbs_builder (build_file : cb_build_file)
    (unfold_function : cb_unfold_function) : cbs_builder =
  { build_file; unfold_function }

module RequireInterceptor = struct
  let get_module_path (state : State.t) (ls_args : Node.Set.t list) :
      Fpath.t option =
    let root = fst (Fpath.split_base state.curr_floc.path) in
    match ls_args with
    | [ _; ls_name ] when Node.Set.cardinal ls_name == 1 -> (
      match (Node.Set.choose ls_name).kind with
      | Literal { kind = String; raw } ->
        let name = String.sub raw 1 (String.length raw - 2) in
        Some Fpath.(root // v name |> rem_ext |> normalize)
      | _ -> None )
    | _ -> None

  let process_module (cb_build_file : cb_build_file) (state : State.t)
      (retn_cid : Allocator.cid) (mrel : Fpath.t) : Node.Set.t =
    match Pcontext.file state.pcontext mrel with
    | None ->
      let State.{ mdg; pcontext; jslib; npmlib; _ } = state in
      let name = Fpath.filename mrel in
      let l_npmlib = Npmlib.resolve mdg pcontext jslib npmlib name in
      Node.Set.singleton l_npmlib
    | Some file when file.built ->
      Jslib.exported_object ~mrel:file.file.mrel state.mdg state.jslib
    | Some file ->
      let name = Fpath.to_string file.file.mrel in
      let l_module = State.add_module_node state retn_cid name in
      let state' = cb_build_file state file.file false (Some l_module) in
      Jslib.exported_object ~mrel:file.file.mrel state'.mdg state.jslib

  let run (cb_build_file : cb_build_file) (state : State.t)
      (left : 'm LeftValue.t) (_ : 'm Expression.t list) (_ : string)
      (_ : Allocator.cid) (_ : Node.t) (ls_args : Node.Set.t list) : State.t =
    match get_module_path state ls_args with
    | None -> state
    | Some mrel ->
      let retn_cid = Allocator.offset (Allocator.cid left) 1 in
      let name = LeftValue.name left in
      let kind = LeftValue.kind left in
      let ls_exports = process_module cb_build_file state retn_cid mrel in
      Store.write ~kind state.store name ls_exports;
      state
end

module FunctionBindInterceptor = struct
  let matcher (_ : State.t) (_ : Node.t) (ls_args : Node.Set.t list)
      (prop : Property.t) : bool =
    if Property.equal (Static "bind") prop then
      Node.Set.for_all Node.is_function (List.hd ls_args)
    else false

  let get_this_function (state : State.t) (ls_args : Node.Set.t list) :
      'm Pcontext.func option =
    let ls_this = List.hd ls_args in
    if Node.Set.cardinal ls_this == 1 then
      Pcontext.func state.pcontext (Node.Set.choose ls_this)
    else None

  let run (state : State.t) (left : 'm LeftValue.t) (_ : 'm Expression.t list)
      (_ : string) (_ : Allocator.cid) (l_func : Node.t)
      (ls_args : Node.Set.t list) : State.t =
    let func = get_this_function state ls_args in
    Fun.flip Option.iter func (fun { func; store; _ } ->
        let name = LeftValue.name left in
        let kind = LeftValue.kind left in
        let func_name = Node.name l_func in
        let bind_cid = Allocator.offset (Allocator.cid left) 1 in
        let l_bind = State.add_function_node state bind_cid func_name in
        Store.write ~kind state.store name (Node.Set.singleton l_bind);
        let store' = Store.copy store in
        Pcontext.declare_func state.pcontext l_bind state.curr_floc func store';
        Fun.flip List.iteri ls_args (fun idx ls_arg ->
            Fun.flip Option.iter (List.nth_opt func.params idx) (fun param ->
                let param_name = Identifier.name param in
                Store.set store param_name ls_arg ) ) );
    state
end

module FunctionCallInterceptor = struct
  let matcher (_ : State.t) (_ : Node.t) (ls_args : Node.Set.t list)
      (prop : Property.t) : bool =
    if Property.equal (Static "call") prop then
      Node.Set.for_all Node.is_function (List.hd ls_args)
    else false

  let run (cb_unfold_function : cb_unfold_function) (state : State.t)
      (left : 'm LeftValue.t) (_ : 'm Expression.t list) (call_name : string)
      (call_cid : Allocator.cid) (_ : Node.t) (ls_args : Node.Set.t list) :
      State.t =
    let retn_cid = Allocator.cid left in
    let retn_name = LeftValue.name left in
    let ls_func = List.hd ls_args in
    let ls_args' = List.tl ls_args in
    let unfold_f = cb_unfold_function state call_name retn_name in
    unfold_f call_cid retn_cid false ls_func ls_args' |> fst
end

module PromiseInterceptor = struct
  let run (state : State.t) (left : 'm LeftValue.t) (_ : 'm Expression.t list)
      (_ : string) (_ : Allocator.cid) (l_func : Node.t) (_ : Node.Set.t list) :
      State.t =
    let l_retn = State.get_node state (Allocator.cid left) in
    State.add_meta_edge state l_retn l_func "cons";
    state
end

module PromiseThenInterceptor = struct
  let matcher (state : State.t) (_ : Node.t) (ls_args : Node.Set.t list)
      (prop : Property.t) : bool =
    if Property.equal (Property.Static "then") prop then
      Fun.flip Node.Set.exists (List.hd ls_args) (fun l_promise ->
          let l_builtin = Jslib.find_node state.mdg state.jslib "Promise" in
          let ls_orig = Mdg.object_orig_versions state.mdg l_promise in
          Fun.flip Node.Set.exists ls_orig (fun l_orig ->
              Mdg.has_metadata state.mdg l_orig l_builtin "cons" ) )
    else false

  let propagate_metadata (state : State.t) (left : 'm LeftValue.t) : unit =
    let l_builtin = Jslib.find_node state.mdg state.jslib "Promise" in
    let l_retn = State.get_node state (Allocator.cid left) in
    State.add_meta_edge state l_retn l_builtin "cons"

  let get_resolves (state : State.t) (ls_promise : Node.Set.t) : Node.Set.t =
    Node.Set.map_flat (Mdg.object_orig_versions state.mdg) ls_promise
    |> Node.Set.map (Mdg.get_call_of_return state.mdg)
    |> Node.Set.map_flat (fun l_call ->
           Mdg.get_argument state.mdg l_call 1 |> Node.Set.of_list )
    |> Node.Set.map_opt (fun l_func -> Mdg.get_parameter_opt state.mdg l_func 1)
    |> Node.Set.map_flat (fun l_resolve ->
           Mdg.get_function_callers state.mdg l_resolve |> Node.Set.of_list )

  let get_resolve_args (state : State.t) (ls_resolve : Node.Set.t) (idx : int) :
      Node.Set.t =
    Fun.flip Node.Set.map_flat ls_resolve (fun l_resolve ->
        Mdg.get_argument state.mdg l_resolve idx |> Node.Set.of_list )

  let run (state : State.t) (left : 'm LeftValue.t) (_ : 'm Expression.t list)
      (_ : string) (_ : Allocator.cid) (_ : Node.t) (ls_args : Node.Set.t list)
      : State.t =
    propagate_metadata state left;
    let ls_promise = List.hd ls_args in
    let ls_callback = List.nth_opt ls_args 1 in
    let ls_callback' = Option.value ~default:Node.Set.empty ls_callback in
    let ls_resolve = get_resolves state ls_promise in
    Fun.flip Node.Set.iter ls_callback' (fun l_callback ->
        let ls_params = Mdg.get_parameters state.mdg l_callback in
        Fun.flip List.iter ls_params (fun (idx, l_param) ->
            let ls_args = get_resolve_args state ls_resolve idx in
            Fun.flip Node.Set.iter ls_args (fun l_arg ->
                State.add_dependency_edge state l_arg l_param ) ) );
    state
end

(* module HttpServerCreateInterceptor = struct
  let matcher (state : State.t) (_ : Node.t) (ls_args : Node.Set.t list)
      (prop : Property.t) : bool =
    if Property.equal (Static "createServer") prop then
      let l_module = Npmlib.find_node_opt state.mdg state.npmlib "http" in
      Option.fold l_module ~none:false ~some:(fun l_module' ->
          Node.Set.for_all (Node.equal l_module') (List.hd ls_args) )
    else false

  let run (state : State.t) (left : 'm LeftValue.t) (_ : 'm Expression.t list)
      (_ : string) (_ : Allocator.cid) (_ : Node.t) (_ : Node.Set.t list) :
      State.t =
    let l_module = Npmlib.find_node state.mdg state.npmlib "http" in
    let l_retn = State.get_node state (Allocator.cid left) in
    State.add_meta_edge state l_retn l_module "cons";
    state
end

module HttpServerListenInterceptor = struct
  let matcher (state : State.t) (_ : Node.t) (ls_args : Node.Set.t list)
      (prop : Property.t) : bool =
    if Property.equal (Property.Static "listen") prop then
      Fun.flip Node.Set.exists (List.hd ls_args) (fun l_server ->
          let l_module = Npmlib.find_node_opt state.mdg state.npmlib "http" in
          Option.fold l_module ~none:false ~some:(fun l_module' ->
              let ls_orig = Mdg.object_orig_versions state.mdg l_server in
              Fun.flip Node.Set.exists ls_orig (fun l_orig ->
                  Mdg.has_metadata state.mdg l_orig l_module' "cons" ) ) )
    else false

  let get_exports (state : State.t) : Node.Set.t =
    match State.curr_file state with
    | None -> Jslib.exported_object state.mdg state.jslib
    | Some mrel -> Jslib.exported_object ~mrel state.mdg state.jslib

  let run (cb_static_nv : cb_static_nv) (state : State.t)
      (left : 'm LeftValue.t) (_ : 'm Expression.t list) (_ : string)
      (_ : Allocator.cid) (_ : Node.t) (ls_args : Node.Set.t list) : State.t =
    let listen_cid = Allocator.cid left in
    let prop = Property.Static "$http" in
    let ls_exports = get_exports state in
    let ls_exports' = cb_static_nv state "exports" ls_exports prop listen_cid in
    Fun.flip Node.Set.iter (List.hd ls_args) (fun l_server ->
        let l_create = Mdg.get_call_of_return_opt state.mdg l_server in
        Fun.flip Option.iter l_create (fun l_create' ->
            let ls_callback = Mdg.get_arguments state.mdg l_create' in
            Fun.flip Node.Set.iter ls_exports' (fun l_export ->
                Fun.flip List.iter ls_callback (fun (_, l_callback) ->
                    if Node.is_function l_callback then
                      State.add_property_edge state l_export l_callback prop ) ) ) );
    state
end

module HttpServerOnInterceptor = struct
  let matcher (state : State.t) (_ : Node.t) (ls_args : Node.Set.t list)
      (prop : Property.t) : bool =
    if Property.equal (Property.Static "on") prop then
      Fun.flip Node.Set.exists (List.hd ls_args) (fun l_server ->
          let l_module = Npmlib.find_node_opt state.mdg state.npmlib "http" in
          Option.fold l_module ~none:false ~some:(fun l_module' ->
              let ls_orig = Mdg.object_orig_versions state.mdg l_server in
              Fun.flip Node.Set.exists ls_orig (fun l_orig ->
                  Mdg.has_metadata state.mdg l_orig l_module' "cons" ) ) )
    else false

  let get_exports (state : State.t) : Node.Set.t =
    match State.curr_file state with
    | None -> Jslib.exported_object state.mdg state.jslib
    | Some mrel -> Jslib.exported_object ~mrel state.mdg state.jslib

  let run (cb_static_nv : cb_static_nv) (state : State.t)
      (left : 'm LeftValue.t) (_ : 'm Expression.t list) (_ : string)
      (_ : Allocator.cid) (_ : Node.t) (ls_args : Node.Set.t list) : State.t =
    let listen_cid = Allocator.cid left in
    let prop = Property.Static "$http" in
    let ls_exports = get_exports state in
    let ls_exports' = cb_static_nv state "exports" ls_exports prop listen_cid in
    Fun.flip Node.Set.iter (List.hd ls_args) (fun l_server ->
        let l_create = Mdg.get_call_of_return_opt state.mdg l_server in
        Fun.flip Option.iter l_create (fun l_create' ->
            let ls_callback = Mdg.get_arguments state.mdg l_create' in
            Fun.flip Node.Set.iter ls_exports' (fun l_export ->
                Fun.flip List.iter ls_callback (fun (_, l_callback) ->
                    if Node.is_function l_callback then
                      State.add_property_edge state l_export l_callback prop ) ) ) );
    state
end *)

let initialize_require (state : State.t) (cbs_builder : cbs_builder) : unit =
  let l_require = Jslib.find_node state.mdg state.jslib "require" in
  let require_run = RequireInterceptor.run cbs_builder.build_file in
  State.set_function_interceptor state l_require require_run

let initialize_function (state : State.t) (cbs_builder : cbs_builder) : unit =
  let bind_matcher = FunctionBindInterceptor.matcher in
  let bind_run = FunctionBindInterceptor.run in
  let call_matcher = FunctionCallInterceptor.matcher in
  let call_run = FunctionCallInterceptor.run cbs_builder.unfold_function in
  State.set_method_interceptor state bind_matcher bind_run;
  State.set_method_interceptor state call_matcher call_run

let initialize_promise (state : State.t) : unit =
  let l_promise = Jslib.find_node state.mdg state.jslib "Promise" in
  let promise_run = PromiseInterceptor.run in
  let then_matcher = PromiseThenInterceptor.matcher in
  let then_run = PromiseThenInterceptor.run in
  State.set_function_interceptor state l_promise promise_run;
  State.set_method_interceptor state then_matcher then_run

(* let initialize_httpserver (state : State.t) (cbs_builder : cbs_builder) : unit =
  let create_matcher = HttpServerCreateInterceptor.matcher in
  let create_run = HttpServerCreateInterceptor.run in
  let listen_matcher = HttpServerListenInterceptor.matcher in
  let listen_run = HttpServerListenInterceptor.run cbs_builder.static_nv in
  State.set_method_interceptor state create_matcher create_run;
  State.set_method_interceptor state listen_matcher listen_run *)

let initialize (state : State.t) (cbs_builder : cbs_builder) : unit =
  initialize_require state cbs_builder;
  initialize_function state cbs_builder;
  initialize_promise state
(* initialize_httpserver state cbs_builder *)
