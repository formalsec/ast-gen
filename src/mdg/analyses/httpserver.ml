type t =
  { l_server : Node.t
  ; ls_entry : Node.Set.t
  ; listen : bool
  }

let none () : t list = []

let create (l_server : Node.t) : t =
  { l_server; ls_entry = Node.Set.empty; listen = false }

let add_entries (server : t) (ls_entry : Node.Set.t) : t =
  { server with ls_entry = Node.Set.union server.ls_entry ls_entry }

let mark_listen (server : t) (ls_entry : Node.Set.t) : t =
  { (add_entries server ls_entry) with listen = true }

let pp (ppf : Fmt.t) (server : t) : unit =
  Fmt.fmt ppf "%a[%b] -> %a" Node.pp server.l_server server.listen Node.Set.pp
    server.ls_entry

let str (server : t) : string = Fmt.str "%a" pp server

let get_exports (state : State.t) : Node.Set.t =
  match State.curr_file state with
  | None -> Jslib.exported_object state.mdg state.jslib
  | Some mrel -> Jslib.exported_object ~mrel state.mdg state.jslib

let compute_server (state : State.t) (l_http : Node.t) : t list =
  Mdg.get_property state.mdg l_http (Static "createServer")
  |> List.map_flat (Mdg.get_function_callers state.mdg)
  |> List.map (Mdg.get_return_of_call state.mdg)
  |> List.map create

let compute_main_use (state : State.t) (server : t) : t =
  Fun.flip2 Node.Set.fold server.ls_entry server (fun l_entry server ->
      Mdg.get_callsites state.mdg l_entry 0
      |> List.map_flat (fun l_cs -> Mdg.get_argument state.mdg l_cs 2)
      |> Node.Set.of_list
      |> add_entries server )

let compute_main (state : State.t) (servers : t list) : t list =
  Fun.flip List.map servers (fun server ->
      Mdg.get_call_of_return state.mdg server.l_server |> fun l_call ->
      Mdg.get_argument state.mdg l_call 1 |> Node.Set.of_list |> fun ls_entry ->
      compute_main_use state { server with ls_entry } )

let compute_use (state : State.t) (servers : t list) : t list =
  Fun.flip List.map servers (fun server ->
      Mdg.get_property state.mdg server.l_server (Static "use")
      |> List.map_flat (Mdg.get_function_callers state.mdg)
      |> List.map_flat (fun l_call -> Mdg.get_argument state.mdg l_call 1)
      |> Node.Set.of_list
      |> add_entries server )

let compute_on (state : State.t) (servers : t list) : t list =
  Fun.flip List.map servers (fun server ->
      Mdg.get_property state.mdg server.l_server (Static "on")
      |> List.map_flat (Mdg.get_function_callers state.mdg)
      |> List.map_flat (fun l_call -> Mdg.get_argument state.mdg l_call 2)
      |> Node.Set.of_list
      |> add_entries server )

let compute_listen (state : State.t) (servers : t list) : t list =
  Fun.flip List.map servers (fun server ->
      Mdg.get_property state.mdg server.l_server (Static "listen")
      |> List.map_flat (Mdg.get_function_callers state.mdg)
      |> List.map_flat (Mdg.get_arguments state.mdg)
      |> List.map snd
      |> List.filter Node.is_function
      |> Node.Set.of_list
      |> mark_listen server )

let compute (state : State.t) : t list =
  let l_http = Npmlib.find_node_opt state.mdg state.npmlib "http" in
  Option.fold l_http ~none:(none ()) ~some:(fun l_http' ->
      compute_server state l_http'
      |> compute_main state
      |> compute_use state
      |> compute_on state
      |> compute_listen state )
