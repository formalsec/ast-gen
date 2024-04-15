  $ dune exec ast_gen -f input-code-1.js
  let status;
  status = (true) ? 'adult' : 'minor';
  
  $ dune exec ast_gen -f input-code-2.js
  let x;
  x = 6;
  let status;
  const v1;
  v1 = x === 6;
  const v2;
  v2 = 1 + 2;
  const v3;
  v3 = 1 + 2;
  const v4;
  v4 = v3 + 3;
  status = (v1) ? v2 : v4;
  
  $ dune exec ast_gen -f input-code-3.js
  let x;
  x = 0;
  const v1;
  v1 = x === 0;
  const v2;
  v2 = -1;
  x = (v1) ? v2 : 1;
  
  $ dune exec ast_gen -f input-code-4.js
  const v1;
  v1 = format('Wmic reported the following error: %s.', stderr);
  stderr = error + (stderr) ? v1 : 'Wmic reported no errors (stderr empty).';
  
