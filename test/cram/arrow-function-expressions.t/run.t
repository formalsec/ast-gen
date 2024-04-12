  $ dune exec ast_gen -f input-code-1.js
  let x;
  x = function (z) {
     const v2;
     v2 = z + 2;
     const v3;
     v3 = v2 + 3;
     return v3;
  }
  
  $ dune exec ast_gen -f input-code-2.js
  let x;
  x = function (z) {
     const v2;
     v2 = 1 + 2;
     const v3;
     v3 = v2 + 3;
     return v3;
  }
  
  $ dune exec ast_gen -f input-code-3.js
  ast_gen: internal error, uncaught exception:
           Failure("pattern not implemented")
           
  [125]
  $ dune exec ast_gen -f input-code-4.js
  let a;
  let v1;
  v1 = [0, 
        1, 
        2, 
        3];
  let v2;
  v2 = v1.find;
  let v3;
  v3 = function (_f) {
     const v4;
     v4 = _f == 1;
     return v4;
  }
  a = v2(v3);
  
  $ dune exec ast_gen -f input-code-5.js
  let a;
  let v1;
  v1 = [0, 
        1, 
        2, 
        3];
  let v2;
  v2 = v1.find;
  let v3;
  v3 = function (_f) {
     const v4;
     v4 = _f == 1;
     return v4;
  }
  a = v2(v3);
  
