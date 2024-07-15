  $ ast_gen input-code-1.js -o out; cat out/code/normalized.js; echo; rm -fr out;
  let z;
  z = function () {
     let v1;
     v1 = 1 + 1;
  }
  
  $ ast_gen input-code-2.js -o out; cat out/code/normalized.js; echo; rm -fr out;
  let f;
  f = function () {
     let v1;
     v1 = 1 + 1;
  }
  module.exports = f;
  
