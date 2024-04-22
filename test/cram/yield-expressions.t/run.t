  $ dune exec ast_gen -f input-code-1.js
  const foo;
  foo = function (index) {
     yield index;
  }
  
  $ dune exec ast_gen -f input-code-2.js
  const foo;
  foo = function (index) {
     const v1;
     v1 = index++;
     yield v1;
  }
  
