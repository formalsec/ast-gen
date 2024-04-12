  $ dune exec ast_gen -f input-code-1.js
  let f1;
  f1 = function () {
     let x;
     x = await 10;
  }
  
  $ dune exec ast_gen -f input-code-2.js
  let f1;
  f1 = function () {
     let x;
     const v2;
     v2 = 1 + 2;
     let v3;
     v3 = f2(v2);
     x = await v3;
  }
  
  $ dune exec ast_gen -f input-code-3.js
  let f;
  f = function (x) {
     let a;
     let v2;
     v2 = x.f;
     let v3;
     v3 = v2();
     a = await v3;
     let v4;
     v4 = eval(a);
     v4;
  }
  
