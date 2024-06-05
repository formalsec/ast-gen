  $ dune exec ast_gen -f input-code-1.js
  let v1;
  v1 = !false;
  
  $ dune exec ast_gen -f input-code-2.js
  const x;
  x = 0;
  let v1;
  v1 = x + 1;
  
  $ dune exec ast_gen -f input-code-3.js
  let f;
  f = function (x) {
     let v1;
     v1 = x.y;
     let v2;
     v2 = v1 + 1;
     let v3;
     v3 = x.y;
     let v4;
     v4 = eval(v3);
  }
  
