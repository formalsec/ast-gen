  $ ast_gen input-code-1.js -o out; cat out/graph/normalized.js; echo; rm -fr out;
  const x;
  let v1;
  v1 = 1 + 2;
  x = eval('1 + 2', v1);
  
  $ ast_gen input-code-2.js -o out; cat out/graph/normalized.js; echo; rm -fr out;
  let v1;
  v1 = 23 + 19;
  let v2;
  v2 = Math.min(23, v1);
  
  $ ast_gen input-code-3.js -o out; cat out/graph/normalized.js; echo; rm -fr out;
  let v1;
  v1 = f();
  let v2;
  v2 = v1();
  
  $ ast_gen input-code-4.js -o out; cat out/graph/normalized.js; echo; rm -fr out;
  cmd = [];
  cmd["0"] = "1";
  cmd["1"] = "2";
  let v1;
  v1 = cmd.push("3");
  let v2;
  v2 = cmd.join(" ");
  let v3;
  v3 = console.log(v2);
  
