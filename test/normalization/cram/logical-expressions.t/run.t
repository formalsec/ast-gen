  $ ast_gen input-code-1.js
  let v1;
  v1 = 2 + 1;
  let v2;
  v2 = 1 && v1;
  
  $ ast_gen input-code-2.js
  let v1;
  v1 = true && false;
  if (v1) {
     let v1;
     v1 = 1;
  }
  
  $ ast_gen input-code-3.js
  let v1;
  v1 = 1 && 2;
  let v2;
  v2 = v1 && 3;
  
  $ ast_gen input-code-4.js
  let v1;
  v1 = 1 + 2;
  let v2;
  v2 = v1 && 1;
  
  $ ast_gen input-code-5.js
  let v1;
  v1 = x.f;
  let v2;
  v2 = x.g;
  let v3;
  v3 = v1 && v2;
  
