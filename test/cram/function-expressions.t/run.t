  $ dune exec ast_gen -f input-code-1.js
  let z;
  z = function () {
     const v1;
     v1 = 1 + 1;
  }
  
  $ dune exec ast_gen -f input-code-2.js
  const f;
  f = function () {
     const v1;
     v1 = 1 + 1;
  }
  module.exports = f;
  
