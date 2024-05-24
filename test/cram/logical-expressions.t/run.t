  $ dune exec ast_gen -f input-code-1.js
  const v1;
  v1 = 2 + 1;
  const v2;
  v2 = 1 && v1;
  
  $ dune exec ast_gen -f input-code-2.js
  const v1;
  v1 = true && false;
  if (v1) {
     let v1;
     v1 = 1;
  }
  
  $ dune exec ast_gen -f input-code-3.js
  const v1;
  v1 = 1 && 2;
  const v2;
  v2 = v1 && 3;
  
  $ dune exec ast_gen -f input-code-4.js
  const v1;
  v1 = 1 + 2;
  const v2;
  v2 = v1 && 1;
  
  $ dune exec ast_gen -f input-code-5.js
  const v1;
  v1 = x.f;
  const v2;
  v2 = x.g;
  const v3;
  v3 = v1 && v2;
  
