  $ dune exec ast_gen -f input-code-1.js
  let z;
  z = function () {
     const v2;
     v2 = 1 + 1;
     v2;
  }
  
  $ dune exec ast_gen -f input-code-2.js
  const f;
  f = function () {
     const v2;
     v2 = 1 + 1;
     v2;
  }
  module.exports = f;
  
