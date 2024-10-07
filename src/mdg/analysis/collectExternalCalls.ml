open Graphjs_base
open Graphjs_ast
open Grammar
open Structures

type external_reference = ExternalReferences.t'

module Analysis : AbstractAnalysis.T = struct
  type t = {
    external_refs : ExternalReferences.t;
    calls         : ExternalReferences.t;
    _context       : unit
  }

  (* handle external reference objects*)
  let create_ext_ref (module' : string) (properties : property list) : external_reference =
    { _module = module'; properties = properties }

  let add_property (ext_ref : external_reference) (property : property) : external_reference = 
    {ext_ref with properties = ext_ref.properties @ [property]}

  (* handle external calls collection *)
  let add_ext_call (info : t) (call : LocationSet.t) (ext_ref : external_reference) : t = 
    ExternalReferences.T.replace info.calls call ext_ref;
    info
  

  (* handle external references collection *)
  let add_ext_ref (info : t) (loc : LocationSet.t) (ext_ref : external_reference) : t = 
    ExternalReferences.T.replace info.external_refs loc ext_ref;
    info

  let get_ext_ref (info : t) (loc : LocationSet.t) : external_reference option = 
    ExternalReferences.T.find_opt info.external_refs loc
  
  (* context *)
  let update_context (info : t) : t = info


  let analyse (info : t) (state : State.t) (statement : m Statement.t) : t =
    let eval_expr = Store.eval_expr state.store state.this in 
    let alloc = Mdg.alloc state.graph in 

    let info = update_context info in 
    match statement with
      | _, AssignFunCall {left; callee; arguments; id_call; _} -> 

        if Identifier.get_name callee = "require" then (
          (* get module name *)
          let module_arg = List.nth_opt arguments 0 in
          match module_arg with
            | Some (_, Literal {value = String module_name; _}) -> 
              let module_name = if String.starts_with ~prefix:"./" module_name 
                then String.sub module_name 2 (String.length module_name - 2)
                else module_name 
              in

              let loc = eval_expr (Identifier.to_expression left) in 
              let external_reference = create_ext_ref module_name [] in
              add_ext_ref info loc external_reference
            
            (* do nothing the fist argument is dynamic *)
            | _ -> info
        
        ) else (
          (* check if callee is an external call *)
          let l_call = LocationSet.singleton (alloc id_call) in 
          let callee = eval_expr (Identifier.to_expression callee) in 
          let external_reference = get_ext_ref info callee in 
          Option.apply (fun external_reference ->
            add_ext_call info l_call external_reference
          ) ~default:info external_reference;)

      
      | _, AssignMetCallStatic {_object; property; id_call; _} -> 
        (* check if object callee is an external reference *)
        let l_call = LocationSet.singleton (alloc id_call) in 
        let callee = eval_expr _object in 
        let external_reference = get_ext_ref info callee in 
        Option.apply (fun external_reference ->
          let external_reference' = add_property external_reference property in 
          add_ext_call info l_call external_reference'
        ) ~default:info external_reference

      | _, StaticLookup {left; _object; property; _} -> 
        (* check if object is an external reference *)
          let loc = eval_expr (Identifier.to_expression left) in 
          let loc_obj = eval_expr _object in 
          let external_reference = get_ext_ref info loc_obj in 
          Option.apply (fun external_reference ->
            let external_reference' = add_property external_reference property in 
            add_ext_ref info loc external_reference'
          ) ~default:info external_reference;
        
      | _ -> info
  
  let init () : t = {
    external_refs = ExternalReferences.T.create 10;
    calls = ExternalReferences.T.create 10;
    _context = ()
  }

  let finish (info : t) : AnalysisType.t = AnalysisType.CollectExternalCalls info.calls
end