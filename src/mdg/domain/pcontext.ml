open Graphjs_base
open Graphjs_ast

module Floc = struct
  type t =
    { path : Fpath.t
    ; mrel : Fpath.t
    ; main : bool
    }

  let default =
    let dflt = { path = Fpath.v "."; mrel = Fpath.v "."; main = false } in
    fun () -> dflt

  let create (path : Fpath.t) (mrel : Fpath.t) (main : bool) =
    { path; mrel; main }
end

type 'm file =
  { file : 'm File.t
  ; built : bool
  }

type 'm func =
  { floc : Floc.t
  ; func : 'm FunctionDefinition.t
  ; eval_store : Store.t
  }

type 'm t =
  { prog : 'm Prog.t
  ; files : (Fpath.t, 'm file) Hashtbl.t
  ; funcs : (Location.t, 'm func) Hashtbl.t
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
  let funcs = Hashtbl.create Config.(!dflt_htbl_sz) in
  { prog; files; funcs; initial_store }

let file (pcontext : 'm t) (path : Fpath.t) : 'm file option =
  Hashtbl.find_opt pcontext.files path

let file_built (pcontext : 'm t) (path : Fpath.t) : unit =
  let path' = Fpath.rem_ext path in
  match Hashtbl.find_opt pcontext.files path' with
  | Some file -> Hashtbl.replace pcontext.files path' { file with built = true }
  | None -> ()

let func (pcontext : 'm t) (l_func : Node.t) : 'm func option =
  Hashtbl.find_opt pcontext.funcs l_func.loc

let func_decl (pcontext : 'm t) (l_func : Node.t) (floc : Floc.t)
    (func : 'm FunctionDefinition.t) (eval_store : Store.t) : unit =
  Hashtbl.replace pcontext.funcs l_func.loc { floc; func; eval_store }
