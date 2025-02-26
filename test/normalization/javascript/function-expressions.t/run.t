  $ graphjs parse parameters.js
  let $v1 = function () {
    
  }
  let $v2 = function (foo) {
    
  }
  let $v3 = function (foo, bar, baz) {
    
  }
  let $v4 = function (foo, bar) {
    let $v5 = foo === undefined;
    if ($v5) {
      foo = 10;
    }
    let $v6 = bar === undefined;
    if ($v6) {
      bar = "abc";
    }
  }
  let $v7 = function ($v8) {
    foo = $v8.foo;
    let $v9 = $v8.bar;
    baz = $v9.baz;
  }
  let $v10 = function ($v11) {
    foo = $v11.foo;
    let $v12 = foo === undefined;
    if ($v12) {
      foo = 10;
    }
    let $v13 = $v11.bar;
    let $v14 = $v13 === undefined;
    if ($v14) {
      let $v15 = {};
      $v15.baz = "abc";
      $v13 = $v15;
    }
    baz = $v13.baz;
  }
  let $v16 = function ($v17) {
    foo = $v17[0];
    let $v18 = $v17[1];
    bar = $v18[0];
    baz = $v18[1];
  }
  let $v19 = function ($v20) {
    foo = $v20[0];
    let $v21 = foo === undefined;
    if ($v21) {
      foo = 10;
    }
    let $v22 = $v20[1];
    let $v23 = $v22 === undefined;
    if ($v23) {
      let $v24 = [];
      $v24[0] = "abc";
      $v24[1] = true;
      $v22 = $v24;
    }
    bar = $v22[0];
    baz = $v22[1];
  }

  $ graphjs parse body.js
  let $v1 = function () {
    
  }
  let $v2 = function () {
    let foo = 10;
  }
  let $v3 = function () {
    let foo = 10;
    let bar = "abc";
  }
  let $v4 = function (foo) {
    let bar = "abc";
  }
  let $v5 = function (foo) {
    let $v6 = foo === undefined;
    if ($v6) {
      foo = 10;
    }
    let bar = "abc";
  }

  $ graphjs parse special.js
  let $v1 = function () {
    
  }
  let $v2 = function (foo) {
    
  }
  let $v3 = async function () {
    
  }
  let $v4 = async function (foo) {
    
  }
  let $v5 = function* () {
    
  }
  let $v6 = function* (foo) {
    
  }
  let $v7 = async function* () {
    
  }
  let $v8 = async function* (foo) {
    
  }

  $ graphjs parse arrow.js
  let $v1 = function () {
    
  }
  let $v2 = function (foo) {
    
  }
  let $v3 = function (foo, bar, baz) {
    
  }
  let $v4 = function (foo, bar) {
    let $v5 = foo === undefined;
    if ($v5) {
      foo = 10;
    }
    let $v6 = bar === undefined;
    if ($v6) {
      bar = "abc";
    }
  }
  let $v7 = function ($v8) {
    foo = $v8.foo;
    let $v9 = $v8.bar;
    baz = $v9.baz;
  }
  let $v10 = function ($v11) {
    foo = $v11.foo;
    let $v12 = foo === undefined;
    if ($v12) {
      foo = 10;
    }
    let $v13 = $v11.bar;
    let $v14 = $v13 === undefined;
    if ($v14) {
      let $v15 = {};
      $v15.baz = "abc";
      $v13 = $v15;
    }
    baz = $v13.baz;
  }
  let $v16 = function ($v17) {
    foo = $v17[0];
    let $v18 = $v17[1];
    bar = $v18[0];
    baz = $v18[1];
  }
  let $v19 = function ($v20) {
    foo = $v20[0];
    let $v21 = foo === undefined;
    if ($v21) {
      foo = 10;
    }
    bar = $v20[1];
    let $v22 = bar === undefined;
    if ($v22) {
      let $v23 = [];
      $v23[0] = "abc";
      bar = $v23;
    }
  }
  let $v24 = function () {
    let foo = 10;
  }
  let $v25 = function () {
    let foo = 10;
    let bar = "abc";
  }
  let $v26 = function () {
    let $v27 = 10 + "abc";
    return $v27;
  }
  let $v28 = async function () {
    
  }
  let $v29 = function (foo) {
    let $v30 = function (bar) {
      let $v31 = foo + bar;
      return $v31;
    }
    return $v30;
  }

  $ graphjs parse await.js
  let $v1 = async function () {
    let $v2 = foo();
    let $v3 = await $v2;
    $v3;
  }
  let $v4 = async function () {
    let $v5 = foo(10);
    let $v6 = await $v5;
    $v6;
  }
  let $v7 = async function () {
    let $v8 = foo(10, "abc", true);
    let $v9 = await $v8;
    $v9;
  }
  let $v10 = async function () {
    let $v11 = 10 + "abc";
    let $v12 = foo($v11);
    let $v13 = await $v12;
    $v13;
  }
  let $v14 = async function () {
    let $v15 = 10 + "abc";
    let $v16 = $v15(true);
    let $v17 = await $v16;
    $v17;
  }
  let $v18 = async function () {
    let $v19 = foo();
    let $v20 = await $v19;
    let $v21 = bar($v20);
  }
