  $ ast_gen input-code-1.js
  let f1;
  f1 = function () {
     let x;
     x = await 10;
  }
  
  $ ast_gen input-code-2.js
  let f1;
  f1 = function () {
     let x;
     let v1;
     v1 = 1 + 2;
     let v2;
     v2 = f2(v1);
     x = await v2;
  }
  
  $ ast_gen input-code-3.js
  let f;
  f = function (x) {
     let a;
     let v1;
     v1 = x.f();
     a = await v1;
     let v2;
     v2 = eval(a);
  }
  
