  $ dune exec ast_gen -f input-code-1.js
  const v1;
  v1 = [];
  const v2;
  v2 = [];
  v1["0"] = v2;
  const v3;
  v3 = 1 + 2;
  v1["1"] = v3;
  
  $ dune exec ast_gen -f input-code-2.js
  const v1;
  v1 = [];
  const v2;
  v2 = [];
  const v3;
  v3 = [];
  v2["0"] = v3;
  const v4;
  v4 = 1 + 2;
  v2["1"] = v4;
  v1["0"] = v2;
  const v5;
  v5 = eval('hello');
  v1["1"] = v5;
  
  $ dune exec ast_gen -f input-code-3.js
  const v1;
  v1 = [];
  v1["0"] = 23;
  v1["2"] = 452;
  
