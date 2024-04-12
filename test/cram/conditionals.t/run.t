  $ dune exec ast_gen -f input-code-1.js
  ast_gen: internal error, uncaught exception:
           Failure("Unknown expression type to normalize (object on (1, 13) to (1, 37))")
           
  [125]
  $ dune exec ast_gen -f input-code-2.js
  ast_gen: internal error, uncaught exception:
           Failure("Unknown expression type to normalize (object on (2, 13) to (2, 40))")
           
  [125]
  $ dune exec ast_gen -f input-code-3.js
  ast_gen: internal error, uncaught exception:
           Failure("Unknown expression type to normalize (object on (2, 4) to (2, 20))")
           
  [125]
  $ dune exec ast_gen -f input-code-4.js
  ast_gen: internal error, uncaught exception:
           Failure("Unknown expression type to normalize (object on (2, 18) to (2, 127))")
           
  [125]
