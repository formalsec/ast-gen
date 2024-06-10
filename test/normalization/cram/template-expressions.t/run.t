  $ ast_gen input-code-1.js
  const x;
  x = `string`;
  
  $ ast_gen input-code-2.js
  const x;
  x = `string` + `concat`;
  
  $ ast_gen input-code-3.js
  const x;
  x = `template ${expr}`;
  
  $ ast_gen input-code-4.js
  const x;
  x = `string`;
  const temp;
  let v1;
  v1 = x + 2;
  temp = `head template ${v1} end tail`;
  
  $ ast_gen input-code-5.js
  ast_gen: internal error, uncaught exception:
           Failure("Unknown expression type to normalize (object on (9, 15) to (9, 60))")
           
  [125]
