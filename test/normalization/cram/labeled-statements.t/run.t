  $ ast_gen input-code-1.js
  lbl:
  break lbl;
  
  
  $ ast_gen input-code-2.js
  lbl1:
  lbl2:
  break lbl1;
  
  
  
  $ ast_gen input-code-3.js
  lbl:
  let v1;
  v1 = x === true;
  if (v1) {
     y = false;
  }
  
  
