  $ graphjs2 input-code-1.js -o out; cat out/code/input-code-1.js; echo; rm -fr out;
  if (true) {
     let v1;
     v1 = 1 + 2;
     v1;
  }
  
  $ graphjs2 input-code-2.js -o out; cat out/code/input-code-2.js; echo; rm -fr out;
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
  
  $ graphjs2 input-code-3.js -o out; cat out/code/input-code-3.js; echo; rm -fr out;
  let v1;
  v1 = x === y;
  if (v1) {
     let v2;
     v2 = alert("They are the same!");
     v2;
  }
  
  $ graphjs2 input-code-4.js -o out; cat out/code/input-code-4.js; echo; rm -fr out;
  const x;
  x = 1;
  let y;
  let v1;
  v1 = x > 0;
  if (v1) {
     y = x + 2;
  }
  
