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
  const foo1 = -10;
  var foo = 10 + "abc";
  const foo2 = 10 + "abc";
  var foo = 10 && true;
  if (foo) {
    foo = "abc" && true;
  }
  let $v1 = 10 && true;
  if ($v1) {
    $v1 = "abc" && true;
  }
  const foo3 = $v1;
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
  const foo4 = $v2;
  bar = bar + 1;
  var foo = bar;
  bar = bar + 1;
  const foo5 = bar;
  var foo = bar;
  bar = bar + 1;
  const foo6 = bar;
  bar = bar + 1;
  let $v3 = bar[baz];
  var foo = $v3;
  let $v3 = $v3 + 1;
  bar[baz] = $v3;
  let $v4 = bar[baz];
  const foo7 = $v4;
  let $v4 = $v4 + 1;
  bar[baz] = $v4;
  let $v5 = bar[baz];
  let $v5 = $v5 - 1;
  var foo = $v5;
  bar[baz] = $v5;
  let $v6 = bar[baz];
  const foo8 = $v6;
  let $v6 = $v6 + 1;
  bar[baz] = $v6;

  $ graphjs parse object_pattern.js
  let $v1 = {};
  let $v2 = {};
  let $v3 = {};
  var foo = $v3.foo;
  let $v4 = {};
  const foo1 = $v4.foo1;
  let $v5 = {};
  var foo = $v5.foo;
  var bar = $v5.bar;
  let $v6 = {};
  const foo2 = $v6.foo2;
  const bar2 = $v6.bar2;
  let $v7 = {};
  var foo = $v7.foo;
  let $v8 = $v7.bar;
  var baz = $v8.baz;
  var qux = $v8.qux;
  let $v9 = {};
  const foo3 = $v9.foo3;
  let $v10 = $v9.bar;
  const baz3 = $v10.baz3;
  const qux3 = $v10.qux3;
  let $v11 = {};
  var foo = $v11.foo;
  let $v12 = foo === undefined;
  if ($v12) {
    foo = 10;
  }
  var bar = $v11.bar;
  let $v13 = bar === undefined;
  if ($v13) {
    bar = "abc";
  }
  let $v14 = {};
  let $v15 = $v14.foo4;
  let $v16 = $v15 === undefined;
  if ($v16) {
    $v15 = 10;
  }
  const foo4 = $v15;
  let $v17 = $v14.bar4;
  let $v18 = $v17 === undefined;
  if ($v18) {
    $v17 = "abc";
  }
  const bar4 = $v17;
  let $v19 = {};
  var foo = $v19.foo;
  let $v20 = foo === undefined;
  if ($v20) {
    foo = 10;
  }
  let $v21 = $v19.bar;
  var baz = $v21.baz;
  let $v22 = baz === undefined;
  if ($v22) {
    baz = "abc";
  }
  let $v23 = {};
  let $v24 = $v23.foo5;
  let $v25 = $v24 === undefined;
  if ($v25) {
    $v24 = 10;
  }
  const foo5 = $v24;
  let $v26 = $v23.bar;
  let $v27 = $v26.baz5;
  let $v28 = $v27 === undefined;
  if ($v28) {
    $v27 = "abc";
  }
  const baz5 = $v27;
  let $v29 = {};
  var foo = $v29.foo;
  let $v30 = foo === undefined;
  if ($v30) {
    foo = 10;
  }
  let $v31 = $v29.bar;
  let $v32 = $v31 === undefined;
  if ($v32) {
    let $v33 = {};
    $v33.baz = "abc";
    $v31 = $v33;
  }
  var baz = $v31.baz;
  let $v34 = {};
  let $v35 = $v34.foo6;
  let $v36 = $v35 === undefined;
  if ($v36) {
    $v35 = 10;
  }
  const foo6 = $v35;
  let $v37 = $v34.bar;
  let $v38 = $v37 === undefined;
  if ($v38) {
    let $v39 = {};
    $v39.baz = "abc";
    $v37 = $v39;
  }
  const baz6 = $v37.baz6;
  let $v40 = {};
  var a = $v40.foo;
  var b = $v40.bar;
  var c = $v40.baz;
  let $v41 = {};
  const a7 = $v41.foo;
  const b7 = $v41.bar;
  const c7 = $v41.baz;
  let $v42 = {};
  var a = $v42.foo;
  let $v43 = a === undefined;
  if ($v43) {
    a = 10;
  }
  var b = $v42.bar;
  let $v44 = b === undefined;
  if ($v44) {
    b = "abc";
  }
  let $v45 = {};
  let $v46 = $v45.foo;
  let $v47 = $v46 === undefined;
  if ($v47) {
    $v46 = 10;
  }
  const a8 = $v46;
  let $v48 = $v45.bar;
  let $v49 = $v48 === undefined;
  if ($v49) {
    $v48 = "abc";
  }
  const b8 = $v48;
  let $v50 = {};
  let $v51 = 10 + "abc";
  var a = $v50[$v51];
  let $v52 = {};
  let $v53 = 10 + "abc";
  const a = $v52[$v53];

  $ graphjs parse array_pattern.js
  let $v1 = [];
  let $v2 = [];
  let $v3 = [];
  var foo = $v3[0];
  let $v4 = [];
  const foo1 = $v4[0];
  let $v5 = [];
  var foo = $v5[0];
  var bar = $v5[1];
  let $v6 = [];
  const foo2 = $v6[0];
  const bar2 = $v6[1];
  let $v7 = [];
  var foo = $v7[0];
  let $v8 = $v7[1];
  var bar = $v8[0];
  var baz = $v8[1];
  let $v9 = [];
  const foo3 = $v9[0];
  let $v10 = $v9[1];
  const bar3 = $v10[0];
  const baz3 = $v10[1];
  let $v11 = [];
  var foo = $v11[0];
  let $v12 = foo === undefined;
  if ($v12) {
    foo = 10;
  }
  var bar = $v11[1];
  let $v13 = bar === undefined;
  if ($v13) {
    bar = "abc";
  }
  let $v14 = [];
  let $v15 = $v14[0];
  let $v16 = $v15 === undefined;
  if ($v16) {
    $v15 = 10;
  }
  const foo4 = $v15;
  let $v17 = $v14[1];
  let $v18 = $v17 === undefined;
  if ($v18) {
    $v17 = "abc";
  }
  const bar4 = $v17;
  let $v19 = [];
  var foo = $v19[0];
  let $v20 = foo === undefined;
  if ($v20) {
    foo = 10;
  }
  let $v21 = $v19[1];
  var bar = $v21[0];
  let $v22 = bar === undefined;
  if ($v22) {
    bar = "abc";
  }
  let $v23 = [];
  let $v24 = $v23[0];
  let $v25 = $v24 === undefined;
  if ($v25) {
    $v24 = 10;
  }
  const foo5 = $v24;
  let $v26 = $v23[1];
  let $v27 = $v26[0];
  let $v28 = $v27 === undefined;
  if ($v28) {
    $v27 = "abc";
  }
  const bar5 = $v27;
  let $v29 = [];
  var foo = $v29[0];
  let $v30 = foo === undefined;
  if ($v30) {
    foo = 10;
  }
  var bar = $v29[1];
  let $v31 = bar === undefined;
  if ($v31) {
    let $v32 = [];
    $v32[0] = "abc";
    bar = $v32;
  }
  let $v33 = [];
  let $v34 = $v33[0];
  let $v35 = $v34 === undefined;
  if ($v35) {
    $v34 = 10;
  }
  const foo6 = $v34;
  let $v36 = $v33[1];
  let $v37 = $v36 === undefined;
  if ($v37) {
    let $v38 = [];
    $v38[0] = "abc";
    $v36 = $v38;
  }
  const bar6 = $v36;
  let $v39 = [];
  var foo = $v39[0];
  var bar = $v39[2];
  let $v40 = [];
  const foo = $v40[0];
  const bar = $v40[2];
  let $v41 = [];
  var foo = $v41[0];
  var bar = $v41[1];
  let $v42 = [];
  const foo = $v42[0];
  const bar = $v42[1];

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

  $ graphjs parse leftvalue_context.js
  let $v1 = 10 + 20;
  var foo = `abc${$v1} def${true}`;
  let $v2 = 10 + 20;
  const foo1 = `abc${$v2} def${true}`;
  let $v3 = 10 + 20;
  let $v4 = "abc" + "def";
  var foo = $v4;
  let $v5 = 10 + 20;
  let $v6 = "abc" + "def";
  const foo2 = $v6;
  var foo = {};
  let $v7 = 10 + 20;
  foo.bar = $v7;
  let $v8 = "abc" + "def";
  foo.baz = $v8;
  const foo3 = {};
  let $v9 = 10 + 20;
  foo3.bar = $v9;
  let $v10 = "abc" + "def";
  foo3.baz = $v10;
  var foo = [];
  let $v11 = 10 + 20;
  foo[0] = $v11;
  let $v12 = "abc" + "def";
  foo[1] = $v12;
  const foo4 = [];
  let $v13 = 10 + 20;
  foo4[0] = $v13;
  let $v14 = "abc" + "def";
  foo4[1] = $v14;
  let $v15 = -10;
  var foo = -$v15;
  let $v16 = -10;
  const foo5 = -$v16;
  let $v17 = 10 + 20;
  var foo = $v17 + 30;
  let $v18 = 10 + 20;
  const foo6 = $v18 + 30;
  let $v19 = {};
  let $v20 = $v19.bar;
  let $v21 = {};
  let $v22 = $v21.baz;
  var foo = $v20 + $v22;
  let $v23 = {};
  let $v24 = $v23.bar;
  let $v25 = {};
  let $v26 = $v25.baz;
  const foo7 = $v24 + $v26;
  let $v27 = 10 + 20;
  let $v28 = "abc" + "def";
  var foo = new bar($v27, $v28);
  let $v29 = 10 + 20;
  let $v30 = "abc" + "def";
  const foo8 = new bar($v29, $v30);
  let $v31 = 10 + 20;
  let $v32 = "abc" + "def";
  var foo = bar($v31, $v32);
  let $v33 = 10 + 20;
  let $v34 = "abc" + "def";
  const foo9 = bar($v33, $v34);
  let $v35 = bar;
  var foo = undefined;
  let $v38 = bar !== null;
  let $v39 = bar !== undefined;
  let $v40 = $v38 && $v39;
  if ($v40) {
    let $v36 = 10 + 20;
    let $v37 = "abc" + "def";
    foo = $v35($v36, $v37);
  }
  let $v41 = bar;
  let $v44 = undefined;
  let $v45 = bar !== null;
  let $v46 = bar !== undefined;
  let $v47 = $v45 && $v46;
  if ($v47) {
    let $v42 = 10 + 20;
    let $v43 = "abc" + "def";
    $v44 = $v41($v42, $v43);
  }
  const foo10 = $v44;
  let $v48 = 10 + 20;
  let $v49 = "abc" + "def";
  let $v50 = [];
  $v50[0] = "";
  $v50[1] = "";
  var foo = $v48($v50, $v49);
  let $v51 = 10 + 20;
  let $v52 = "abc" + "def";
  let $v53 = [];
  $v53[0] = "";
  $v53[1] = "";
  const foo11 = $v51($v53, $v52);
  let $v54 = "abc" + "def";
  var foo = import($v54);
  let $v55 = "abc" + "def";
  const foo12 = import($v55);
