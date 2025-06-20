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
      (left : Region.t LeftValue.t) (_ : 'm Expression.t list) (_ : string)
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
  let matcher (_ : Node.t) (ls_args : Node.Set.t list) (prop : Property.t) :
      bool =
    Node.Set.for_all Node.is_function (List.hd ls_args)
    && Property.equal (Static "bind") prop

  let get_this_function (state : State.t) (ls_args : Node.Set.t list) :
      'm Pcontext.func option =
    let ls_this = List.hd ls_args in
    if Node.Set.cardinal ls_this == 1 then
      Pcontext.func state.pcontext (Node.Set.choose ls_this)
    else None

  let run (state : State.t) (left : Region.t LeftValue.t)
      (_ : 'm Expression.t list) (_ : string) (_ : Allocator.cid)
      (l_func : Node.t) (ls_args : Node.Set.t list) : State.t =
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
  let matcher (_ : Node.t) (ls_args : Node.Set.t list) (prop : Property.t) :
      bool =
    Node.Set.for_all Node.is_function (List.hd ls_args)
    && Property.equal (Static "call") prop

  let run (cb_unfold_function : cb_unfold_function) (state : State.t)
      (left : Region.t LeftValue.t) (_ : 'm Expression.t list)
      (call_name : string) (call_cid : Allocator.cid) (_ : Node.t)
      (ls_args : Node.Set.t list) : State.t =
    let retn_cid = Allocator.cid left in
    let retn_name = LeftValue.name left in
    let ls_func = List.hd ls_args in
    let ls_args' = List.tl ls_args in
    let unfold_f = cb_unfold_function state call_name retn_name in
    unfold_f call_cid retn_cid false ls_func ls_args' |> fst
end

let initialize_require (state : State.t) (cbs_builder : cbs_builder) : unit =
  let l_require = Jslib.find_node state.mdg state.jslib "require" in
  let cb_require = RequireInterceptor.run cbs_builder.build_file in
  State.set_function_interceptor state l_require cb_require

let initialize_function (state : State.t) (cbs_builder : cbs_builder) : unit =
  let bind_matcher = FunctionBindInterceptor.matcher in
  let bind_run = FunctionBindInterceptor.run in
  let call_matcher = FunctionCallInterceptor.matcher in
  let call_run = FunctionCallInterceptor.run cbs_builder.unfold_function in
  State.set_method_interceptor state bind_matcher bind_run;
  State.set_method_interceptor state call_matcher call_run

let initialize (state : State.t) (cbs_builder : cbs_builder) : unit =
  initialize_require state cbs_builder;
  initialize_function state cbs_builder
