  $ dune exec ast_gen -f input-code-1.js
  const f1;
  f1 = function () {
     let x;
     x = 0;
  }
  
  $ dune exec ast_gen -f input-code-2.js
  const f;
  f = function (x, y, z) {
     const v1;
     v1 = x + 1;
     v1;
  }
  
  $ dune exec ast_gen -f input-code-3.js
  const count;
  count = function () {
     var i;
     i = 0;
     const v1;
     v1 = i < 10;
     while (v1) {
        const v2;
        v2 = alert(i);
        v2;
        v1 = i < 10;
     }
  }
  
  $ dune exec ast_gen -f input-code-4.js
  const positive;
  positive = function (n) {
     const v1;
     v1 = n > 0;
     if (v1) {
        const v2;
        v2 = n * 2;
        const v3;
        v3 = alert(v2);
        v3;
     }
  }
  
  $ dune exec ast_gen -f input-code-5.js
  const f;
  f = function () {
  }
  
