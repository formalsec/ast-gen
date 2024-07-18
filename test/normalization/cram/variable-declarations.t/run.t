  $ ast_gen input-code-1.js -o out; cat out/code/input-code-1.js; echo; rm -fr out;
  let x;
  x = 1;
  
  $ ast_gen input-code-2.js -o out; cat out/code/input-code-2.js; echo; rm -fr out;
  let x;
  x = 1 + 2;
  
  $ ast_gen input-code-3.js -o out; cat out/code/input-code-3.js; echo; rm -fr out;
  let x;
  let y;
  x = 1 + 2;
  y = 3;
  
  $ ast_gen input-code-4.js -o out; cat out/code/input-code-4.js; echo; rm -fr out;
  var x;
  var y;
  y = x + 1;
  
