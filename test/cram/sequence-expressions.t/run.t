  $ dune exec ast_gen -f input-code-1.js
  (1, 2, 3, 4);
  
  $ dune exec ast_gen -f input-code-2.js
  const v1;
  v1 = 1 + 2;
  const v2;
  v2 = 3 + 4;
  const v3;
  v3 = v2 + 5;
  (v1, v3);
  
  $ dune exec ast_gen -f input-code-3.js
  ast_gen: internal error, uncaught exception:
           Invalid_argument("option is None")
           
  [125]
