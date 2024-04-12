  $ dune exec ast_gen -f input-code-1.js
  let x;
  x = {  };
  
  $ dune exec ast_gen -f input-code-2.js
  let x;
  x = { p : 'p' };
  
  $ dune exec ast_gen -f input-code-3.js
  let v1;
  v1 = {  };
  v1;
  
  $ dune exec ast_gen -f input-code-4.js
  let v1;
  v1 = { x : 23 };
  v1;
  
  $ dune exec ast_gen -f input-code-5.js
  let v1;
  v1 = function () {
     let v2;
     v2 = this.x;
     return v2;
  }
  let v3;
  v3 = function (v) {
  }
  let v4;
  v4 = { x : 23,
        y : v1,
        y : v3 };
  v4;
  
  $ dune exec ast_gen -f input-code-6.js
  const v1;
  v1 = 23 + 19;
  let v2;
  v2 = { x : v1 };
  v2;
  
  $ dune exec ast_gen -f input-code-7.js
  let customer;
  let v1;
  v1 = { first : 'person' };
  customer = { name : v1,
        role : 'user' };
  
  $ dune exec ast_gen -f input-code-8.js
  var map;
  map = { '%r' : repo };
  
