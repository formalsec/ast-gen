  $ graphjs input-code-1.js -o out; cat out/code/input-code-1.js; echo; rm -fr out;
  while (false) {
     let v1;
     v1 = 1 + 2;
  }
  
  $ graphjs input-code-2.js -o out; cat out/code/input-code-2.js; echo; rm -fr out;
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
  
  $ graphjs input-code-3.js -o out; cat out/code/input-code-3.js; echo; rm -fr out;
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
  
  $ graphjs input-code-4.js -o out; cat out/code/input-code-4.js; echo; rm -fr out;
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
  
  $ graphjs input-code-5.js -o out; cat out/code/input-code-5.js; echo; rm -fr out;
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
  
  $ graphjs input-code-6.js -o out; cat out/code/input-code-6.js; echo; rm -fr out;
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
  
