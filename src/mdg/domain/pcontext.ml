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
  ; store : Store.t
  }

type 'm t =
  { prog : 'm Prog.t
  ; files : (Fpath.t, 'm file) Hashtbl.t
  ; funcs : (Location.t, 'm func) Hashtbl.t
  }

let create_files (prog : 'm Prog.t) : (Fpath.t, 'm file) Hashtbl.t =
  let files = Hashtbl.create Config.(!dflt_htbl_sz) in
  Fun.flip Hashtbl.iter prog.files (fun path file ->
      let path' = Fpath.rem_ext path in
      Hashtbl.replace files path' { file; built = false } );
  files

let create (prog : 'm Prog.t) : 'm t =
  let files = create_files prog in
  let funcs = Hashtbl.create Config.(!dflt_htbl_sz) in
  { prog; files; funcs }

let file (pcontext : 'm t) (path : Fpath.t) : 'm file option =
  Hashtbl.find_opt pcontext.files path

let build_file (pcontext : 'm t) (path : Fpath.t) : unit =
  let path' = Fpath.rem_ext path in
  match Hashtbl.find_opt pcontext.files path' with
  | Some file -> Hashtbl.replace pcontext.files path' { file with built = true }
  | None -> ()

let func (pcontext : 'm t) (l_func : Node.t) : 'm func option =
  Hashtbl.find_opt pcontext.funcs l_func.loc

let set_func (pcontext : 'm t) (l_func : Node.t) (func : 'm func) : unit =
  Hashtbl.replace pcontext.funcs l_func.loc func

let declare_func (pcontext : 'm t) (l_func : Node.t) (floc : Floc.t)
    (func : 'm FunctionDefinition.t) (store : Store.t) : unit =
  Hashtbl.replace pcontext.funcs l_func.loc { floc; func; store }
