  $ dune exec ast_gen -f input-code-1.js
  const x;
  const v1;
  v1 = 1 + 2;
  x = eval('1 + 2', v1);
  
  $ dune exec ast_gen -f input-code-2.js
  const v1;
  v1 = Math.min;
  const v2;
  v2 = 23 + 19;
  const v3;
  v3 = v1(23, v2);
  v3;
  
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
  v1 = cmd.push;
  const v2;
  v2 = v1("3");
  v2;
  const v3;
  v3 = console.log;
  const v4;
  v4 = cmd.join;
  const v5;
  v5 = v4(" ");
  const v6;
  v6 = v3(v5);
  v6;
  
