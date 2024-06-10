  $ ast_gen input-code-1.js
  let x;
  x = {};
  
  $ ast_gen input-code-2.js
  let x;
  x = {};
  x.p = 'p';
  
  $ ast_gen input-code-3.js
  let v1;
  v1 = {};
  
  $ ast_gen input-code-4.js
  let v1;
  v1 = {};
  v1.x = 23;
  
  $ ast_gen input-code-5.js
  let v1;
  v1 = {};
  v1.x = 23;
  let v2;
  v2 = function () {
     let v3;
     v3 = this.x;
     return v3;
  }
  v1.y = v2;
  let v4;
  v4 = function (v) {
  }
  v1.y = v4;
  
  $ ast_gen input-code-6.js
  let v1;
  v1 = {};
  let v2;
  v2 = 23 + 19;
  v1.x = v2;
  
  $ ast_gen input-code-7.js
  let customer;
  customer = {};
  let v1;
  v1 = {};
  v1.first = 'person';
  customer.name = v1;
  customer.role = 'user';
  
  $ ast_gen input-code-8.js
  var map;
  map = {};
  map["%r"] = repo;
  
