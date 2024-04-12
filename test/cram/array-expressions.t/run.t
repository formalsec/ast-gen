  $ dune exec ast_gen -f input-code-1.js
  let v1;
  v1 = [];
  const v2;
  v2 = 1 + 2;
  let v3;
  v3 = [v1, 
        v2];
  v3;
  
  $ dune exec ast_gen -f input-code-2.js
  let v1;
  v1 = [];
  const v2;
  v2 = 1 + 2;
  let v3;
  v3 = [v1, 
        v2];
  let v4;
  v4 = eval('hello');
  let v5;
  v5 = [v3, 
        v4];
  v5;
  
  $ dune exec ast_gen -f input-code-3.js
  ast_gen: internal error, uncaught exception:
           Failure("normalize array element case not defined")
           
  [125]
