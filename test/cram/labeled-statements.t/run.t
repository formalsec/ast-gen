  $ dune exec ast_gen -f input-code-1.js
  lbl:
  break lbl;
  
  
  $ dune exec ast_gen -f input-code-2.js
  lbl1:
  lbl2:
  break lbl1;
  
  
  
  $ dune exec ast_gen -f input-code-3.js
  lbl:
  const v1;
  v1 = x === true;
  if (v1) {
     y = false;
  }
  
  
