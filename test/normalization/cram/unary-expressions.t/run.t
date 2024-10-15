  $ graphjs2 input-code-1.js -o out; cat out/code/input-code-1.js; echo; rm -fr out;
  let v1;
  v1 = !false;
  v1;
  
  $ graphjs2 input-code-2.js -o out; cat out/code/input-code-2.js; echo; rm -fr out;
  const x;
  x = 0;
  let v1;
  v1 = Number(x);
  x = v1 + 1;
  v1;
  
  $ graphjs2 input-code-3.js -o out; cat out/code/input-code-3.js; echo; rm -fr out;
  let f;
  f = function (x) {
     let v1;
     v1 = x.y;
     let v2;
     v2 = Number(v1);
     let v3;
     v3 = v2 + 1;
     x.y = v3;
     v2;
     let v4;
     v4 = x.y;
     let v5;
     v5 = eval(v4);
     v5;
  }
  
