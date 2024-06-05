  $ dune exec ast_gen -f input-code-1.js
  const x;
  let v1;
  v1 = 1 + 2;
  x = eval('1 + 2', v1);
  
  $ dune exec ast_gen -f input-code-2.js
  let v1;
  v1 = 23 + 19;
  let v2;
  v2 = Math.min(23, v1);
  
  $ dune exec ast_gen -f input-code-3.js
  let v1;
  v1 = f();
  let v2;
  v2 = v1();
  
  $ dune exec ast_gen -f input-code-4.js
  cmd = [];
  cmd["0"] = "1";
  cmd["1"] = "2";
  let v1;
  v1 = cmd.push("3");
  let v2;
  v2 = cmd.join(" ");
  let v3;
  v3 = console.log(v2);
  
