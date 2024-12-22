open Graphjs_base

type entry =
  { root : string
  ; name : string
  ; mdg : Mdg.t
  }

type t = (Fpath.t, entry) Hashtbl.t

let create_entry ((path, mdg) : Fpath.t * Mdg.t) : Fpath.t * entry =
  let (root', name') = Fpath.split_base path in
  let root = if Fpath.is_current_dir root' then "" else Fpath.to_string root' in
  let name = Fpath.to_string name' in
  (path, { root; name; mdg })

let create (entries : (Fpath.t * Mdg.t) list) : t =
  entries |> List.map create_entry |> List.to_seq |> Hashtbl.of_seq

let find (entries : t) (path : Fpath.t) : entry = Hashtbl.find entries path

let add (entries : t) (path : Fpath.t) (entry : entry) : unit =
  Hashtbl.add entries path entry

let merge_entries (entries : t) (main : entry) : Mdg.t =
  Fun.flip Hashtbl.iter entries (fun _ entry ->
      Log.debug "root = %S | name = %S" entry.root entry.name );

  (* *)
  main.mdg
