  $ ast_gen input-code-1.js -o out; cat out/code/normalized.js; echo; rm -fr out;
  let foo;
  foo = function (index) {
     yield index;
  }
  
  $ ast_gen input-code-2.js -o out; cat out/code/normalized.js; echo; rm -fr out;
  let foo;
  foo = function (index) {
     let v1;
     v1 = index;
     index = index + 1;
     yield v1;
  }
  
