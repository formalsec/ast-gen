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
