  $ dune exec ast_gen -f input-code-1.js
  let x;
  const v1;
  v1 = 1 + 2;
  x = eval('1 + 2', v1);
  x = x;
  
  $ dune exec ast_gen -f input-code-2.js
  let v1;
  v1 = Math.min;
  const v2;
  v2 = 23 + 19;
  let v3;
  v3 = v1(23, v2);
  v3;
  
  $ dune exec ast_gen -f input-code-3.js
  let v1;
  v1 = f();
  let v2;
  v2 = v1();
  v2;
  
  $ dune exec ast_gen -f input-code-4.js
  cmd = ["1", 
        "2"];
  let v2;
  v2 = cmd.push;
  let v3;
  v3 = v2("3");
  v3;
  let v4;
  v4 = console.log;
  let v5;
  v5 = cmd.join;
  let v6;
  v6 = v5(" ");
  let v7;
  v7 = v4(v6);
  v7;
  