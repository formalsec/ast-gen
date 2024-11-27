  $ graphjs parse identifier.js
  var foo;
  var foo2 = 10;
  var foo3 = 20;
  var foo4;
  let bar;
  let bar2 = 10;
  let bar3 = 20;
  let bar4;
  const baz = 10;
  const baz2 = 20;
  const baz3 = 30;

  $ graphjs parse operator.js
  var foo = -10;
  var foo = 10 + "abc";
  var foo = 10 && true;
  if (foo) {
    foo = "abc" && true;
  }
  let $v1 = 10 && true;
  if ($v1) {
    $v1 = "abc" && true;
  }
  const foo2 = $v1;
  var foo;
  if (true) {
    foo = 10;
  } else {
    foo = "abc";
  }
  let $v2;
  if (true) {
    $v2 = 10;
  } else {
    $v2 = "abc";
  }
  const foo3 = $v2;
  bar = bar + 1;
  var foo = bar;
  var foo = bar;
  bar = bar + 1;
  let $v3 = obj[bar];
  var foo = $v3;
  let $v3 = $v3 + 1;
  obj[bar] = $v3;

  $ graphjs parse object_pattern.js
  let $v1 = {};
  var foo = $v1.foo;
  let $v2 = {};
  const foo1 = $v2.foo1;
  let $v3 = {};
  var foo = $v3.foo;
  var bar = $v3.bar;
  let $v4 = {};
  const foo2 = $v4.foo2;
  const bar2 = $v4.bar2;
  let $v5 = {};
  var foo = $v5.foo;
  let $v6 = $v5.bar;
  var baz = $v6.baz;
  var qux = $v6.qux;
  let $v7 = {};
  const foo3 = $v7.foo3;
  let $v8 = $v7.bar;
  const baz3 = $v8.baz3;
  const qux3 = $v8.qux3;
  let $v9 = {};
  var foo = $v9.foo;
  let $v10 = foo === undefined;
  if ($v10) {
    foo = 10;
  }
  var bar = $v9.bar;
  let $v11 = bar === undefined;
  if ($v11) {
    bar = "abc";
  }
  let $v12 = {};
  let $v13 = $v12.foo4;
  let $v14 = $v13 === undefined;
  if ($v14) {
    $v13 = 10;
  }
  const foo4 = $v13;
  let $v15 = $v12.bar4;
  let $v16 = $v15 === undefined;
  if ($v16) {
    $v15 = "abc";
  }
  const bar4 = $v15;
  let $v17 = {};
  var foo = $v17.foo;
  let $v18 = foo === undefined;
  if ($v18) {
    foo = 10;
  }
  let $v19 = $v17.bar;
  var baz = $v19.baz;
  let $v20 = baz === undefined;
  if ($v20) {
    baz = "abc";
  }
  let $v21 = {};
  let $v22 = $v21.foo5;
  let $v23 = $v22 === undefined;
  if ($v23) {
    $v22 = 10;
  }
  const foo5 = $v22;
  let $v24 = $v21.bar;
  let $v25 = $v24.baz5;
  let $v26 = $v25 === undefined;
  if ($v26) {
    $v25 = "abc";
  }
  const baz5 = $v25;
  let $v27 = {};
  var foo = $v27.foo;
  let $v28 = foo === undefined;
  if ($v28) {
    foo = 10;
  }
  let $v29 = $v27.bar;
  let $v30 = $v29 === undefined;
  if ($v30) {
    let $v31 = {};
    $v31.baz = "abc";
    $v29 = $v31;
  }
  var baz = $v29.baz;
  let $v32 = {};
  let $v33 = $v32.foo6;
  let $v34 = $v33 === undefined;
  if ($v34) {
    $v33 = 10;
  }
  const foo6 = $v33;
  let $v35 = $v32.bar;
  let $v36 = $v35 === undefined;
  if ($v36) {
    let $v37 = {};
    $v37.baz = "abc";
    $v35 = $v37;
  }
  const baz6 = $v35.baz6;
  let $v38 = {};
  var a = $v38.foo;
  var b = $v38.bar;
  var c = $v38.baz;
  let $v39 = {};
  const a7 = $v39.foo;
  const b7 = $v39.bar;
  const c7 = $v39.baz;
  let $v40 = {};
  var a = $v40.foo;
  let $v41 = a === undefined;
  if ($v41) {
    a = 10;
  }
  var b = $v40.bar;
  let $v42 = b === undefined;
  if ($v42) {
    b = "abc";
  }
  let $v43 = {};
  let $v44 = $v43.foo;
  let $v45 = $v44 === undefined;
  if ($v45) {
    $v44 = 10;
  }
  const a8 = $v44;
  let $v46 = $v43.bar;
  let $v47 = $v46 === undefined;
  if ($v47) {
    $v46 = "abc";
  }
  const b8 = $v46;
  let $v48 = {};
  var a = $v48["foo"];

  $ graphjs parse array_pattern.js
  let $v1 = [];
  var foo = $v1[0];
  let $v2 = [];
  const foo1 = $v2[0];
  let $v3 = [];
  var foo = $v3[0];
  var bar = $v3[1];
  let $v4 = [];
  const foo2 = $v4[0];
  const bar2 = $v4[1];
  let $v5 = [];
  var foo = $v5[0];
  let $v6 = $v5[1];
  var bar = $v6[0];
  var baz = $v6[1];
  let $v7 = [];
  const foo3 = $v7[0];
  let $v8 = $v7[1];
  const bar3 = $v8[0];
  const baz3 = $v8[1];
  let $v9 = [];
  var foo = $v9[0];
  let $v10 = foo === undefined;
  if ($v10) {
    foo = 10;
  }
  var bar = $v9[1];
  let $v11 = bar === undefined;
  if ($v11) {
    bar = "abc";
  }
  let $v12 = [];
  let $v13 = $v12[0];
  let $v14 = $v13 === undefined;
  if ($v14) {
    $v13 = 10;
  }
  const foo4 = $v13;
  let $v15 = $v12[1];
  let $v16 = $v15 === undefined;
  if ($v16) {
    $v15 = "abc";
  }
  const bar4 = $v15;
  let $v17 = [];
  var foo = $v17[0];
  let $v18 = foo === undefined;
  if ($v18) {
    foo = 10;
  }
  let $v19 = $v17[1];
  var bar = $v19[0];
  let $v20 = bar === undefined;
  if ($v20) {
    bar = "abc";
  }
  let $v21 = [];
  let $v22 = $v21[0];
  let $v23 = $v22 === undefined;
  if ($v23) {
    $v22 = 10;
  }
  const foo5 = $v22;
  let $v24 = $v21[1];
  let $v25 = $v24[0];
  let $v26 = $v25 === undefined;
  if ($v26) {
    $v25 = "abc";
  }
  const bar5 = $v25;
  let $v27 = [];
  var foo = $v27[0];
  let $v28 = foo === undefined;
  if ($v28) {
    foo = 10;
  }
  var bar = $v27[1];
  let $v29 = bar === undefined;
  if ($v29) {
    let $v30 = [];
    $v30[0] = "abc";
    bar = $v30;
  }
  let $v31 = [];
  let $v32 = $v31[0];
  let $v33 = $v32 === undefined;
  if ($v33) {
    $v32 = 10;
  }
  const foo6 = $v32;
  let $v34 = $v31[1];
  let $v35 = $v34 === undefined;
  if ($v35) {
    let $v36 = [];
    $v36[0] = "abc";
    $v34 = $v36;
  }
  const bar6 = $v34;
  let $v37 = [];
  var foo = $v37[0];
  var bar = $v37[2];
  let $v38 = [];
  var foo = $v38[0];
  var bar = $v38[1];

  $ graphjs parse member.js
  let $v1 = {};
  var foo = $v1.foo;
  let $v2 = {};
  const foo1 = $v2.foo;
  let $v3 = {};
  let $v4 = $v3.foo;
  var foo = $v4.bar;
  let $v5 = {};
  let $v6 = $v5.foo;
  const foo2 = $v6.bar;
  let $v7 = {};
  let $v8 = $v7.foo;
  var foo = undefined;
  let $v9 = $v8 !== null;
  let $v10 = $v8 !== undefined;
  let $v11 = $v9 && $v10;
  if ($v11) {
    foo = $v8.bar;
  }
  let $v12 = {};
  let $v13 = $v12.foo;
  let $v14 = undefined;
  let $v15 = $v13 !== null;
  let $v16 = $v13 !== undefined;
  let $v17 = $v15 && $v16;
  if ($v17) {
    $v14 = $v13.bar;
  }
  const foo3 = $v14;
  let $v18 = {};
  let $v19 = $v18.foo;
  let $v20 = undefined;
  let $v21 = $v19 !== null;
  let $v22 = $v19 !== undefined;
  let $v23 = $v21 && $v22;
  if ($v23) {
    $v20 = $v19.bar;
  }
  var foo = undefined;
  let $v24 = $v20 !== null;
  let $v25 = $v20 !== undefined;
  let $v26 = $v24 && $v25;
  if ($v26) {
    foo = $v20.baz;
  }
  let $v27 = {};
  let $v28 = $v27.foo;
  let $v29 = undefined;
  let $v30 = $v28 !== null;
  let $v31 = $v28 !== undefined;
  let $v32 = $v30 && $v31;
  if ($v32) {
    $v29 = $v28.bar;
  }
  let $v33 = undefined;
  let $v34 = $v29 !== null;
  let $v35 = $v29 !== undefined;
  let $v36 = $v34 && $v35;
  if ($v36) {
    $v33 = $v29.baz;
  }
  const foo4 = $v33;

  $ graphjs parse function.js
  var foo = function () {
    
  }
  const foo1 = function () {
    
  }
  let $v1 = function () {
    let bar = function () {
      
    }
    return bar;
  }
  var foo = $v1();
  let $v2 = function () {
    let bar = function () {
      
    }
    return bar;
  }
  const foo2 = $v2();

  $ graphjs parse class.js
  var Foo = function () {
    
  }
  let $v1 = Foo.prototype;
  $v1.constructor = Foo;
  const Foo1 = function () {
    
  }
  let $v2 = Foo1.prototype;
  $v2.constructor = Foo1;
  let $v4 = function () {
    let Bar = function () {
      
    }
    let $v3 = Bar.prototype;
    $v3.constructor = Bar;
    return Bar;
  }
  var Foo = $v4();
  let $v6 = function () {
    let Bar = function () {
      
    }
    let $v5 = Bar.prototype;
    $v5.constructor = Bar;
    return Bar;
  }
  const Foo2 = $v6();
  let $v8 = function () {
    let Bar = function () {
      
    }
    let $v7 = Bar.prototype;
    $v7.constructor = Bar;
    return Bar;
  }
  var Foo = $v8();
  let $v10 = function () {
    let Bar = function () {
      
    }
    let $v9 = Bar.prototype;
    $v9.constructor = Bar;
    return Bar;
  }
  const Foo3 = $v10();
