  $ graphjs parse identifier.js
  foo = 10;
  baz = true;
  bar = true;
  foo = true;

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
  let $v1 = bar[baz];
  let $v1 = $v1 - 1;
  foo = $v1;
  bar[baz] = $v1;
  let $v2 = bar[baz];
  foo = $v2;
  let $v2 = $v2 + 1;
  bar[baz] = $v2;

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
  let $v2 = {};
  foo = $v2.foo;
  let $v3 = {};
  foo = $v3.foo;
  bar = $v3.bar;
  let $v4 = {};
  foo = $v4.foo;
  let $v5 = $v4.bar;
  baz = $v5.baz;
  qux = $v5.qux;
  let $v6 = {};
  foo = $v6.foo;
  let $v7 = foo === undefined;
  if ($v7) {
    foo = 10;
  }
  bar = $v6.bar;
  let $v8 = bar === undefined;
  if ($v8) {
    bar = "abc";
  }
  let $v9 = {};
  foo = $v9.foo;
  let $v10 = foo === undefined;
  if ($v10) {
    foo = 10;
  }
  let $v11 = $v9.bar;
  baz = $v11.baz;
  let $v12 = baz === undefined;
  if ($v12) {
    baz = "abc";
  }
  let $v13 = {};
  foo = $v13.foo;
  let $v14 = foo === undefined;
  if ($v14) {
    foo = 10;
  }
  let $v15 = $v13.bar;
  let $v16 = $v15 === undefined;
  if ($v16) {
    let $v17 = {};
    $v17.baz = "abc";
    $v15 = $v17;
  }
  baz = $v15.baz;
  let $v18 = {};
  a = $v18.foo;
  b = $v18.bar;
  c = $v18.baz;
  let $v19 = {};
  a = $v19.foo;
  let $v20 = a === undefined;
  if ($v20) {
    a = 10;
  }
  b = $v19.bar;
  let $v21 = b === undefined;
  if ($v21) {
    b = "abc";
  }
  let $v22 = {};
  let $v23 = 10 + "abc";
  a = $v22[$v23];

  $ graphjs parse array_pattern.js
  let $v1 = [];
  let $v2 = [];
  foo = $v2[0];
  let $v3 = [];
  foo = $v3[0];
  bar = $v3[1];
  let $v4 = [];
  foo = $v4[0];
  let $v5 = $v4[1];
  bar = $v5[0];
  baz = $v5[1];
  let $v6 = [];
  foo = $v6[0];
  let $v7 = foo === undefined;
  if ($v7) {
    foo = 10;
  }
  bar = $v6[1];
  let $v8 = bar === undefined;
  if ($v8) {
    bar = "abc";
  }
  let $v9 = [];
  foo = $v9[0];
  let $v10 = foo === undefined;
  if ($v10) {
    foo = 10;
  }
  let $v11 = $v9[1];
  bar = $v11[0];
  let $v12 = bar === undefined;
  if ($v12) {
    bar = "abc";
  }
  let $v13 = [];
  foo = $v13[0];
  let $v14 = foo === undefined;
  if ($v14) {
    foo = 10;
  }
  bar = $v13[1];
  let $v15 = bar === undefined;
  if ($v15) {
    let $v16 = [];
    $v16[0] = "abc";
    bar = $v16;
  }
  let $v17 = [];
  foo = $v17[0];
  bar = $v17[2];
  let $v18 = [];
  foo = $v18[0];
  bar = $v18[1];

  $ graphjs parse array_pattern.js
  let $v1 = [];
  let $v2 = [];
  foo = $v2[0];
  let $v3 = [];
  foo = $v3[0];
  bar = $v3[1];
  let $v4 = [];
  foo = $v4[0];
  let $v5 = $v4[1];
  bar = $v5[0];
  baz = $v5[1];
  let $v6 = [];
  foo = $v6[0];
  let $v7 = foo === undefined;
  if ($v7) {
    foo = 10;
  }
  bar = $v6[1];
  let $v8 = bar === undefined;
  if ($v8) {
    bar = "abc";
  }
  let $v9 = [];
  foo = $v9[0];
  let $v10 = foo === undefined;
  if ($v10) {
    foo = 10;
  }
  let $v11 = $v9[1];
  bar = $v11[0];
  let $v12 = bar === undefined;
  if ($v12) {
    bar = "abc";
  }
  let $v13 = [];
  foo = $v13[0];
  let $v14 = foo === undefined;
  if ($v14) {
    foo = 10;
  }
  bar = $v13[1];
  let $v15 = bar === undefined;
  if ($v15) {
    let $v16 = [];
    $v16[0] = "abc";
    bar = $v16;
  }
  let $v17 = [];
  foo = $v17[0];
  bar = $v17[2];
  let $v18 = [];
  foo = $v18[0];
  bar = $v18[1];

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

  $ graphjs parse leftvalue_context.js
  let $v1 = 10 + 20;
  foo = `abc${$v1} def${true}`;
  let $v2 = 10 + 20;
  let $v3 = "abc" + "def";
  foo = $v3;
  foo = {};
  let $v4 = 10 + 20;
  foo.bar = $v4;
  let $v5 = "abc" + "def";
  foo.baz = $v5;
  foo = [];
  let $v6 = 10 + 20;
  foo[0] = $v6;
  let $v7 = "abc" + "def";
  foo[1] = $v7;
  let $v8 = -10;
  foo = -$v8;
  let $v9 = 10 + 20;
  foo = $v9 + 30;
  let $v10 = {};
  let $v11 = $v10.bar;
  let $v12 = {};
  let $v13 = $v12.baz;
  foo = $v11 + $v13;
  let $v14 = 10 + 20;
  let $v15 = "abc" + "def";
  foo = new bar($v14, $v15);
  let $v16 = 10 + 20;
  let $v17 = "abc" + "def";
  foo = bar($v16, $v17);
  let $v18 = bar;
  foo = undefined;
  let $v21 = bar !== null;
  let $v22 = bar !== undefined;
  let $v23 = $v21 && $v22;
  if ($v23) {
    let $v19 = 10 + 20;
    let $v20 = "abc" + "def";
    foo = $v18($v19, $v20);
  }
  let $v24 = 10 + 20;
  let $v25 = "abc" + "def";
  let $v26 = [];
  $v26[0] = "";
  $v26[1] = "";
  foo = $v24($v26, $v25);
  let $v27 = "abc" + "def";
  foo = import($v27);
