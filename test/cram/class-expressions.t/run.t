  $ dune exec ast_gen -f input-code-1.js
  ast_gen: internal error, uncaught exception:
           Failure("Unknown expression type to normalize (object on (1, 8) to (2, 1))")
           
  [125]
  $ dune exec ast_gen -f input-code-2.js
  ast_gen: internal error, uncaught exception:
           Failure("Unknown expression type to normalize (object on (1, 8) to (4, 1))")
           
  [125]
  $ dune exec ast_gen -f input-code-3.js
  ast_gen: internal error, uncaught exception:
           Failure("Unknown expression type to normalize (object on (1, 8) to (8, 1))")
           
  [125]
