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
  let v3;
  v3 = alert(e);
  v3;
  try {
     let v1;
     v1 = f();
     v1;
  } catch (e){
     let v3;
     v3 = alert(e);
     v3;
  }finally {
     let v2;
     v2 = alert("done");
     v2;
  }
  
  $ dune exec ast_gen -f input-code-4.js
  let f;
  f = function (x) {
     let v4;
     v4 = e["someValue"];
     let v5;
     v5 = x.v4;
     let v6;
     v6 = eval(v5);
     v6;
     try {
        let v2;
        v2 = f();
        v2;
     }    catch (e){
        let v4;
        v4 = e["someValue"];
        let v5;
        v5 = x.v4;
        let v6;
        v6 = eval(v5);
        v6;
     }   finally {
        let v3;
        v3 = alert('done');
        v3;
     }
  }
  
