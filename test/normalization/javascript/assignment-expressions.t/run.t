  $ graphjs parse identifier.js
  foo = 10;
  bar2 = true;
  bar = true;

  $ graphjs parse assignment_operator.js
  foo = foo + 10;
  foo = foo - 10;
  foo = foo * 10;
  foo = foo / 10;
  foo = foo % 10;
  foo = foo ** 10;
  foo = foo & 10;
  foo = foo | 10;
  foo = foo ^ 10;
  foo = foo << 10;
  foo = foo >> 10;
  foo = foo >>> 10;
  foo = foo && 10;
  foo = foo || 10;
  foo = foo ?? 10;

  $ graphjs parse operator.js
  foo = -10;
  foo = 10 + "abc";
  foo = 10 && true;
  if (foo) {
    foo = "abc" && true;
  }
  if (true) {
    foo = 10;
  } else {
    foo = "abc";
  }
  bar = bar + 1;
  foo = bar;
  foo = bar;
  bar = bar + 1;
  let $v1 = obj[bar];
  foo = $v1;
  let $v1 = $v1 + 1;
  obj[bar] = $v1;

  $ graphjs parse member_pattern.js
  this.foo = 10;
  let $v1 = this.foo;
  $v1 = $v1 + 10;
  this.foo = $v1;
  this[foo] = 10;
  let $v2 = this[foo];
  $v2 = $v2 + 10;
  this[foo] = $v2;

  $ graphjs parse object_pattern.js
  let $v1 = {};
  foo = $v1.foo;
  let $v2 = {};
  foo = $v2.foo;
  bar = $v2.bar;
  let $v3 = {};
  foo = $v3.foo;
  let $v4 = $v3.bar;
  baz = $v4.baz;
  qux = $v4.qux;
  let $v5 = {};
  foo = $v5.foo;
  let $v6 = foo === undefined;
  if ($v6) {
    foo = 10;
  }
  bar = $v5.bar;
  let $v7 = bar === undefined;
  if ($v7) {
    bar = "abc";
  }
  let $v8 = {};
  foo = $v8.foo;
  let $v9 = foo === undefined;
  if ($v9) {
    foo = 10;
  }
  let $v10 = $v8.bar;
  baz = $v10.baz;
  let $v11 = baz === undefined;
  if ($v11) {
    baz = "abc";
  }
  let $v12 = {};
  foo = $v12.foo;
  let $v13 = foo === undefined;
  if ($v13) {
    foo = 10;
  }
  let $v14 = $v12.bar;
  let $v15 = $v14 === undefined;
  if ($v15) {
    let $v16 = {};
    $v16.baz = "abc";
    $v14 = $v16;
  }
  baz = $v14.baz;
  let $v17 = {};
  a = $v17.foo;
  b = $v17.bar;
  c = $v17.baz;
  let $v18 = {};
  a = $v18.foo;
  let $v19 = a === undefined;
  if ($v19) {
    a = 10;
  }
  b = $v18.bar;
  let $v20 = b === undefined;
  if ($v20) {
    b = "abc";
  }
  let $v21 = {};
  a = $v21["foo"];

  $ graphjs parse array_pattern.js
  let $v1 = [];
  foo = $v1[0];
  let $v2 = [];
  foo = $v2[0];
  bar = $v2[1];
  let $v3 = [];
  foo = $v3[0];
  let $v4 = $v3[1];
  bar = $v4[0];
  baz = $v4[1];
  let $v5 = [];
  foo = $v5[0];
  let $v6 = foo === undefined;
  if ($v6) {
    foo = 10;
  }
  bar = $v5[1];
  let $v7 = bar === undefined;
  if ($v7) {
    bar = "abc";
  }
  let $v8 = [];
  foo = $v8[0];
  let $v9 = foo === undefined;
  if ($v9) {
    foo = 10;
  }
  let $v10 = $v8[1];
  bar = $v10[0];
  let $v11 = bar === undefined;
  if ($v11) {
    bar = "abc";
  }
  let $v12 = [];
  foo = $v12[0];
  let $v13 = foo === undefined;
  if ($v13) {
    foo = 10;
  }
  bar = $v12[1];
  let $v14 = bar === undefined;
  if ($v14) {
    let $v15 = [];
    $v15[0] = "abc";
    bar = $v15;
  }
  let $v16 = [];
  foo = $v16[0];
  bar = $v16[2];
  let $v17 = [];
  foo = $v17[0];
  bar = $v17[1];

  $ graphjs parse array_pattern.js
  let $v1 = [];
  foo = $v1[0];
  let $v2 = [];
  foo = $v2[0];
  bar = $v2[1];
  let $v3 = [];
  foo = $v3[0];
  let $v4 = $v3[1];
  bar = $v4[0];
  baz = $v4[1];
  let $v5 = [];
  foo = $v5[0];
  let $v6 = foo === undefined;
  if ($v6) {
    foo = 10;
  }
  bar = $v5[1];
  let $v7 = bar === undefined;
  if ($v7) {
    bar = "abc";
  }
  let $v8 = [];
  foo = $v8[0];
  let $v9 = foo === undefined;
  if ($v9) {
    foo = 10;
  }
  let $v10 = $v8[1];
  bar = $v10[0];
  let $v11 = bar === undefined;
  if ($v11) {
    bar = "abc";
  }
  let $v12 = [];
  foo = $v12[0];
  let $v13 = foo === undefined;
  if ($v13) {
    foo = 10;
  }
  bar = $v12[1];
  let $v14 = bar === undefined;
  if ($v14) {
    let $v15 = [];
    $v15[0] = "abc";
    bar = $v15;
  }
  let $v16 = [];
  foo = $v16[0];
  bar = $v16[2];
  let $v17 = [];
  foo = $v17[0];
  bar = $v17[1];

  $ graphjs parse member.js 
  let $v1 = {};
  foo = $v1.foo;
  let $v2 = {};
  let $v3 = $v2.foo;
  foo = $v3.bar;
  let $v4 = {};
  let $v5 = $v4.foo;
  foo = undefined;
  let $v6 = $v5 !== null;
  let $v7 = $v5 !== undefined;
  let $v8 = $v6 && $v7;
  if ($v8) {
    foo = $v5.bar;
  }
  let $v9 = {};
  let $v10 = $v9.foo;
  let $v11 = undefined;
  let $v12 = $v10 !== null;
  let $v13 = $v10 !== undefined;
  let $v14 = $v12 && $v13;
  if ($v14) {
    $v11 = $v10.bar;
  }
  foo = undefined;
  let $v15 = $v11 !== null;
  let $v16 = $v11 !== undefined;
  let $v17 = $v15 && $v16;
  if ($v17) {
    foo = $v11.baz;
  }

  $ graphjs parse function.js
  foo = function () {
    
  }
  let $v1 = function () {
    let bar = function () {
      
    }
    return bar;
  }
  foo = $v1();

  $ graphjs parse class.js
  Foo = function () {
    
  }
  let $v1 = Foo.prototype;
  $v1.constructor = Foo;
  let $v3 = function () {
    let Bar = function () {
      
    }
    let $v2 = Bar.prototype;
    $v2.constructor = Bar;
    return Bar;
  }
  Foo = $v3();
  let $v5 = function () {
    let Bar = function () {
      
    }
    let $v4 = Bar.prototype;
    $v4.constructor = Bar;
    return Bar;
  }
  Foo = $v5();
