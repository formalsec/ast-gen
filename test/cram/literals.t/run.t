  $ dune exec ast_gen -f input-code-1.js
  23;
  
  $ dune exec ast_gen -f input-code-2.js
  'hello';
  
  $ dune exec ast_gen -f input-code-3.js
  ast_gen: internal error, uncaught exception:
           Failure("Unknown expression type to normalize (object on (1, 0) to (1, 7))")
           
  [125]
  $ dune exec ast_gen -f input-code-4.js
  foo;
  
