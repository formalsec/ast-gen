  $ dune exec ast_gen -f input-code-1.js
  let foo;
  foo = function (index) {
     yield index;
  }
  
  $ dune exec ast_gen -f input-code-2.js
  let foo;
  foo = function (index) {
     let v1;
     v1 = index + 1;
     yield v1;
  }
  
