  $ graphjs2 input-code-1.js -o out; cat out/code/input-code-1.js; echo; rm -fr out;
  let v1;
  v1 = new Array(2);
  let v2;
  v2 = new Array(0);
  v1["0"] = v2;
  let v3;
  v3 = 1 + 2;
  v1["1"] = v3;
  v1;
  
  $ graphjs2 input-code-2.js -o out; cat out/code/input-code-2.js; echo; rm -fr out;
  let v1;
  v1 = new Array(2);
  let v2;
  v2 = new Array(2);
  let v3;
  v3 = new Array(0);
  v2["0"] = v3;
  let v4;
  v4 = 1 + 2;
  v2["1"] = v4;
  v1["0"] = v2;
  let v5;
  v5 = eval('hello');
  v1["1"] = v5;
  v1;
  
  $ graphjs2 input-code-3.js -o out; cat out/code/input-code-3.js; echo; rm -fr out;
  let v1;
  v1 = new Array(3);
  v1["0"] = 23;
  v1["2"] = 452;
  v1;
  
