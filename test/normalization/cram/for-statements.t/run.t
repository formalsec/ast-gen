  $ graphjs input-code-1.js -o out; cat out/code/input-code-1.js; echo; rm -fr out;
  let src;
  src = [];
  src["0"] = 1;
  src["1"] = 2;
  src["2"] = 3;
  let dest;
  dest = [];
  for (var v1 in src) {
     p = v1;
     x = src[p];
     y = dest[p];
  }
  
  $ graphjs input-code-2.js -o out; cat out/code/input-code-2.js; echo; rm -fr out;
  for (let v1 in src) {
     p = v1;
     x = src[p];
     y = dest[p];
  }
  
  $ graphjs input-code-3.js -o out; cat out/code/input-code-3.js; echo; rm -fr out;
  let extend;
  extend = function (dest, src) {
     for (var v1 in src) {
        p = v1;
        x = src[p];
        y = dest[p];
     }
  }
  
  $ graphjs input-code-4.js -o out; cat out/code/input-code-4.js; echo; rm -fr out;
  let iterable;
  iterable = [];
  iterable["0"] = 10;
  iterable["1"] = 20;
  iterable["2"] = 30;
  for (let v1 of iterable) {
     value = v1;
     let v2;
     v2 = console.log(value);
  }
  
  $ graphjs input-code-5.js -o out; cat out/code/input-code-5.js; echo; rm -fr out;
  for (let v1 of iterable) {
     key = v1[0];
     value = v1[1];
     let v2;
     v2 = console.log(value);
  }
  
