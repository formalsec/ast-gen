  $ dune exec ast_gen -f input-code-1.js
  const v1;
  v1 = !false;
  v1;
  
  $ dune exec ast_gen -f input-code-2.js
  const x;
  x = 0;
  const v1;
  v1 = x++;
  v1;
  
  $ dune exec ast_gen -f input-code-3.js
  const f;
  f = function (x) {
     const v1;
     v1 = x.y;
     const v2;
     v2 = v1++;
     v2;
     const v3;
     v3 = x.y;
     const v4;
     v4 = eval(v3);
     v4;
  }
  
