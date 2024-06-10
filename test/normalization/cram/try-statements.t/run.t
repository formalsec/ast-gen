  $ ast_gen input-code-1.js -o out; cat out/graph/normalized.js; echo; rm -fr out;
  try {
     let v1;
     v1 = 1 + 2;
  } catch (e){
     let v2;
     v2 = 1 + 2;
  }
  
  $ ast_gen input-code-2.js -o out; cat out/graph/normalized.js; echo; rm -fr out;
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
  
  $ ast_gen input-code-3.js -o out; cat out/graph/normalized.js; echo; rm -fr out;
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
  
  $ ast_gen input-code-4.js -o out; cat out/graph/normalized.js; echo; rm -fr out;
  let f;
  f = function (x) {
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
  
