  $ ast_gen input-code-1.js
  let z;
  z = function () {
     let v1;
     v1 = 1 + 1;
  }
  
  $ ast_gen input-code-2.js
  let f;
  f = function () {
     let v1;
     v1 = 1 + 1;
  }
  module.exports = f;
  
