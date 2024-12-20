open Graphjs_base

module Config = struct
  include Config

  let time_font_f font = Font.update font ~effect:`Faint
  let main_font : Font.t t = constant (Font.create ~fg:`White ())
  let path_font : Font.t t = constant (Font.create ~fg:`DarkGray ())
  let success_font : Font.t t = constant (Font.create ~fg:`LightGreen ())
  let failure_font : Font.t t = constant (Font.create ~fg:`LightRed ())
  let timeout_font : Font.t t = constant (Font.create ~fg:`Cyan ())
  let anomaly_font : Font.t t = constant (Font.create ~fg:`LightPurple ())
  let skipped_font : Font.t t = constant (Font.create ~fg:`Yellow ())
  let success_time_font : Font.t t = constant (time_font_f !success_font)
  let failure_time_font : Font.t t = constant (time_font_f !failure_font)
  let timeout_time_font : Font.t t = constant (time_font_f !timeout_font)
  let anomaly_time_font : Font.t t = constant (time_font_f !anomaly_font)
end

open struct
  let width (ppf : Fmt.t) : int =
    let writer = Writer.find ppf in
    Option.value ~default:200 (Writer.width writer)
end

module InputTree = struct
  type t' =
    | File of Fpath.t
    | Directory of t

  and t = (string, t') Hashtbl.t

  let create () : t = Hashtbl.create Config.(!dflt_htbl_sz)

  let rec add (relative : Fpath.t) (tree : t) : string list -> unit = function
    | [] -> Log.fail "unexpected path in input tree generator"
    | [ filename ] -> Hashtbl.add tree filename (File relative)
    | dirname :: path' -> (
      match Hashtbl.find_opt tree dirname with
      | Some (File _) -> Log.fail "unexpected path in input tree generator"
      | Some (Directory tree') -> add relative tree' path'
      | None ->
        let tree' = Hashtbl.create Config.(!dflt_htbl_sz) in
        Hashtbl.add tree dirname (Directory tree');
        add relative tree' path' )

  let fill (ext : string option) (paths : Fpath.t list) (tree : t) : t =
    let pwd = Fpath.v (Console.pwd ()) in
    Fun.flip List.iter paths (fun rel ->
        let abs = Fpath.normalize Fpath.(pwd // rel) in
        let abs' = Option.fold ~none:abs ~some:Fpath.(( -+ ) abs) ext in
        let segs = Fpath.segs abs' in
        add rel tree segs );
    tree

  let trim (ext : string option) (tree : t) : (string list * Fpath.t) list =
    let ext_f p = Option.fold ~none:p ~some:(fun e -> p ^ "." ^ e) ext in
    let trim_f = function [] -> [] | hd :: tl -> ext_f hd :: tl in
    let rec trim' curr tree acc =
      let single = Hashtbl.length tree <= 1 in
      Fun.flip2 Hashtbl.fold tree acc (fun name item acc ->
          match (item, single) with
          | (File path, true) -> (List.rev (trim_f curr), path) :: acc
          | (File path, false) -> (List.rev (name :: curr), path) :: acc
          | (Directory tree', true) -> trim' curr tree' acc
          | (Directory tree', false) -> trim' (name :: curr) tree' acc ) in
    trim' [] tree []

  let generate ?(ext : string option) (inputs : Fpath.t list) :
      (string list * Fpath.t) list Exec.status =
    create () |> fill ext inputs |> trim ext |> Result.ok
end

module Instance = struct
  type outcome =
    | Success
    | Failure
    | Timeout
    | Anomaly
    | Skipped

  type 'm t =
    { input : Fpath.t
    ; workspace : Workspace.t
    ; result : 'm Exec.status
    ; outcome : outcome
    ; time : Time.t
    ; streams : Log.Redirect.t
    }

  let create (input : Fpath.t) (workspace : Workspace.t)
      (result : 'm Exec.status) (outcome : outcome) (time : Time.t)
      (streams : Log.Redirect.t) : 'm t =
    { input; workspace; result; outcome; time; streams }

  let skipped (instance : 'm t) : bool =
    match instance.outcome with Skipped -> true | _ -> false

  let time_font : outcome -> Font.t = function
    | Success -> Config.(!success_time_font)
    | Failure -> Config.(!failure_time_font)
    | Timeout -> Config.(!timeout_time_font)
    | Anomaly -> Config.(!anomaly_time_font)
    | Skipped -> Log.fail "unexpected skipped instance outcome"

  let pp_path (limit : int) (ppf : Fmt.t) (path : Fpath.t) : unit =
    let (line', _) = String.truncate limit (Fpath.to_string path) in
    let len = String.length line' in
    let dots = if len < limit then String.make (limit - len) '.' else "" in
    Fmt.fmt ppf "%s %s" line' dots

  let pp_outcome (ppf : Fmt.t) : outcome -> unit = function
    | Success -> Font.fmt Config.(!success_font) ppf "SUCCESS"
    | Failure -> Font.fmt Config.(!failure_font) ppf "FAILURE"
    | Timeout -> Font.fmt Config.(!timeout_font) ppf "TIMEOUT"
    | Anomaly -> Font.fmt Config.(!anomaly_font) ppf "ANOMALY"
    | Skipped -> Font.fmt Config.(!skipped_font) ppf "SKIPPED"

  let pp_simple (ppf : Fmt.t) (instance : 'm t) : unit =
    let limit = width ppf - 18 in
    let (_, _, secs, millis) = Time.format instance.time in
    Font.fmt Config.(!path_font) ppf "%a" (pp_path limit) instance.input;
    Fmt.fmt ppf " %a" pp_outcome instance.outcome;
    if not (skipped instance) then
      Font.fmt (time_font instance.outcome) ppf "[%02d.%03ds]" secs millis
end

module InstanceTree = struct
  type 'm t' =
    | Instance of 'm Instance.t
    | Directory of 'm t

  and 'm t =
    { workspace : Workspace.t
    ; items : (string, 'm t') Hashtbl.t
    ; mutable success : int
    ; mutable failure : int
    ; mutable timeout : int
    ; mutable anomaly : int
    ; mutable skipped : int
    ; mutable time : Time.t
    }

  let create (workspace : Workspace.t) : 'm t =
    { workspace
    ; items = Hashtbl.create Config.(!dflt_htbl_sz)
    ; success = 0
    ; failure = 0
    ; timeout = 0
    ; anomaly = 0
    ; skipped = 0
    ; time = 0.0
    }

  let add (tree : 'm t) (name : string) (instance : 'm Instance.t) : unit =
    Hashtbl.add tree.items name (Instance instance)

  let rec extend (tree : 'm t) (offset : string list) :
      'm t * Workspace.t * string =
    match offset with
    | [] -> Log.fail "unexpected path in instance tree"
    | filename :: [] ->
      let w' = Workspace.extend tree.workspace filename in
      Workspace.mkdir_noerr Main w';
      (tree, w', filename)
    | dirname :: offset' -> (
      match Hashtbl.find_opt tree.items dirname with
      | Some (Instance _) -> Log.fail "unexpected path in instance tree"
      | Some (Directory tree') -> extend tree' offset'
      | None ->
        let w' = Workspace.extend tree.workspace dirname in
        let tree' = create w' in
        Hashtbl.add tree.items dirname (Directory tree');
        extend tree' offset' )

  let total (tree : 'm t) : int =
    tree.success + tree.failure + tree.timeout + tree.anomaly

  let rec count_results (tree : 'm t) =
    Fun.flip Hashtbl.iter tree.items (fun _ item ->
        let (succ, fail, tout, anml, skpd, time) = count_item item in
        tree.success <- tree.success + succ;
        tree.failure <- tree.failure + fail;
        tree.timeout <- tree.timeout + tout;
        tree.anomaly <- tree.anomaly + anml;
        tree.skipped <- tree.skipped + skpd;
        tree.time <- tree.time +. time )

  and count_item : 'm t' -> int * int * int * int * int * Time.t = function
    | Instance { time; outcome = Success; _ } -> (1, 0, 0, 0, 0, time)
    | Instance { time; outcome = Failure; _ } -> (0, 1, 0, 0, 0, time)
    | Instance { time; outcome = Timeout; _ } -> (0, 0, 1, 0, 0, time)
    | Instance { time; outcome = Anomaly; _ } -> (0, 0, 0, 1, 0, time)
    | Instance { outcome = Skipped; _ } -> (0, 0, 0, 0, 1, 0.0)
    | Directory tree ->
      count_results tree;
      ( tree.success
      , tree.failure
      , tree.timeout
      , tree.anomaly
      , tree.skipped
      , tree.time )

  let pp_execution_header (ppf : Fmt.t) (cmd : string) : unit =
    let div = String.make (width ppf) '-' in
    let font_pp = Font.fmt Config.(!main_font) in
    font_pp ppf "%s@\nGraph.js Bulk Execution: <%s>@\n" div cmd

  let pp_summary_header (ppf : Fmt.t) () : unit =
    let div = String.make (width ppf) '-' in
    let font_pp = Font.fmt Config.(!main_font) in
    font_pp ppf "%s@\nExecution Summary:@\n" div

  let pp_summary_totals (ppf : Fmt.t) (tree : 'm t) : unit =
    let total = total tree in
    let ratio = float_of_int tree.success *. 100.0 /. float_of_int total in
    let (_, mins, secs, millis) = Time.format tree.time in
    Fmt.fmt ppf "Tests Successful: %d / %d (%.2f%%) | " tree.success total ratio;
    Fmt.fmt ppf "Time elapsed: %dm %ds %dms@\n" mins secs millis;
    Fmt.fmt ppf "Failures: %d, Timeouts: %d, Anomalies: %d, Skipped: %d"
      tree.failure tree.timeout tree.anomaly tree.skipped

  let pp_summary (ppf : Fmt.t) (tree : 'm t) : unit =
    Fmt.fmt ppf "@\n%a@\n%a" pp_summary_header () pp_summary_totals tree

  let rec pp_instances (ppf : Fmt.t) (tree : 'm t) : unit =
    Fun.flip Hashtbl.iter tree.items (fun _ -> function
      | Instance instance -> Fmt.fmt ppf "%a@\n" Instance.pp_simple instance
      | Directory tree' -> pp_instances ppf tree' )

  let pp_report (cmd : string) (ppf : Fmt.t) (tree : 'm t) : unit =
    Fmt.fmt ppf "%a@\n" pp_execution_header cmd;
    Fmt.fmt ppf "%a" pp_instances tree;
    Fmt.fmt ppf "%a@." pp_summary tree
end

module type CmdInterface = sig
  type t

  val cmd : string
  val run : Fpath.t -> Workspace.t -> t Exec.status
  val outcome : t Exec.status -> Instance.outcome
end

module Executor (CmdInterface : CmdInterface) = struct
  let dump_instance_log (w : Workspace.t) (instance : 'm Instance.t) : unit =
    match (w.out, instance.outcome) with
    | (None, _) | (_, Skipped) | (Single _, Success) -> ()
    | (Single _, Failure) | (Single _, Timeout) | (Single _, Anomaly) ->
      let w' = Workspace.(w -+ "log") in
      Workspace.write_noerr Main w' (fun ppf ->
          Log.Redirect.pp_captured ppf instance.streams )
    | (Bundle _, _) ->
      let w' = Workspace.(w / "log.txt") in
      Workspace.write_noerr Side w' (fun ppf ->
          Log.Redirect.pp_captured ppf instance.streams )

  let rec dump_execution_report (tree : 'm InstanceTree.t) : unit =
    Fun.flip Hashtbl.iter tree.items (fun _ -> function
      | Directory tree' -> dump_execution_report tree'
      | _ -> () );
    let w' = Workspace.(tree.workspace / "report.graphjs") in
    Workspace.write_noerr Main w'
      (Fmt.dly "%a" (InstanceTree.pp_report CmdInterface.cmd) tree)

  let store_instance (tree : CmdInterface.t InstanceTree.t) (name : string)
      (instance : 'm Instance.t) : unit =
    InstanceTree.add tree name instance;
    dump_instance_log instance.workspace instance;
    Log.stdout "%a@." Instance.pp_simple instance

  let run_instance (input : Fpath.t) (w : Workspace.t) () :
      CmdInterface.t Exec.status * Instance.outcome =
    match CmdInterface.run input w with
    | Error (`Generic _) as result -> (result, Anomaly)
    | Error (`Failure _) as result -> (result, Anomaly)
    | Error `Timeout as result -> (result, Timeout)
    | result -> (result, CmdInterface.outcome result)

  let run_instances (tree : CmdInterface.t InstanceTree.t)
      (inputs : (string list * Fpath.t) list) : unit Exec.status =
    Fun.flip2 List.fold_left (Ok ()) inputs (fun acc (offset, input) ->
        let (tree', w', name) = InstanceTree.extend tree offset in
        let streams = Log.Redirect.capture Shared in
        let (time, (result, outcome)) = Time.time (run_instance input w') in
        Log.Redirect.restore streams;
        let instance = Instance.create input w' result outcome time streams in
        store_instance tree' name instance;
        match acc with
        | Ok () -> Result.map ignore result
        | Error _ as err -> err )

  let execute (w : Workspace.t) :
      (string list * Fpath.t) list -> unit Exec.status = function
    | [] -> Log.fail "unexpected empty input list"
    | (_, input) :: [] -> Result.map ignore (CmdInterface.run input w)
    | inputs ->
      let tree = InstanceTree.create w in
      Log.stdout "%a@." InstanceTree.pp_execution_header CmdInterface.cmd;
      let res = run_instances tree inputs in
      InstanceTree.count_results tree;
      Log.stdout "%a@." InstanceTree.pp_summary tree;
      dump_execution_report tree;
      res
end
