  $ graphjs2 input-code-1.js -o out; cat out/code/input-code-1.js; echo; rm -fr out;
  let v;
  Foo = function () {
  }
  let v2;
  v2 = new Bar();
  Foo.prototype = v2;
  v = Foo;
  
  $ graphjs2 input-code-2.js -o out; cat out/code/input-code-2.js; echo; rm -fr out;
  let v;
  Foo = function () {
  }
  let v2;
  v2 = new Bar();
  Foo.prototype = v2;
  let v3;
  v3 = function () {
  }
  v2.foo = v3;
  v = Foo;
  
  $ graphjs2 input-code-3.js -o out; cat out/code/input-code-3.js; echo; rm -fr out;
  let v;
  Foo = function () {
     let v3;
     v3 = this.prototype;
     let v4;
     v4 = v3.constructor;
     let v5;
     v5 = v4();
     v5;
  }
  let v2;
  v2 = new Bar();
  Foo.prototype = v2;
  let v6;
  v6 = function () {
     let v7;
     v7 = 1 + 2;
     v7;
  }
  v2.foo = v6;
  v = Foo;
  
