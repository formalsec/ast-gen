  $ dune exec ast_gen -f input-code-1.js
  let x;
  x = 1;
  
  $ dune exec ast_gen -f input-code-2.js
  let x;
  x = 1 + 2;
  
  $ dune exec ast_gen -f input-code-3.js
  let x;
  let y;
  x = 1 + 2;
  y = 3;
  
  $ dune exec ast_gen -f input-code-4.js
  var y;
  y = x + 1;
  
