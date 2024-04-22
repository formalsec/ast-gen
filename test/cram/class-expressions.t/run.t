  $ dune exec ast_gen -f input-code-1.js
  let v;
  Foo = function () {
  }
  let v2;
  v2 = new Bar();
  Foo.prototype = v2;
  
  $ dune exec ast_gen -f input-code-2.js
  let v;
  Foo = function () {
  }
  let v2;
  v2 = new Bar();
  Foo.prototype = v2;
  const v3;
  v3 = function () {
  }
  v2.foo = v3;
  
  $ dune exec ast_gen -f input-code-3.js
  let v;
  Foo = function () {
     let v3;
     v3 = this.prototype;
     let v4;
     v4 = v3.constructor;
     const v5;
     v5 = v4();
     v5;
  }
  let v2;
  v2 = new Bar();
  Foo.prototype = v2;
  const v6;
  v6 = function () {
     const v7;
     v7 = 1 + 2;
     v7;
  }
  v2.foo = v6;
  
