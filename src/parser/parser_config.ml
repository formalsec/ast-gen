open Graphjs_base
open Graphjs_shared
include Config

let mode : Mode.t t = static Mode.SingleFile

let test262_conform_hoisted : bool t =
  Graphjs_ast.Config.test262_conform_hoisted
