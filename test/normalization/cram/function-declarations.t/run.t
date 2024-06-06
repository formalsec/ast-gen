  $ dune exec ast_gen -f input-code-1.js
  let f1;
  f1 = function () {
     let x;
     x = 0;
  }
  
  $ dune exec ast_gen -f input-code-2.js
  let f;
  f = function (x, y, z) {
     let v1;
     v1 = x + 1;
  }
  
  $ dune exec ast_gen -f input-code-3.js
  let count;
  count = function () {
     var i;
     i = 0;
     let v1;
     v1 = i < 10;
     while (v1) {
        let v2;
        v2 = alert(i);
        v1 = i < 10;
     }
  }
  
  $ dune exec ast_gen -f input-code-4.js
  let positive;
  positive = function (n) {
     let v1;
     v1 = n > 0;
     if (v1) {
        let v2;
        v2 = n * 2;
        let v3;
        v3 = alert(v2);
     }
  }
  
  $ dune exec ast_gen -f input-code-5.js
  let f;
  f = function () {
  }
  
