  $ dune exec ast_gen -f input-code-1.js
  let z;
  z = function () {
     const v2;
     v2 = 1 + 1;
     v2;
  }
  z = z;
  
  $ dune exec ast_gen -f input-code-2.js
  ast_gen: internal error, uncaught exception:
           Failure("pattern not implemented")
           
  [125]
