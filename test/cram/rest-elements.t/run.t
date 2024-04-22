  $ dune exec ast_gen -f input-code-1.js
  const f;
  f = function (arg1) {
  }
  
  $ dune exec ast_gen -f input-code-2.js
  let param1;
  let otherParams;
  const v1;
  v1 = a + b;
  param1 = v1[0];
  const v2;
  v2 = v1.slice;
  otherParams = v2(1);
  
  $ dune exec ast_gen -f input-code-3.js
  let array;
  let otherParams;
  const v1;
  v1 = f();
  array = v1[0];
  const v2;
  v2 = v1.slice;
  otherParams = v2(1);
  
  $ dune exec ast_gen -f input-code-4.js
  let array;
  let otherParams;
  const v1;
  v1 = f();
  array = v1[0];
  const v2;
  v2 = v1.slice;
  otherParams = v2(1);
  
  $ dune exec ast_gen -f input-code-5.js
  const a;
  const v1;
  v1 = {};
  v1.a = 3;
  a = v1.a;
  
  $ dune exec ast_gen -f input-code-6.js
  const a;
  const b;
  const v1;
  v1 = f();
  a = v1.a;
  b = v1.b;
  
  $ dune exec ast_gen -f input-code-7.js
  const a;
  const b;
  const v1;
  v1 = {};
  v1.a = 3;
  a = v1.a;
  b = v1.b;
  
