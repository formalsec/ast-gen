  $ dune exec ast_gen -f input-code-1.js
  let v;
  Foo = function () {
  }
  let v3;
  v3 = new Bar();
  Foo.prototype = v3;
  v = Foo;
  
  $ dune exec ast_gen -f input-code-2.js
  let v;
  Foo = function () {
  }
  let v3;
  v3 = new Bar();
  Foo.prototype = v3;
  const v4;
  v4 = function () {
  }
  v3.foo = v4;
  v = Foo;
  
  $ dune exec ast_gen -f input-code-3.js
  let v;
  let Foo;
  Foo = function () {
     const v5;
     v5 = super();
     v5;
  }
  let v3;
  v3 = new Bar();
  Foo.prototype = v3;
  const v6;
  v6 = function () {
     const v7;
     v7 = 1 + 2;
     v7;
  }
  v3.foo = v6;
  v = Foo;
  
