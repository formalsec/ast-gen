open Graphjs_base
include Config

let test262_conform_hoisted : bool t =
  Graphjs_ast.Config.test262_conform_hoisted
