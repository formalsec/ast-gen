  $ ast_gen input-code-1.js -o out; cat out/code/input-code-1.js; echo; rm -fr out;
  lbl:
     break lbl;
  
  
  $ ast_gen input-code-2.js -o out; cat out/code/input-code-2.js; echo; rm -fr out;
  lbl1:
     lbl2:
        break lbl1;
  
  
  
  $ ast_gen input-code-3.js -o out; cat out/code/input-code-3.js; echo; rm -fr out;
  lbl:
     let v1;
     v1 = x === true;
     if (v1) {
        y = false;
     }
  
  
