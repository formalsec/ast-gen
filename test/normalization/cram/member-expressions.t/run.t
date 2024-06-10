  $ ast_gen input-code-1.js
  let x;
  x = {};
  x.p = 'p';
  let y;
  y = x.p;
  
  $ ast_gen input-code-2.js
  const y;
  let v1;
  v1 = f();
  y = x[v1];
  
