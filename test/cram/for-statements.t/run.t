  $ dune exec ast_gen -f input-code-1.js
  let src;
  src = [];
  src["0"] = 1;
  src["1"] = 2;
  src["2"] = 3;
  let dest;
  dest = [];
  for (var p in src) {
     x = src[p];
     y = dest[p];
  }
  
  $ dune exec ast_gen -f input-code-2.js
  for (let v1 in src) {
     p = v1;
     x = src[p];
     y = dest[p];
  }
  
  $ dune exec ast_gen -f input-code-3.js
  let extend;
  extend = function (dest, src) {
     for (var p in src) {
        x = src[p];
        y = dest[p];
     }
  }
  
  $ dune exec ast_gen -f input-code-4.js
  let iterable;
  iterable = [];
  iterable["0"] = 10;
  iterable["1"] = 20;
  iterable["2"] = 30;
  for (let value of iterable) {
     let v1;
     v1 = console.log(value);
  }
  
  $ dune exec ast_gen -f input-code-5.js
  ast_gen: internal error, uncaught exception:
           Failure("hd")
           
  [125]
