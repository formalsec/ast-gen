open Graphjs_base

module Config = struct
  include Config

  let time_font_f (font : Font.t) : Font.t = Font.update font ~filter:`Faint
  let main_font = constant (Font.create ~fg:`White ())
  let path_font = constant (Font.create ~fg:`DarkGray ())
  let success_font = constant (Font.create ~fg:`LightGreen ())
  let failure_font = constant (Font.create ~fg:`LightRed ())
  let anomaly_font = constant (Font.create ~fg:`LightPurple ())
  let timeout_font = constant (Font.create ~fg:`Cyan ())
  let skipped_font = constant (Font.create ~fg:`Yellow ())
  let success_time_font = constant (time_font_f !success_font)
  let failure_time_font = constant (time_font_f !failure_font)
  let anomaly_time_font = constant (time_font_f !anomaly_font)
  let timeout_time_font = constant (time_font_f !timeout_font)
  let dflt_width = constant 20
  let dflt_log_ext = constant "log"
  let dflt_log_path = constant (Fpath.v "log.txt")
  let dflt_report_path = constant (Fpath.v "report.graphjs")
end

module InputTree = struct
  type t' =
    | Input of Fpath.t
    | Tree of t

  and t = (string, t') Hashtbl.t

  let create () : t = Hashtbl.create Config.(!dflt_htbl_sz)

  let count_next_sec (tree : t) : int * int =
    Fun.flip2 Hashtbl.fold tree (0, 0) (fun _ item ((n_secs, n_items) as acc) ->
        match item with
        | Input _ -> acc
        | Tree tree' -> (n_secs + 1, n_items + Hashtbl.length tree') )

  let rec add (input : Fpath.t) (tree : t) (secs : string list) : unit =
    match secs with
    | [] -> Log.fail "unexpected path in input tree generator"
    | sec :: [] -> Hashtbl.add tree sec (Input input)
    | sec :: secs' -> (
      match Hashtbl.find_opt tree sec with
      | Some (Input _) -> Log.fail "unexpected path in input tree generator"
      | Some (Tree tree') -> add input tree' secs'
      | None ->
        let tree' = Hashtbl.create Config.(!dflt_htbl_sz) in
        Hashtbl.add tree sec (Tree tree');
        add input tree' secs' )

  let fill (inputs : Fpath.t list) (tree : t) : t =
    let pwd = Fpath.v (Console.pwd ()) in
    Fun.flip List.iter inputs (fun input ->
        let abs = Fpath.normalize Fpath.(pwd // input) in
        let secs = Fpath.segs abs in
        add input tree secs );
    tree

  let trim (tree : t) : (string list * Fpath.t) list =
    let rec trim' curr tree trim_curr acc =
      let trim_curr' = trim_curr && Hashtbl.length tree <= 1 in
      let (n_next_secs, n_next_items) = count_next_sec tree in
      let trim_next = n_next_secs == n_next_items in
      Fun.flip2 Hashtbl.fold tree acc (fun sec item acc ->
          match (item, trim_curr') with
          | (Input input, true) -> (List.rev curr, input) :: acc
          | (Input input, false) -> (List.rev (sec :: curr), input) :: acc
          | (Tree tree', true) -> trim' curr tree' trim_next acc
          | (Tree tree', false) -> trim' (sec :: curr) tree' trim_next acc )
    in
    trim' [] tree true []

  let generate (inputs : Fpath.t list) :
      (string list * Fpath.t) list Exec.result =
    create () |> fill inputs |> trim |> Result.ok
end

module Instance = struct
  type outcome =
    | Success
    | Failure
    | Anomaly
    | Timeout
    | Skipped

  type 'm t =
    { input : Fpath.t
    ; workspace : Workspace.t
    ; result : 'm Exec.result
    ; outcome : outcome
    ; time : Time.t
    ; streams : Log.Redirect.t
    }

  let create (input : Fpath.t) (workspace : Workspace.t)
      (result : 'm Exec.result) (outcome : outcome) (time : Time.t)
      (streams : Log.Redirect.t) : 'm t =
    { input; workspace; result; outcome; time; streams }

  let skipped (instance : 'm t) : bool =
    match instance.outcome with Skipped -> true | _ -> false

  let time_font (outcome : outcome) : Font.t =
    match outcome with
    | Success -> Config.(!success_time_font)
    | Failure -> Config.(!failure_time_font)
    | Anomaly -> Config.(!anomaly_time_font)
    | Timeout -> Config.(!timeout_time_font)
    | Skipped -> Log.fail "unexpected skipped instance outcome"

  let pp_path (limit : int) (ppf : Fmt.t) (path : Fpath.t) : unit =
    let line = String.truncate (Some limit) (Fpath.to_string path) in
    let len = String.length line in
    let dots_len = if limit >= len then limit - len else 0 in
    let dots = String.make dots_len '.' in
    Fmt.fmt ppf "%s %s" line dots

  let pp_outcome (ppf : Fmt.t) : outcome -> unit = function
    | Success -> Font.fmt Config.(!success_font) ppf "SUCCESS"
    | Failure -> Font.fmt Config.(!failure_font) ppf "FAILURE"
    | Timeout -> Font.fmt Config.(!timeout_font) ppf "TIMEOUT"
    | Anomaly -> Font.fmt Config.(!anomaly_font) ppf "ANOMALY"
    | Skipped -> Font.fmt Config.(!skipped_font) ppf "SKIPPED"

  let pp_simple (dflt_width : int) (ppf : Fmt.t) (instance : 'm t) : unit =
    let log_time = not (skipped instance) in
    let time_str = if log_time then Time.str instance.time else "" in
    let time_len = String.length time_str in
    let limit = Writer.(size ~default:dflt_width (width ppf)) - time_len - 11 in
    Font.fmt Config.(!path_font) ppf "%a" (pp_path limit) instance.input;
    Fmt.fmt ppf " %a" pp_outcome instance.outcome;
    if log_time then Font.fmt (time_font instance.outcome) ppf "[%s]" time_str
end

module InstanceTree = struct
  type 'm t' =
    | Instance of 'm Instance.t
    | Directory of 'm t

  and 'm t =
    { workspace : Workspace.t
    ; items : (string, 'm t') Hashtbl.t
    ; mutable time : Time.t
    ; mutable success : int
    ; mutable failure : int
    ; mutable timeout : int
    ; mutable anomaly : int
    ; mutable skipped : int
    }

  let create (workspace : Workspace.t) : 'm t =
    { workspace
    ; items = Hashtbl.create Config.(!dflt_htbl_sz)
    ; time = 0.0
    ; success = 0
    ; failure = 0
    ; timeout = 0
    ; anomaly = 0
    ; skipped = 0
    }

  let add (tree : 'm t) (name : string) (instance : 'm Instance.t) : unit =
    Hashtbl.add tree.items name (Instance instance)

  let rec extend (tree : 'm t) (secs : string list) :
      'm t * Workspace.t * string =
    match secs with
    | [] -> Log.fail "unexpected path in instance tree"
    | sec :: [] ->
      let w' = Workspace.extend tree.workspace sec in
      let w'' = Workspace.set_ext w' in
      Workspace.mkdir_noerr Main w'';
      (tree, w'', sec)
    | sec :: secs' -> (
      match Hashtbl.find_opt tree.items sec with
      | Some (Instance _) -> Log.fail "unexpected path in instance tree"
      | Some (Directory tree') -> extend tree' secs'
      | None ->
        let w' = Workspace.extend tree.workspace sec in
        let tree' = create w' in
        Hashtbl.add tree.items sec (Directory tree');
        extend tree' secs' )

  let total (tree : 'm t) : int =
    tree.success + tree.failure + tree.anomaly + tree.timeout

  let rec count_results (tree : 'm t) : unit =
    Fun.flip Hashtbl.iter tree.items (fun _ item ->
        let (succ, fail, anom, tout, skip, time) = count_item item in
        tree.success <- tree.success + succ;
        tree.failure <- tree.failure + fail;
        tree.anomaly <- tree.anomaly + anom;
        tree.timeout <- tree.timeout + tout;
        tree.skipped <- tree.skipped + skip;
        tree.time <- tree.time +. time )

  and count_item (tree : 'm t') : int * int * int * int * int * Time.t =
    match tree with
    | Instance { time; outcome = Success; _ } -> (1, 0, 0, 0, 0, time)
    | Instance { time; outcome = Failure; _ } -> (0, 1, 0, 0, 0, time)
    | Instance { time; outcome = Anomaly; _ } -> (0, 0, 1, 0, 0, time)
    | Instance { time; outcome = Timeout; _ } -> (0, 0, 0, 1, 0, time)
    | Instance { outcome = Skipped; _ } -> (0, 0, 0, 0, 1, 0.0)
    | Directory tree ->
      count_results tree;
      ( tree.success
      , tree.failure
      , tree.anomaly
      , tree.timeout
      , tree.skipped
      , tree.time )

  let pp_header (dflt_width : int) (ppf : Fmt.t) (cmd : string) : unit =
    let limit = Writer.(size ~default:dflt_width (width ppf)) in
    let div = String.make limit '-' in
    let font_pp = Font.fmt Config.(!main_font) in
    font_pp ppf "%s@\nGraph.js Bulk Execution: <%s>@\n" div cmd

  let pp_summary_header (dflt_width : int) (ppf : Fmt.t) () : unit =
    let limit = Writer.(size ~default:dflt_width (width ppf)) in
    let div = String.make limit '-' in
    let font_pp = Font.fmt Config.(!main_font) in
    font_pp ppf "%s@\nExecution Summary:@\n" div

  let pp_summary_totals (ppf : Fmt.t) (tree : 'm t) : unit =
    let total = total tree in
    let ratio = float_of_int tree.success *. 100.0 /. float_of_int total in
    Fmt.fmt ppf "Tests Successful: %d / %d (%.2f%%) | " tree.success total ratio;
    Fmt.fmt ppf "Time elapsed: %a@\n" Time.pp tree.time;
    Fmt.fmt ppf "Failures: %d, Anomalies: %d, Timeouts: %d, Skipped: %d"
      tree.failure tree.anomaly tree.timeout tree.skipped

  let pp_summary (dflt_width : int) (ppf : Fmt.t) (tree : 'm t) : unit =
    let pp_header = pp_summary_header dflt_width in
    Fmt.fmt ppf "@\n%a@\n%a" pp_header () pp_summary_totals tree

  let rec pp_instances (dflt_width : int) (ppf : Fmt.t) (tree : 'm t) : unit =
    Fun.flip Hashtbl.iter tree.items (fun _ -> function
      | Instance instance ->
        Fmt.fmt ppf "%a@\n" (Instance.pp_simple dflt_width) instance
      | Directory tree' -> pp_instances dflt_width ppf tree' )

  let pp_report (dflt_width : int) (cmd : string) (ppf : Fmt.t) (tree : 'm t) :
      unit =
    Fmt.fmt ppf "%a@\n" (pp_header dflt_width) cmd;
    Fmt.fmt ppf "%a" (pp_instances dflt_width) tree;
    Fmt.fmt ppf "%a@." (pp_summary dflt_width) tree
end

module type CmdInterface = sig
  type t

  val cmd : string
  val run : Workspace.t -> Fpath.t -> t Exec.result
  val outcome : t Exec.result -> Instance.outcome
end

module Executor (CmdInterface : CmdInterface) = struct
  let max_input_len (inputs : (string list * Fpath.t) list) : int =
    Fun.flip2 List.fold_left 0 inputs (fun acc (_, path) ->
        let len = String.length (Fpath.to_string path) in
        if len > acc then len else acc )

  let dump_instance_log (w : Workspace.t) (instance : 'm Instance.t) : unit =
    match (w.path, instance.outcome) with
    | (None, _) | (_, Skipped) | (Single _, Success) -> ()
    | (Single _, _) ->
      let log_ext = Config.(!dflt_log_ext) in
      let w' = Workspace.(w -+ log_ext) in
      Workspace.output_noerr Main w' Log.Redirect.pp_captured instance.streams
    | (Bundle _, _) ->
      let log_path = Config.(!dflt_log_path) in
      let w' = Workspace.(w // log_path) in
      Workspace.output_noerr Side w' Log.Redirect.pp_captured instance.streams

  let rec dump_execution_report (dflt_width : int) (tree : 'm InstanceTree.t) :
      unit =
    Fun.flip Hashtbl.iter tree.items (fun _ -> function
      | Directory tree' -> dump_execution_report dflt_width tree'
      | _ -> () );
    let report_path = Config.(!dflt_report_path) in
    let w' = Workspace.(tree.workspace // report_path) in
    let pp_tree = InstanceTree.pp_report dflt_width CmdInterface.cmd in
    Workspace.output_noerr Main w' pp_tree tree

  let run_instance (input : Fpath.t) (w : Workspace.t) () :
      CmdInterface.t Exec.result * Instance.outcome =
    match CmdInterface.run w input with
    | Error (`Generic _) as result -> (result, Anomaly)
    | Error (`Failure _) as result -> (result, Anomaly)
    | Error `Timeout as result -> (result, Timeout)
    | result -> (result, CmdInterface.outcome result)

  let store_instance (dflt_width : int) (tree : CmdInterface.t InstanceTree.t)
      (name : string) (instance : 'm Instance.t) : unit =
    InstanceTree.add tree name instance;
    dump_instance_log instance.workspace instance;
    Log.stdout "%a@." (Instance.pp_simple dflt_width) instance

  let run_instances (dflt_width : int) (tree : CmdInterface.t InstanceTree.t)
      (inputs : (string list * Fpath.t) list) : unit Exec.result =
    Fun.flip2 List.fold_left (Ok ()) inputs (fun acc (offset, input) ->
        Log.info "Running instance '%a'..." Fpath.pp input;
        let (tree', w, name) = InstanceTree.extend tree offset in
        let streams = Log.Redirect.capture Shared in
        let (time, (result, outcome)) = Time.compute (run_instance input w) in
        let _ = Log.Redirect.restore streams in
        let instance = Instance.create input w result outcome time streams in
        store_instance dflt_width tree' name instance;
        match acc with
        | Ok () -> Result.map ignore result
        | Error _ as err -> err )

  let execute (w : Workspace.t) (inputs : (string list * Fpath.t) list) :
      unit Exec.result =
    match inputs with
    | [] -> Log.fail "unexpected empty input list"
    | [ (_, input) ] -> Result.map ignore (CmdInterface.run w input)
    | inputs ->
      let dflt_width = max_input_len inputs + Config.(!dflt_width) in
      let tree = InstanceTree.create w in
      Log.stdout "%a@." (InstanceTree.pp_header dflt_width) CmdInterface.cmd;
      let res = run_instances dflt_width tree inputs in
      InstanceTree.count_results tree;
      Log.stdout "%a@." (InstanceTree.pp_summary dflt_width) tree;
      dump_execution_report dflt_width tree;
      res
end
