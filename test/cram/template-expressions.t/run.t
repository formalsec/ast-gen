  $ dune exec ast_gen -f input-code-1.js
  let x;
  x = `string`;
  
  $ dune exec ast_gen -f input-code-2.js
  let x;
  x = `string` + `concat`;
  
  $ dune exec ast_gen -f input-code-3.js
  let x;
  x = `template ${expr}`;
  
  $ dune exec ast_gen -f input-code-4.js
  let x;
  x = `string`;
  let temp;
  const v1;
  v1 = x + 2;
  temp = `head template ${v1} end tail`;
  
  $ dune exec ast_gen -f input-code-5.js
  ast_gen: internal error, uncaught exception:
           Failure("Unknown expression type to normalize (object on (2, 17) to (2, 58))")
           
  [125]
