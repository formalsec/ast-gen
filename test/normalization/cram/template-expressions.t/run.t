  $ graphjs2 input-code-1.js -o out; cat out/code/input-code-1.js; echo; rm -fr out;
  const x;
  x = `string`;
  

  $ graphjs2 input-code-2.js -o out; cat out/code/input-code-2.js; echo; rm -fr out;
  const x;
  x = `string` + `concat`;
  

  $ graphjs2 input-code-3.js -o out; cat out/code/input-code-3.js; echo; rm -fr out;
  const x;
  x = `template ${expr}`;
  

  $ graphjs2 input-code-4.js -o out; cat out/code/input-code-4.js; echo; rm -fr out;
  const x;
  x = `string`;
  const temp;
  let v1;
  v1 = x + 2;
  temp = `head template ${v1} end tail`;
  

  $ graphjs2 input-code-5.js -o out 2>&1 | grep "Failure" && cat out/code/input-code-5.js && echo && rm -fr out
            Failure("[ERROR] Unknown expression type to normalize (object on (9, 15) to (9, 60))")
  cat: out/code/input-code-5.js: No such file or directory
  [1]

x
