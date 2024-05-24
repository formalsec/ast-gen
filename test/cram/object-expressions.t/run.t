  $ dune exec ast_gen -f input-code-1.js
  let x;
  x = {};
  
  $ dune exec ast_gen -f input-code-2.js
  let x;
  x = {};
  x.p = 'p';
  
  $ dune exec ast_gen -f input-code-3.js
  const v1;
  v1 = {};
  
  $ dune exec ast_gen -f input-code-4.js
  const v1;
  v1 = {};
  v1.x = 23;
  
  $ dune exec ast_gen -f input-code-5.js
  const v1;
  v1 = {};
  v1.x = 23;
  const v2;
  v2 = function () {
     const v3;
     v3 = this.x;
     return v3;
  }
  v1.y = v2;
  const v4;
  v4 = function (v) {
  }
  v1.y = v4;
  
  $ dune exec ast_gen -f input-code-6.js
  const v1;
  v1 = {};
  const v2;
  v2 = 23 + 19;
  v1.x = v2;
  
  $ dune exec ast_gen -f input-code-7.js
  let customer;
  customer = {};
  const v1;
  v1 = {};
  v1.first = 'person';
  customer.name = v1;
  customer.role = 'user';
  
  $ dune exec ast_gen -f input-code-8.js
  var map;
  map = {};
  map["%r"] = repo;
  
