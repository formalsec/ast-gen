  $ dune exec ast_gen -f input-code-1.js
  let f1;
  f1 = function () {
     let x;
     x = 0;
  }
  
  $ dune exec ast_gen -f input-code-2.js
  let f;
  f = function (x, y, z) {
     const v2;
     v2 = x++;
     v2;
  }
  
  $ dune exec ast_gen -f input-code-3.js
  let count;
  count = function () {
     var i;
     i = 0;
     const v2;
     v2 = i < 10;
     while (v2) {
        let v3;
        v3 = alert(i);
        v3;
     }
  }
  
  $ dune exec ast_gen -f input-code-4.js
  let positive;
  positive = function (n) {
     const v2;
     v2 = n > 0;
     if (v2) {
        const v3;
        v3 = n * 2;
        let v4;
        v4 = alert(v3);
        v4;
     };
  }
  
  $ dune exec ast_gen -f input-code-5.js
  let f;
  f = function () {
  }
  
