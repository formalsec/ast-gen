  $ dune exec ast_gen -f input-code-1.js
  let v2;
  v2 = 1 + 2;
  try {
     let v1;
     v1 = 1 + 2;
  } catch (e){
     let v2;
     v2 = 1 + 2;
  }
  
  $ dune exec ast_gen -f input-code-2.js
  let v3;
  v3 = 1 + 2;
  try {
     let v1;
     v1 = 1 + 2;
  } catch (e){
     let v3;
     v3 = 1 + 2;
  }finally {
     let v2;
     v2 = 1 + 2;
  }
  
  $ dune exec ast_gen -f input-code-3.js
  let v3;
  v3 = alert(e);
  try {
     let v1;
     v1 = f();
  } catch (e){
     let v3;
     v3 = alert(e);
  }finally {
     let v2;
     v2 = alert("done");
  }
  
  $ dune exec ast_gen -f input-code-4.js
  let f;
  f = function (x) {
     let v3;
     v3 = e["someValue"];
     let v4;
     v4 = x[v3];
     let v5;
     v5 = eval(v4);
     try {
        let v1;
        v1 = f();
     }    catch (e){
        let v3;
        v3 = e["someValue"];
        let v4;
        v4 = x[v3];
        let v5;
        v5 = eval(v4);
     }   finally {
        let v2;
        v2 = alert('done');
     }
  }
  
