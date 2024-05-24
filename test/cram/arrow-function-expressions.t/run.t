  $ dune exec ast_gen -f input-code-1.js
  let x;
  x = function (z) {
     const v1;
     v1 = z + 2;
     const v2;
     v2 = v1 + 3;
     return v2;
  }
  
  $ dune exec ast_gen -f input-code-2.js
  let x;
  x = function (z) {
     const v1;
     v1 = 1 + 2;
     const v2;
     v2 = v1 + 3;
     return v2;
  }
  
  $ dune exec ast_gen -f input-code-3.js
  const v1;
  v1 = function (z) {
     const v2;
     v2 = 1 + 2;
     const v3;
     v3 = v2 + 3;
     return v3;
  }
  a.b = v1;
  
  $ dune exec ast_gen -f input-code-4.js
  const a;
  const v1;
  v1 = [];
  v1["0"] = 0;
  v1["1"] = 1;
  v1["2"] = 2;
  v1["3"] = 3;
  const v2;
  v2 = function (_f) {
     const v3;
     v3 = _f == 1;
     return v3;
  }
  a = v1.find(v2);
  
  $ dune exec ast_gen -f input-code-5.js
  const a;
  const v1;
  v1 = [];
  v1["0"] = 0;
  v1["1"] = 1;
  v1["2"] = 2;
  v1["3"] = 3;
  const v2;
  v2 = function (_f) {
     const v3;
     v3 = _f == 1;
     return v3;
  }
  a = v1.find(v2);
  
