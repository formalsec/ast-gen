  $ dune exec ast_gen -f input-code-1.js
  Foo = function () {
  }
  let v3;
  v3 = new Bar();
  Foo.prototype = v3;
  
  $ dune exec ast_gen -f input-code-2.js
  Foo = function () {
  }
  let v3;
  v3 = new Bar();
  Foo.prototype = v3;
  const v4;
  v4 = function () {
  }
  v3.foo = v4;
  
  $ dune exec ast_gen -f input-code-3.js
  let Foo;
  Foo = function () {
     let v5;
     v5 = this.prototype;
     let v6;
     v6 = v5.constructor;
     const v7;
     v7 = v6();
     v7;
  }
  let v3;
  v3 = new Bar();
  Foo.prototype = v3;
  const v8;
  v8 = function () {
     const v9;
     v9 = 1 + 2;
     v9;
  }
  v3.foo = v8;
  
