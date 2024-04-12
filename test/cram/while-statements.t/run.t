  $ dune exec ast_gen -f input-code-1.js
  while (false) {
     const v1;
     v1 = 1 + 2;
     v1;
  }
  
  $ dune exec ast_gen -f input-code-2.js
  let x;
  x = 0;
  const v1;
  v1 = x < 1;
  while (v1) {
     const v2;
     v2 = x++;
     v2;
  }
  
  $ dune exec ast_gen -f input-code-3.js
  let x;
  x = 0;
  let v1;
  v1 = true;
  while (v1) {
     const v2;
     v2 = x++;
     v2;
     v1 = x < 1;
  }
  
  $ dune exec ast_gen -f input-code-4.js
  let x;
  x = 0;
  let v1;
  v1 = true;
  while (v1) {
     const v2;
     v2 = x++;
     v2;
     break;
     v1 = x < 1;
  }
  
  $ dune exec ast_gen -f input-code-5.js
  var i;
  i = 0;
  const v1;
  v1 = i < 10;
  while (v1) {
     const v3;
     v3 = alert(i);
     v3;
     const v2;
     v2 = ++i;
  }
  
  $ dune exec ast_gen -f input-code-6.js
  var i;
  i = 0;
  const v1;
  v1 = i < 10;
  while (v1) {
     const v3;
     v3 = alert(i);
     v3;
     const v2;
     v2 = ++i;
  }
  
