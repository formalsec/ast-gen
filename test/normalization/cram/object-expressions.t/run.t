  $ ast_gen input-code-1.js -o out; cat out/code/input-code-1.js; echo; rm -fr out;
  let x;
  x = {};
  
  $ ast_gen input-code-2.js -o out; cat out/code/input-code-2.js; echo; rm -fr out;
  let x;
  x = {};
  x.p = 'p';
  
  $ ast_gen input-code-3.js -o out; cat out/code/input-code-3.js; echo; rm -fr out;
  let v1;
  v1 = {};
  
  $ ast_gen input-code-4.js -o out; cat out/code/input-code-4.js; echo; rm -fr out;
  let v1;
  v1 = {};
  v1.x = 23;
  
  $ ast_gen input-code-5.js -o out; cat out/code/input-code-5.js; echo; rm -fr out;
  let v1;
  v1 = {};
  v1.x = 23;
  let v2;
  v2 = function () {
     let v3;
     v3 = this.x;
     return v3;
  }
  let v4;
  v4 = {};
  v4.get = v2;
  let v5;
  v5 = Object.defineProperty(v1, "y", v4);
  let v6;
  v6 = function (v) {
  }
  let v7;
  v7 = {};
  v7.set = v6;
  let v8;
  v8 = Object.defineProperty(v1, y, v7);
  
  $ ast_gen input-code-6.js -o out; cat out/code/input-code-6.js; echo; rm -fr out;
  let v1;
  v1 = {};
  let v2;
  v2 = 23 + 19;
  v1.x = v2;
  
  $ ast_gen input-code-7.js -o out; cat out/code/input-code-7.js; echo; rm -fr out;
  let customer;
  customer = {};
  let v1;
  v1 = {};
  v1.first = 'person';
  customer.name = v1;
  customer.role = 'user';
  
  $ ast_gen input-code-8.js -o out; cat out/code/input-code-8.js; echo; rm -fr out;
  var map;
  map = {};
  map["%r"] = repo;
  
