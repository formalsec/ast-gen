  $ ast_gen input-code-1.js -o out; cat out/code/input-code-1.js; echo; rm -fr out;
  let foo;
  foo = function (index) {
     let v1;
     v1 = yield index;
  }
  
  $ ast_gen input-code-2.js -o out; cat out/code/input-code-2.js; echo; rm -fr out;
  let foo;
  foo = function (index) {
     let v1;
     let v2;
     v2 = index;
     index = index + 1;
     v1 = yield v2;
  }
  
