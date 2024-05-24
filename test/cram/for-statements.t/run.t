  $ dune exec ast_gen -f input-code-1.js
  let src;
  src = [1, 
        2, 
        3];
  let dest;
  dest = [];
  for (var p in src) {
     x = src[p];
     y = dest[p];
  }
  
  $ dune exec ast_gen -f input-code-2.js
  for (const v1 in src) {
     p = v1;
     x = src[p];
     y = dest[p];
  }
  
  $ dune exec ast_gen -f input-code-3.js
  const extend;
  extend = function (dest, src) {
     for (var p in src) {
        x = src[p];
        y = dest[p];
     }
  }
  
  $ dune exec ast_gen -f input-code-4.js
  let iterable;
  iterable = [10, 
        20, 
        30];
  for (let value of iterable) {
     const v1;
     v1 = console.log(value);
  }
  
  $ dune exec ast_gen -f input-code-5.js
  ast_gen: internal error, uncaught exception:
           Failure("hd")
           
  [125]
