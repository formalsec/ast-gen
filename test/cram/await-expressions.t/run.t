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
     const v2;
     v2 = 1 + 2;
     const v3;
     v3 = f2(v2);
     x = await v3;
  }
  
  $ dune exec ast_gen -f input-code-3.js
  const f;
  f = function (x) {
     let a;
     const v2;
     v2 = x.f;
     const v3;
     v3 = v2();
     a = await v3;
     const v4;
     v4 = eval(a);
     v4;
  }
  
