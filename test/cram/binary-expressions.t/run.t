  $ dune exec ast_gen -f input-code-1.js
  const v1;
  v1 = 1 + 2;
  v1;
  
  $ dune exec ast_gen -f input-code-2.js
  const v1;
  v1 = x + y;
  v1;
  
  $ dune exec ast_gen -f input-code-3.js
  x = y + z;
  
  $ dune exec ast_gen -f input-code-4.js
  let x;
  x = y + z;
  
