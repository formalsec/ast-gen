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
     const v4;
     v4 = e["someValue"];
     const v5;
     v5 = x.v4;
     const v6;
     v6 = eval(v5);
     v6;
     try {
        const v2;
        v2 = f();
        v2;
     }    catch (e){
        const v4;
        v4 = e["someValue"];
        const v5;
        v5 = x.v4;
        const v6;
        v6 = eval(v5);
        v6;
     }   finally {
        const v3;
        v3 = alert('done');
        v3;
     }
  }
  
