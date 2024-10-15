  $ graphjs2 input-code-1.js -o out; cat out/code/input-code-1.js; echo; rm -fr out;
  let x;
  x = function (z) {
     let v1;
     v1 = z + 2;
     let v2;
     v2 = v1 + 3;
     return v2;
  }
  

  $ graphjs2 input-code-2.js -o out; cat out/code/input-code-2.js; echo; rm -fr out;
  let x;
  x = function (z) {
     let v1;
     v1 = 1 + 2;
     let v2;
     v2 = v1 + 3;
     return v2;
  }
  

  $ graphjs2 input-code-3.js -o out; cat out/code/input-code-3.js; echo; rm -fr out;
  let v1;
  v1 = function (z) {
     let v2;
     v2 = 1 + 2;
     let v3;
     v3 = v2 + 3;
     return v3;
  }
  a.b = v1;
  

  $ graphjs2 input-code-4.js -o out; cat out/code/input-code-4.js; echo; rm -fr out;
  const a;
  let v1;
  v1 = new Array(4);
  v1["0"] = 0;
  v1["1"] = 1;
  v1["2"] = 2;
  v1["3"] = 3;
  let v2;
  v2 = function (_f) {
     let v3;
     v3 = _f == 1;
     return v3;
  }
  a = v1.find(v2);
  

  $ graphjs2 input-code-5.js -o out; cat out/code/input-code-5.js; echo; rm -fr out;
  const a;
  let v1;
  v1 = new Array(4);
  v1["0"] = 0;
  v1["1"] = 1;
  v1["2"] = 2;
  v1["3"] = 3;
  let v2;
  v2 = function (_f) {
     let v3;
     v3 = _f == 1;
     return v3;
  }
  a = v1.find(v2);
  

