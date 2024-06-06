  $ dune exec ast_gen -f input-code-1.js
  if (true) {
     let v1;
     v1 = 1 + 2;
  }
  
  $ dune exec ast_gen -f input-code-2.js
  let x;
  x = 'Oi';
  let v1;
  v1 = x === 'Hey';
  if (v1) {
     let y;
     let v2;
     v2 = 1 + 2;
     y = v2 + 3;
  } else {
     let z;
     let v3;
     v3 = 1 + 2;
     z = v3 + 3;
  }
  
  $ dune exec ast_gen -f input-code-3.js
  let v1;
  v1 = x === y;
  if (v1) {
     let v2;
     v2 = alert("They are the same!");
  }
  
  $ dune exec ast_gen -f input-code-4.js
  const x;
  x = 1;
  let y;
  let v1;
  v1 = x > 0;
  if (v1) {
     y = x + 2;
  }
  
