  $ graphjs input-code-1.js -o out; cat out/code/input-code-1.js; echo; rm -fr out;
  let z;
  z = function () {
     let v1;
     v1 = 1 + 1;
  }
  
  $ graphjs input-code-2.js -o out; cat out/code/input-code-2.js; echo; rm -fr out;
  let f;
  f = function () {
     let v1;
     v1 = 1 + 1;
  }
  module.exports = f;
  
