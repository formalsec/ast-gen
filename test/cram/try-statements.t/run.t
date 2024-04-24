  $ dune exec ast_gen -f input-code-1.js
  const v2;
  v2 = 1 + 2;
  v2;
  try {
     const v1;
     v1 = 1 + 2;
     v1;
  } catch (e){
     const v2;
     v2 = 1 + 2;
     v2;
  }
  
  $ dune exec ast_gen -f input-code-2.js
  const v3;
  v3 = 1 + 2;
  v3;
  try {
     const v1;
     v1 = 1 + 2;
     v1;
  } catch (e){
     const v3;
     v3 = 1 + 2;
     v3;
  }finally {
     const v2;
     v2 = 1 + 2;
     v2;
  }
  
  $ dune exec ast_gen -f input-code-3.js
  const v3;
  v3 = alert(e);
  v3;
  try {
     const v1;
     v1 = f();
     v1;
  } catch (e){
     const v3;
     v3 = alert(e);
     v3;
  }finally {
     const v2;
     v2 = alert("done");
     v2;
  }
  
  $ dune exec ast_gen -f input-code-4.js
  const f;
  f = function (x) {
     const v3;
     v3 = e["someValue"];
     const v4;
     v4 = x[v3];
     const v5;
     v5 = eval(v4);
     v5;
     try {
        const v1;
        v1 = f();
        v1;
     }    catch (e){
        const v3;
        v3 = e["someValue"];
        const v4;
        v4 = x[v3];
        const v5;
        v5 = eval(v4);
        v5;
     }   finally {
        const v2;
        v2 = alert('done');
        v2;
     }
  }
  
