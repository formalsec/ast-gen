  $ graphjs2 input-code-1.js -o out; cat out/code/input-code-1.js; echo; rm -fr out;
  let status;
  let v1;
  if (true) {
     v1 = 'adult';
  } else {
     v1 = 'minor';
  }
  status = v1;
  
  $ graphjs2 input-code-2.js -o out; cat out/code/input-code-2.js; echo; rm -fr out;
  let x;
  x = 6;
  let status;
  let v1;
  let v2;
  v2 = x === 6;
  if (v2) {
     let v3;
     v3 = 1 + 2;
     v1 = v3;
  } else {
     let v4;
     v4 = 1 + 2;
     let v5;
     v5 = v4 + 3;
     v1 = v5;
  }
  status = v1;
  
  $ graphjs2 input-code-3.js -o out; cat out/code/input-code-3.js; echo; rm -fr out;
  let x;
  x = 0;
  let v1;
  let v2;
  v2 = x === 0;
  if (v2) {
     let v3;
     v3 = -1;
     v1 = v3;
  } else {
     v1 = 1;
  }
  x = v1;
  
  $ graphjs2 input-code-4.js -o out; cat out/code/input-code-4.js; echo; rm -fr out;
  let v1;
  if (stderr) {
     let v2;
     v2 = format('Wmic reported the following error: %s.', stderr);
     v1 = v2;
  } else {
     v1 = 'Wmic reported no errors (stderr empty).';
  }
  stderr = error + v1;
  
