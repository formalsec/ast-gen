  $ dune exec ast_gen -f input-code-1.js
  if (true) {
     const v1;
     v1 = 1 + 2;
     v1;
  }
  
  $ dune exec ast_gen -f input-code-2.js
  let x;
  x = 'Oi';
  const v1;
  v1 = x === 'Hey';
  if (v1) {
     let y;
     const v2;
     v2 = 1 + 2;
     y = v2 + 3;
  } else {
     let z;
     const v3;
     v3 = 1 + 2;
     z = v3 + 3;
  }
  
  $ dune exec ast_gen -f input-code-3.js
  const v1;
  v1 = x === y;
  if (v1) {
     let v2;
     v2 = alert("They are the same!");
     v2;
  }
  
  $ dune exec ast_gen -f input-code-4.js
  let x;
  x = 1;
  const v1;
  v1 = x > 0;
  if (v1) {
     y = x + 2;
  }
  
