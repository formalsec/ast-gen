  $ dune exec ast_gen -f input-code-1.js
  let f;
  f = function (arg1) {
  }
  
  $ dune exec ast_gen -f input-code-2.js
  ast_gen: internal error, uncaught exception:
           Failure("restelement not implemented")
           
  [125]
  $ dune exec ast_gen -f input-code-3.js
  ast_gen: internal error, uncaught exception:
           Failure("restelement not implemented")
           
  [125]
  $ dune exec ast_gen -f input-code-4.js
  ast_gen: internal error, uncaught exception:
           Failure("restelement not implemented")
           
  [125]
  $ dune exec ast_gen -f input-code-5.js
  let a;
  let v1;
  v1 = { a : 3 };
  a = v1.a;
  
  $ dune exec ast_gen -f input-code-6.js
  let a;
  let b;
  let v1;
  v1 = f();
  a = v1.a;
  b = v1.b;
  
  $ dune exec ast_gen -f input-code-7.js
  let a;
  let b;
  let v1;
  v1 = { a : 3 };
  a = v1.a;
  b = v1.b;
  
