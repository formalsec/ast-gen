  $ dune exec ast_gen -f input-code-1.js
  ast_gen: internal error, uncaught exception:
           Failure("Unknown statement type to normalize (object on (3, 0) to (4, 21))")
           
  [125]
  $ dune exec ast_gen -f input-code-2.js
  ast_gen: internal error, uncaught exception:
           Failure("Unknown statement type to normalize (object on (1, 0) to (2, 21))")
           
  [125]
  $ dune exec ast_gen -f input-code-3.js
  ast_gen: internal error, uncaught exception:
           Failure("Unknown statement type to normalize (object on (2, 4) to (3, 25))")
           
  [125]
  $ dune exec ast_gen -f input-code-4.js
  ast_gen: internal error, uncaught exception:
           Failure("Unknown statement type to normalize (object on (3, 0) to (5, 1))")
           
  [125]
  $ dune exec ast_gen -f input-code-5.js
  ast_gen: internal error, uncaught exception:
           Failure("Unknown statement type to normalize (object on (1, 0) to (3, 1))")
           
  [125]
