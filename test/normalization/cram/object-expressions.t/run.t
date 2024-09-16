  $ graphjs2 input-code-1.js -o out; cat out/code/input-code-1.js; echo; rm -fr out;
  let x;
  x = {};
  
  $ graphjs2 input-code-2.js -o out; cat out/code/input-code-2.js; echo; rm -fr out;
  let x;
  x = {};
  x.p = 'p';
  
  $ graphjs2 input-code-3.js -o out; cat out/code/input-code-3.js; echo; rm -fr out;
  let v1;
  v1 = {};
  
  $ graphjs2 input-code-4.js -o out; cat out/code/input-code-4.js; echo; rm -fr out;
  let v1;
  v1 = {};
  v1.x = 23;
  
  $ graphjs2 input-code-5.js -o out; cat out/code/input-code-5.js; echo; rm -fr out;
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
  
  $ graphjs2 input-code-6.js -o out; cat out/code/input-code-6.js; echo; rm -fr out;
  let v1;
  v1 = {};
  let v2;
  v2 = 23 + 19;
  v1.x = v2;
  
  $ graphjs2 input-code-7.js -o out; cat out/code/input-code-7.js; echo; rm -fr out;
  let customer;
  customer = {};
  let v1;
  v1 = {};
  v1.first = 'person';
  customer.name = v1;
  customer.role = 'user';
  
  $ graphjs2 input-code-8.js -o out; cat out/code/input-code-8.js; echo; rm -fr out;
  var map;
  map = {};
  map["%r"] = repo;
  
