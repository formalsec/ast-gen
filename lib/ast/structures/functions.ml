open Auxiliary.Functions

(* function id definition *)
module Id  = struct

  type t = {
    uid : int;
    name : string;
  }

  let create (uid' : int) (name' : string) : t = {uid = uid'; name = name'}
  let equal (func_id : t) (func_id' : t) = Int.equal func_id.uid func_id'.uid 
                                        && String.equal func_id.name func_id'.name
  let hash (func_id : t)= Hashtbl.hash func_id.uid

  let get_id (func_id : t) = func_id.uid
  let get_name (func_id : t) = func_id.name

  let to_string (func_id: t) : string = "(" ^ string_of_int func_id.uid ^ ", " ^ func_id.name ^ ")"
end

(* function hashtable definition *)
module FuncTable = Hashtbl.Make(Id)  


module rec Info : sig
  type functions = Id.t list
  type info = {
    params : string list;
    nested : functions;
  }

  type t = {
    top_lvl : functions ref;
    functions : info FuncTable.t;
  }

  (* ---- primitive functions ----- *)
  val empty       : t 
  val find        : t -> Id.t -> info
  val find_opt    : t -> Id.t -> info option
  val create      : int -> t
  val iter        : (Id.t -> info -> unit) -> t -> unit 
  val add         : t -> Id.t -> Id.t option -> string list -> unit
  val get_func_id : t -> string -> Id.t option -> Id.t option
  val get_params  : info -> string list 



end = struct
  type functions = Id.t list
  type info = {
    params : string list;
    nested : functions;
  }

  type t = {
    top_lvl : functions ref;
    functions : info FuncTable.t;
  }

  let empty = {top_lvl = ref []; functions = FuncTable.create 1}
  let create (size : int) : t = { top_lvl = ref []; functions = FuncTable.create size }
  let find (info : t) : Id.t -> info = FuncTable.find info.functions
  let find_opt (info : t) : Id.t -> info option = FuncTable.find_opt info.functions
  let replace (info : t) : Id.t -> info -> unit = FuncTable.replace info.functions 
  let remove (info : t) (func_id : Id.t) : unit = 
    let top_lvl = info.top_lvl in 

    top_lvl := List.filter (not << Id.equal func_id) !top_lvl;
    FuncTable.remove info.functions func_id;
    FuncTable.filter_map_inplace (fun _ info -> 
      Some {info with nested = List.filter (not << Id.equal func_id) info.nested}
    ) info.functions

  let iter (f : Id.t -> info -> unit) (info : t) : unit = FuncTable.iter f info.functions


  let get_top_lvl (info : t) : functions = !(info.top_lvl)
  let add_top_lvl (info : t) (func : Id.t) : unit =
    (info.top_lvl) := func :: !(info.top_lvl)
  
  let get_func_id (info : t) (func_name : string) (parent_id : Id.t option) : Id.t option =
    let context = match parent_id with 
      | Some parent_id -> 
        let parent_info = find info parent_id in
        parent_info.nested
      | None ->  get_top_lvl info
    in
    List.find_opt (((=) func_name) << Id.get_name) context


  let add_nested (info : t) (parent_id : Id.t option) (func_id : Id.t) : unit =
    match parent_id with
    (* no parent node, add function to the top-level functions list *)
    | None     -> add_top_lvl info func_id
    (* there is a parent node to add to its nested children*)
    | Some key -> 
      let func_info = find info key in 
      replace info key {func_info with nested = func_id :: func_info.nested}

  let add (info : t) (func_id : Id.t) (parent_id : Id.t option) (params' : string list) : unit = 
    (* remove previous version if it exists *)
    let prev_definition = get_func_id info (Id.get_name func_id) parent_id in 
    option_may (remove info) prev_definition;

    (* add found node information *)
    let func_info : info = {
      params = params';
      nested = [];
    } in 
    replace info func_id func_info;

    (* add found node information to its parent *)
    add_nested info parent_id func_id

  let get_params (info : info) : string list = info.params

end

module Context = struct
  type t = {
    path : Id.t list;
    functions : Info.t
  }

  let empty = {path = []; functions = Info.empty}
  let create (functions' : Info.t) : t = { path = []; functions = functions'}
  let visit (context : t) (id : Id.t) : t = {context with path = id :: context.path}

  let get_current_function (context : t) () : Id.t option = List.nth_opt context.path 0

  let get_func_id (context : t) (func_name : string) : Id.t option = 
    let get_func_info_id = Info.get_func_id context.functions in 
    let rec aux (path : Id.t list)  : Id.t option =
      let parent_id = hd_opt path in
      let id = get_func_info_id func_name parent_id in 

      if Option.is_some id then id (* found function nested inside parent id *)
      else if Option.is_some parent_id then aux (List.tl path) (* function not found yet but there is more parents to search *)
      else None (* function name wasnt found in any parent's nested list *)

    in
    aux context.path

  let get_func_info' (context : t) (func_id : Id.t) : Info.info = 
    Info.find context.functions func_id

  let get_func_info (context : t) (func_name : string) : Info.info option = 
    let func_id = get_func_id context func_name in 
    Option.bind func_id (Option.some << get_func_info' context)

  let get_param_names' (contents : t) (func_id : Id.t) : string list = 
    let func_info = get_func_info' contents func_id in 
    func_info.params

  let get_param_names (context : t) (func_name : string) : string list option = 
    let func_info = get_func_info context func_name in 
    Option.map (Info.get_params) func_info

  let is_last_definition (context : t) (id : Id.t) : bool =
    let get_func_info_id = Info.get_func_id context.functions in 
    let parent_id = hd_opt context.path in
    let found_id = get_func_info_id id.name parent_id in 

    map_default_lazy 
      (fun found_id -> (Id.get_id found_id) = (Id.get_id id)) 
      (lazy (failwith ("function " ^ id.name ^ " is not definied in the given context"))) found_id
  
end



(* module rec Info : sig
  type info = {
    params : string list;
    context  : FuncTable.Id.t list;
  }

  type t = info FuncTable.t

  (* ---- primitive functions ----- *)
  val create   : int -> t
  val add : t -> string -> int -> string list -> t
  val iter : (string -> info -> unit) -> t -> unit

  val get_info       : t list -> string -> info
  val get_param_name : t list -> string -> int -> string

end = struct
  type info = {
    id     : int;
    params : string list;
    context  : Info.t;
  }

  type t = info HashTable.t

  (* ------- S T R U C T U R E   F U N C T I O N S ------- *)
  let create = HashTable.create
  let find_opt : t -> string -> info option = HashTable.find_opt

  let add (info : t) (func : string) (id' : int) (params' : string list) : t = 
    let new_context = create 5 in
    let func_info : info = {
      id = id';
      params = params';
      context = new_context;
    } in 

    HashTable.replace info func func_info;
    new_context

  let iter : (string -> info -> unit) -> t -> unit = HashTable.iter

  
  (* ------- I N F O   M A N I P U L A T I O N ------- *)
  let rec get_info (functions : t list) (func_name : string) : info = 
    match functions with 
      | [] -> failwith "function not defined in the given context"
      | context::rest -> 
        let info = find_opt context func_name in 
        if Option.is_some info
          then Option.get info
          else  get_info rest func_name
    
  let get_param_name (functions : t list) (func_name : string) (index : int) : string =
    let info = get_info functions func_name in
    List.nth info.params index

end *)