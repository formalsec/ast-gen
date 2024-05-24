  $ dune exec ast_gen -f input-code-1.js
  const f1;
  f1 = function () {
     let x;
     x = await 10;
  }
  
  $ dune exec ast_gen -f input-code-2.js
  const f1;
  f1 = function () {
     let x;
     const v1;
     v1 = 1 + 2;
     const v2;
     v2 = f2(v1);
     x = await v2;
  }
  
  $ dune exec ast_gen -f input-code-3.js
  const f;
  f = function (x) {
     let a;
     const v1;
     v1 = x.f();
     a = await v1;
     const v2;
     v2 = eval(a);
  }
  
