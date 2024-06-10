  $ ast_gen input-code-1.js
  while (false) {
     let v1;
     v1 = 1 + 2;
  }
  
  $ ast_gen input-code-2.js
  let x;
  x = 0;
  let v1;
  v1 = x < 1;
  while (v1) {
     let v2;
     v2 = x;
     x = x + 1;
     v1 = x < 1;
  }
  
  $ ast_gen input-code-3.js
  let x;
  x = 0;
  let v1;
  v1 = true;
  while (v1) {
     let v2;
     v2 = x;
     x = x + 1;
     v1 = x < 1;
  }
  
  $ ast_gen input-code-4.js
  let x;
  x = 0;
  let v1;
  v1 = true;
  while (v1) {
     let v2;
     v2 = x;
     x = x + 1;
     break;
     v1 = x < 1;
  }
  
  $ ast_gen input-code-5.js
  var i;
  i = 0;
  let v1;
  v1 = i < 10;
  while (v1) {
     let v3;
     v3 = alert(i);
     let v2;
     i = i + 1;
     v2 = i;
     v1 = i < 10;
  }
  
  $ ast_gen input-code-6.js
  var i;
  i = 0;
  let v1;
  v1 = i < 10;
  while (v1) {
     let v3;
     v3 = alert(i);
     let v2;
     i = i + 1;
     v2 = i;
     v1 = i < 10;
  }
  
