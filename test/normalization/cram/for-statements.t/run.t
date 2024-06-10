  $ ast_gen input-code-1.js -o out; cat out/graph/normalized.js; echo; rm -fr out;
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
  
  $ ast_gen input-code-2.js -o out; cat out/graph/normalized.js; echo; rm -fr out;
  for (let v1 in src) {
     p = v1;
     x = src[p];
     y = dest[p];
  }
  
  $ ast_gen input-code-3.js -o out; cat out/graph/normalized.js; echo; rm -fr out;
  let extend;
  extend = function (dest, src) {
     for (var p in src) {
        x = src[p];
        y = dest[p];
     }
  }
  
  $ ast_gen input-code-4.js -o out; cat out/graph/normalized.js; echo; rm -fr out;
  let iterable;
  iterable = [];
  iterable["0"] = 10;
  iterable["1"] = 20;
  iterable["2"] = 30;
  for (let value of iterable) {
     let v1;
     v1 = console.log(value);
  }
  
  $ ast_gen input-code-5.js -o out; cat out/graph/normalized.js; echo; rm -fr out;
  ast_gen: internal error, uncaught exception:
           Failure("hd")
           
  cat: out/graph/normalized.js: No such file or directory
  
