  $ ast_gen input-code-1.js -o out; cat out/graph/normalized.js; echo; rm -fr out;
  let v1;
  v1 = 1 + 2;
  
  $ ast_gen input-code-2.js -o out; cat out/graph/normalized.js; echo; rm -fr out;
  let v1;
  v1 = x + y;
  
  $ ast_gen input-code-3.js -o out; cat out/graph/normalized.js; echo; rm -fr out;
  x = y + z;
  
  $ ast_gen input-code-4.js -o out; cat out/graph/normalized.js; echo; rm -fr out;
  const x;
  x = y + z;
  
