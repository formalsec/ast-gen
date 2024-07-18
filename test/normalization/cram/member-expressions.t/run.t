  $ ast_gen input-code-1.js -o out; cat out/code/input-code-1.js; echo; rm -fr out;
  let x;
  x = {};
  x.p = 'p';
  let y;
  y = x.p;
  
  $ ast_gen input-code-2.js -o out; cat out/code/input-code-2.js; echo; rm -fr out;
  const y;
  let v1;
  v1 = f();
  y = x[v1];
  
