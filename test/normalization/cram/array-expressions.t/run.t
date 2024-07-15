  $ ast_gen input-code-1.js -o out; cat out/code/normalized.js; echo; rm -fr out;
  let v1;
  v1 = [];
  let v2;
  v2 = [];
  v1["0"] = v2;
  let v3;
  v3 = 1 + 2;
  v1["1"] = v3;
  
  $ ast_gen input-code-2.js -o out; cat out/code/normalized.js; echo; rm -fr out;
  let v1;
  v1 = [];
  let v2;
  v2 = [];
  let v3;
  v3 = [];
  v2["0"] = v3;
  let v4;
  v4 = 1 + 2;
  v2["1"] = v4;
  v1["0"] = v2;
  let v5;
  v5 = eval('hello');
  v1["1"] = v5;
  
  $ ast_gen input-code-3.js -o out; cat out/code/normalized.js; echo; rm -fr out;
  let v1;
  v1 = [];
  v1["0"] = 23;
  v1["2"] = 452;
  
