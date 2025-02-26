  $ graphjs parse function.js
  function foo(bar, baz) {
    qux;
  }
  async function foo(bar, baz) {
    qux;
  }
  function* foo(bar, baz) {
    qux;
  }
  async function* foo(bar, baz) {
    qux;
  }

  $ graphjs parse class.js
  var Foo = function () {
    
  }
  let $v1 = Foo.prototype;
  $v1.constructor = Foo;
  var Foo = function (bar, baz) {
    this.bar = bar;
    this.baz = baz;
  }
  let $v2 = Foo.prototype;
  $v2.constructor = Foo;
  var Foo = function () {
    
  }
  let $v3 = Foo.prototype;
  $v3.constructor = Foo;
  $v3.bar = 10;
  let $v4 = function () {
    
  }
  $v3.baz = $v4;
  var Foo = function () {
    
  }
  let $v5 = Foo.prototype;
  $v5.constructor = Foo;
  Foo.bar = 10;
  let $v6 = function () {
    
  }
  Foo.baz = $v6;
  var Foo = function (baz) {
    let $v7 = this.__proto__;
    $v7 = $v7.__proto__;
    let $v8 = $v7.constructor(baz);
  }
  let $v9 = Foo.prototype;
  $v9.constructor = Foo;
  let $v10 = Bar.prototype;
  Foo.__proto__ = Bar;
  $v9.__proto__ = $v10;

  $ graphjs parse import.js
  import foo from "module";
  import "module";
  import "module";
  import { foo } from "module";
  import { foo } from "module";
  import { bar } from "module";
  import { baz } from "module";
  import { foo as bar } from "module";
  import { default as foo } from "module";
  import foo from "module";
  import { bar } from "module";
  import foo from "module";
  import { bar } from "module";
  import { baz as qux } from "module";
  import * as foo from "module";
  import foo from "module";
  import * as bar from "module";
  import foo from "./path/to/module.js";
  import foo from "/path/to/module.js";

  $ graphjs parse export.js
  var foo5;
  export { foo5 };
  var foo6 = 10;
  export { foo6 };
  var foo7 = 10;
  var bar7;
  export { foo7 };
  export { bar7 };
  let $v1 = {};
  $v1.foo8 = 10;
  $v1.bar8 = "abc";
  var foo8 = $v1.foo8;
  var bar8 = $v1.bar8;
  export { foo8 };
  export { bar8 };
  let $v2 = [];
  $v2[0] = 10;
  $v2[1] = "abc";
  var foo9 = $v2[0];
  var bar9 = $v2[1];
  export { foo9 };
  export { bar9 };
  function foo10() {
    
  }
  export { foo10 };
  var Foo11 = function () {
    
  }
  let $v3 = Foo11.prototype;
  $v3.constructor = Foo11;
  export { Foo11 };
  export { foo12 };
  export { foo13 };
  export { bar13 };
  export { baz13 };
  export { foo14 as bar14 };
  export { foo15 };
  export { bar15 as baz15 };
  export { foo17 } from "module";
  export { foo18 } from "module";
  export { bar18 } from "module";
  export { baz18 } from "module";
  export { foo19 as bar19 } from "module";
  export { foo20 } from "module";
  export { bar20 as baz20 } from "module";
  export { foo21 as default } from "module";
  export { default as foo22 } from "module";
  export * from "module";
  export * as foo23 from "module";
