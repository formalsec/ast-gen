  $ dune exec ast_gen -f input-code-1.js
  let status;
  let v1;
  if (true) {
     v1 = 'adult';
  } else {
     v1 = 'minor';
  }
  status = v1;
  
  $ dune exec ast_gen -f input-code-2.js
  let x;
  x = 6;
  let status;
  let v1;
  const v2;
  v2 = x === 6;
  if (v2) {
     const v3;
     v3 = 1 + 2;
     v1 = v3;
  } else {
     const v4;
     v4 = 1 + 2;
     const v5;
     v5 = v4 + 3;
     v1 = v5;
  }
  status = v1;
  
  $ dune exec ast_gen -f input-code-3.js
  let x;
  x = 0;
  let v1;
  const v2;
  v2 = x === 0;
  if (v2) {
     const v3;
     v3 = -1;
     v1 = v3;
  } else {
     v1 = 1;
  }
  x = v1;
  
  $ dune exec ast_gen -f input-code-4.js
  let v1;
  if (stderr) {
     const v2;
     v2 = format('Wmic reported the following error: %s.', stderr);
     v1 = v2;
  } else {
     v1 = 'Wmic reported no errors (stderr empty).';
  }
  stderr = error + v1;
  
