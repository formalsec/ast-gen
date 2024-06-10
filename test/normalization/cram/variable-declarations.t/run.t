  $ ast_gen input-code-1.js
  let x;
  x = 1;
  
  $ ast_gen input-code-2.js
  let x;
  x = 1 + 2;
  
  $ ast_gen input-code-3.js
  let x;
  let y;
  x = 1 + 2;
  y = 3;
  
  $ ast_gen input-code-4.js
  var x;
  var y;
  y = x + 1;
  
