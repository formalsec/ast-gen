  $ dune exec ast_gen -f input-code-1.js
  let v1;
  v1 = 1 + 2;
  
  $ dune exec ast_gen -f input-code-2.js
  let v1;
  v1 = x + y;
  
  $ dune exec ast_gen -f input-code-3.js
  x = y + z;
  
  $ dune exec ast_gen -f input-code-4.js
  const x;
  x = y + z;
  
