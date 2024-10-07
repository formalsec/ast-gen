  $ graphjs input-code-1.js -o out; cat out/code/input-code-1.js; echo; rm -fr out;
  let f;
  f = function (arg1) {
  }
  
  $ graphjs input-code-2.js -o out; cat out/code/input-code-2.js; echo; rm -fr out;
  let param1;
  let otherParams;
  let v1;
  v1 = a + b;
  param1 = v1[0];
  let v2;
  v2 = v1.slice;
  otherParams = v2(1);
  
  $ graphjs input-code-3.js -o out; cat out/code/input-code-3.js; echo; rm -fr out;
  let array;
  let otherParams;
  let v1;
  v1 = f();
  array = v1[0];
  let v2;
  v2 = v1.slice;
  otherParams = v2(1);
  
  $ graphjs input-code-4.js -o out; cat out/code/input-code-4.js; echo; rm -fr out;
  let array;
  let otherParams;
  let v1;
  v1 = f();
  array = v1[0];
  let v2;
  v2 = v1.slice;
  otherParams = v2(1);
  
  $ graphjs input-code-5.js -o out; cat out/code/input-code-5.js; echo; rm -fr out;
  const a;
  let v1;
  v1 = {};
  v1.a = 3;
  a = v1.a;
  
  $ graphjs input-code-6.js -o out; cat out/code/input-code-6.js; echo; rm -fr out;
  const a;
  const b;
  let v1;
  v1 = f();
  a = v1.a;
  b = v1.b;
  
  $ graphjs input-code-7.js -o out; cat out/code/input-code-7.js; echo; rm -fr out;
  const a;
  const b;
  let v1;
  v1 = {};
  v1.a = 3;
  a = v1.a;
  b = v1.b;
  
