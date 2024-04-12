  $ dune exec ast_gen -f input-code-1.js
  const v1;
  v1 = !false;
  v1;
  
  $ dune exec ast_gen -f input-code-2.js
  let x;
  x = 0;
  const v1;
  v1 = x++;
  v1;
  
  $ dune exec ast_gen -f input-code-3.js
  let f;
  f = function (x) {
     let v2;
     v2 = x.y;
     const v3;
     v3 = v2++;
     v3;
     let v4;
     v4 = x.y;
     let v5;
     v5 = eval(v4);
     v5;
  }
  
