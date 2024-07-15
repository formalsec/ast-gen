  $ ast_gen input-code-1.js -o out; cat out/code/normalized.js; echo; rm -fr out;
  let v1;
  v1 = !false;
  
  $ ast_gen input-code-2.js -o out; cat out/code/normalized.js; echo; rm -fr out;
  const x;
  x = 0;
  let v1;
  v1 = x;
  x = x + 1;
  
  $ ast_gen input-code-3.js -o out; cat out/code/normalized.js; echo; rm -fr out;
  let f;
  f = function (x) {
     let v1;
     v1 = x.y;
     let v2;
     v2 = v1;
     v1 = v1 + 1;
     let v3;
     v3 = x.y;
     let v4;
     v4 = eval(v3);
  }
  
