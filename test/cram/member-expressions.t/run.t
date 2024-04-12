  $ dune exec ast_gen -f input-code-1.js
  let x;
  x = { p : 'p' };
  x = x;
  let y;
  y = x.p;
  y = y;
  
  $ dune exec ast_gen -f input-code-2.js
  let y;
  let v1;
  v1 = f();
  y = x.v1;
  y = y;
  
