  $ ast_gen input-code-1.js
  let v1;
  v1 = 1 + 2;
  
  $ ast_gen input-code-2.js
  let v1;
  v1 = x + y;
  
  $ ast_gen input-code-3.js
  x = y + z;
  
  $ ast_gen input-code-4.js
  const x;
  x = y + z;
  
