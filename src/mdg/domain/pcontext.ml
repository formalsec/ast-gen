open Graphjs_base
open Graphjs_ast

type 'm file =
  { file : 'm File.t
  ; built : bool
  }

type 'm t =
  { prog : 'm Prog.t
  ; files : (Fpath.t, 'm file) Hashtbl.t
  ; initial_store : Store.t
  }

let create_files (prog : 'm Prog.t) : (Fpath.t, 'm file) Hashtbl.t =
  let files = Hashtbl.create Config.(!dflt_htbl_sz) in
  Fun.flip2 Hashtbl.fold prog.files files (fun path file files ->
      let path' = Fpath.rem_ext path in
      Hashtbl.replace files path' { file; built = false };
      files )

let create (prog : 'm Prog.t) (initial_store : Store.t) : 'm t =
  let files = create_files prog in
  { prog; files; initial_store }

let file (pcontext : 'm t) (path : Fpath.t) : 'm file option =
  Hashtbl.find_opt pcontext.files path

let file_built (pcontext : 'm t) (path : Fpath.t) : unit =
  let path' = Fpath.rem_ext path in
  match Hashtbl.find_opt pcontext.files path' with
  | Some file -> Hashtbl.replace pcontext.files path' { file with built = true }
  | None -> ()
