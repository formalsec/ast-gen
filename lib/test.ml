module Ast = Flow_ast
open Ast

let rec program (loc, ({ Ast.Program.statements; _ } as prog)) =
  let statements' = statements in
  (loc, { prog with statements = statements' })

and statements stmts = List.map statement stmts

and statement (stmt : ('a, 'b) Statement.t) =
  let open Statement in
  match stmt with
  | _loc, Empty { Empty.comments = _ } -> stmt
  | _ -> stmt
