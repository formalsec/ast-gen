  $ graphjs2 input-code-1.js -o out; cat out/code/input-code-1.js; echo; rm -fr out;
  while (false) {
     let v1;
     v1 = 1 + 2;
  }
  
  $ graphjs2 input-code-2.js -o out; cat out/code/input-code-2.js; echo; rm -fr out;
  let x;
  x = 0;
  let v1;
  v1 = x < 1;
  while (v1) {
     let v2;
     v2 = Number(x);
     x = v2 + 1;
     v1 = x < 1;
  }
  
  $ graphjs2 input-code-3.js -o out; cat out/code/input-code-3.js; echo; rm -fr out;
  let x;
  x = 0;
  let v1;
  v1 = true;
  while (v1) {
     let v2;
     v2 = Number(x);
     x = v2 + 1;
     v1 = x < 1;
  }
  
  $ graphjs2 input-code-4.js -o out; cat out/code/input-code-4.js; echo; rm -fr out;
  let x;
  x = 0;
  let v1;
  v1 = true;
  while (v1) {
     let v2;
     v2 = Number(x);
     x = v2 + 1;
     break;
     v1 = x < 1;
  }
  
  $ graphjs2 input-code-5.js -o out; cat out/code/input-code-5.js; echo; rm -fr out;
  var i;
  i = 0;
  let v1;
  v1 = i < 10;
  while (v1) {
     let v3;
     v3 = alert(i);
     let v2;
     v2 = Number(i);
     i = v2 + 1;
     v1 = i < 10;
  }
  
  $ graphjs2 input-code-6.js -o out; cat out/code/input-code-6.js; echo; rm -fr out;
  var i;
  i = 0;
  let v1;
  v1 = i < 10;
  while (v1) {
     let v3;
     v3 = alert(i);
     let v2;
     v2 = Number(i);
     i = v2 + 1;
     v1 = i < 10;
  }
  
