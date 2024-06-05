  $ dune exec ast_gen -f input-code-1.js
  let v1;
  v1 = 1;
  let v2;
  v2 = 2;
  let v3;
  v3 = 3;
  let v4;
  v4 = 4;
  
  $ dune exec ast_gen -f input-code-2.js
  let v1;
  v1 = 1 + 2;
  let v2;
  v2 = 3 + 4;
  let v3;
  v3 = v2 + 5;
  let v4;
  v4 = v1;
  let v5;
  v5 = v3;
  
  $ dune exec ast_gen -f input-code-3.js
  x = 0;
  y = {};
  let v1;
  v1 = 2 + 1;
  y.a = v1;
  let v2;
  v2 = x;
  let v3;
  v3 = y;
  
