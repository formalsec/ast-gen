  $ ast_gen input-code-1.js -o out; cat out/code/normalized.js; echo; rm -fr out;
  let f1;
  f1 = function () {
     let x;
     x = 0;
  }
  
  $ ast_gen input-code-2.js -o out; cat out/code/normalized.js; echo; rm -fr out;
  let f;
  f = function (x, y, z) {
     let v1;
     v1 = x;
     x = x + 1;
  }
  
  $ ast_gen input-code-3.js -o out; cat out/code/normalized.js; echo; rm -fr out;
  let count;
  count = function () {
     var i;
     i = 0;
     let v1;
     v1 = i < 10;
     while (v1) {
        let v2;
        v2 = alert(i);
        v1 = i < 10;
     }
  }
  
  $ ast_gen input-code-4.js -o out; cat out/code/normalized.js; echo; rm -fr out;
  let positive;
  positive = function (n) {
     let v1;
     v1 = n > 0;
     if (v1) {
        let v2;
        v2 = n * 2;
        let v3;
        v3 = alert(v2);
     }
  }
  
  $ ast_gen input-code-5.js -o out; cat out/code/normalized.js; echo; rm -fr out;
  let f;
  f = function () {
  }
  
