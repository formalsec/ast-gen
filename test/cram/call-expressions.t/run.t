  $ dune exec ast_gen -f input-code-1.js
  const x;
  const v1;
  v1 = 1 + 2;
  x = eval('1 + 2', v1);
  
  $ dune exec ast_gen -f input-code-2.js
  const v1;
  v1 = 23 + 19;
  const v2;
  v2 = Math.min(23, v1);
  v2;
  
  $ dune exec ast_gen -f input-code-3.js
  const v1;
  v1 = f();
  const v2;
  v2 = v1();
  v2;
  
  $ dune exec ast_gen -f input-code-4.js
  cmd = ["1", 
        "2"];
  const v1;
  v1 = cmd.push("3");
  v1;
  const v2;
  v2 = cmd.join(" ");
  const v3;
  v3 = console.log(v2);
  v3;
  
