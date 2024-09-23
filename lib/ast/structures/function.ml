module Id = struct
  type t =
    { uid : int
    ; name : string
    }

  let create (uid : int) (name : string) : t = { uid; name } [@@inline]
  let id (fid : t) : int = fid.uid [@@inline]
  let name (fid : t) : string = fid.name [@@inline]

  let equal (fid1 : t) (fid2 : t) : bool =
    Int.equal fid1.uid fid2.uid && String.equal fid1.name fid2.name
  [@@inline]

  let hash (fid : t) : int = Hashtbl.hash fid.uid [@@inline]

  let pp (ppf : Format.formatter) (fid : t) : unit =
    Format.fprintf ppf "(%d, %s)" fid.uid fid.name

  let str (fid : t) : string = Format.asprintf "%a" pp fid [@@inline]
end

module FuncTable = Hashtbl.Make (Id)

module Info = struct
  type func =
    { params : string list
    ; nested : Id.t list
    }

  let params (func : func) : string list = func.params [@@inline]

  type t =
    { top_lvl : Id.t list ref
    ; funcs : func FuncTable.t
    }

  let empty : unit -> t =
    let empty = { top_lvl = ref []; funcs = FuncTable.create 16 } in
    fun () -> empty

  let create (size : int) : t =
    { top_lvl = ref []; funcs = FuncTable.create size }
  [@@inline]

  let top_lvl (info : t) : Id.t list = !(info.top_lvl) [@@inline]

  let add_top_lvl (info : t) (fid : Id.t) : unit =
    info.top_lvl := fid :: !(info.top_lvl)
  [@@inline]

  let find (info : t) : Id.t -> func = FuncTable.find info.funcs
  let find_opt (info : t) : Id.t -> func option = FuncTable.find_opt info.funcs
  let replace (info : t) : Id.t -> func -> unit = FuncTable.replace info.funcs

  let remove (info : t) (fid : Id.t) : unit =
    let find_fid = List.filter Fun.(not << Id.equal fid) in
    info.top_lvl := find_fid !(info.top_lvl);
    FuncTable.remove info.funcs fid;
    FuncTable.filter_map_inplace
      (fun _ info -> Some { info with nested = find_fid info.nested })
      info.funcs

  let iter (iter_f : Id.t -> func -> unit) (info : t) : unit =
    FuncTable.iter iter_f info.funcs
  [@@inlune]

  let get_func_id (info : t) (fname : string) (parent_fid : Id.t option) :
      Id.t option =
    ( match parent_fid with
    | Some parent_fid' -> (find info parent_fid').nested
    | None -> top_lvl info )
    |> List.find_opt Fun.(String.equal fname << Id.name)

  let add_nested (info : t) (parent_fid : Id.t option) (fid : Id.t) : unit =
    match parent_fid with
    | None -> add_top_lvl info fid
    | Some fid' ->
      let func = find info fid' in
      replace info fid' { func with nested = fid :: func.nested }

  let add (info : t) (fid : Id.t) (parent_id : Id.t option)
      (params : string list) : unit =
    let prev_def = get_func_id info (Id.name fid) parent_id in
    Option.apply ~default:() (remove info) prev_def;
    replace info fid { params; nested = [] };
    add_nested info parent_id fid
end

module Context = struct
  type t =
    { path : Id.t list
    ; finfo : Info.t
    }

  let empty : unit -> t =
    let empty = { path = []; finfo = Info.empty () } in
    fun () -> empty

  let create (finfo : Info.t) : t = { path = []; finfo } [@@inline]
  let curr_func (ctx : t) : Id.t option = List.hd_opt ctx.path [@@inline]

  let visit (ctx : t) (id : Id.t) : t = { ctx with path = id :: ctx.path }
  [@@inline]

  let get_func_id (ctx : t) (fname : string) : Id.t option =
    let get_func_info_id = Info.get_func_id ctx.finfo fname in
    let rec get_fund_id' path =
      let parent_id = List.hd_opt path in
      let fid = get_func_info_id parent_id in
      match (fid, parent_id) with
      | ((Some _ as fid'), _) -> fid'
      | (None, Some _) -> get_fund_id' (List.tl path)
      | (None, None) -> None in
    get_fund_id' ctx.path

  let get_func_info' (ctx : t) (fid : Id.t) : Info.func =
    Info.find ctx.finfo fid
  [@@inline]

  let get_func_info (ctx : t) (fname : string) : Info.func option =
    let fid = get_func_id ctx fname in
    Option.bind fid Fun.(Option.some << get_func_info' ctx)

  let get_param_names' (ctx : t) (fid : Id.t) : string list =
    get_func_info' ctx fid |> Info.params
  [@@inline]

  let get_param_names (ctx : t) (fname : string) : string list option =
    get_func_info ctx fname |> Option.map Info.params
  [@@inline]

  let is_last_def (ctx : t) (fid : Id.t) : bool =
    let parent_fid = List.hd_opt ctx.path in
    let found_fid = Info.get_func_id ctx.finfo fid.name parent_fid in
    match found_fid with
    | Some fid' -> Id.equal fid fid'
    | None ->
      failwith
        ("[ERROR] Function " ^ fid.name ^ " is not defined in the given context")
end
