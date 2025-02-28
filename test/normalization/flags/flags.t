Flag for always generating fresh variables
  $ graphjs parse always_fresh.js
  foo = -10;
  foo = 10 + 20;
  foo = bar.baz;
  foo = bar(10, "abc");
  foo = function (x, y, z) {
    
  }
  let $v1 = {};
  for (let foo in $v1) {
    
  }
  for (let foo of bar) {
    
  }
  try {
    
  } catch (foo) {
    
  }

  $ graphjs parse always_fresh.js --always-fresh
  let $v1 = -10;
  foo = $v1;
  let $v2 = 10 + 20;
  foo = $v2;
  let $v3 = bar.baz;
  foo = $v3;
  let $v4 = bar(10, "abc");
  foo = $v4;
  let $v5 = function (x, y, z) {
    
  }
  foo = $v5;
  let $v6 = {};
  for (let foo in $v6) {
    
  }
  for (let foo of bar) {
    
  }
  try {
    
  } catch (foo) {
    
  }



Flag for disabling function hoisting
  $ graphjs parse disable_hoisting.js
  let foo = function () {
    
  }
  function bar() {
    
  }
  $ graphjs parse disable_hoisting.js --disable-hoisting
  let foo = function () {
    
  }
  var bar = function () {
    
  }



Flag for disabling default values
  $ graphjs parse disable_defaults.js
  let $v1 = {};
  var foo = $v1.foo;
  let $v2 = foo === undefined;
  if ($v2) {
    foo = 10;
  }
  var bar = $v1.bar;
  let $v3 = bar === undefined;
  if ($v3) {
    bar = "abc";
  }
  let $v4 = [];
  var foo = $v4[0];
  let $v5 = foo === undefined;
  if ($v5) {
    foo = 10;
  }
  var bar = $v4[1];
  let $v6 = bar === undefined;
  if ($v6) {
    bar = "abc";
  }
  for (let $v7 in qux) {
    foo = $v7.foo;
    let $v8 = foo === undefined;
    if ($v8) {
      foo = 10;
    }
    bar = $v7.bar;
    let $v9 = bar === undefined;
    if ($v9) {
      let $v10 = {};
      $v10.baz = "abc";
      bar = $v10;
    }
  }
  for (let $v11 of qux) {
    foo = $v11.foo;
    let $v12 = foo === undefined;
    if ($v12) {
      foo = 10;
    }
    bar = $v11.bar;
    let $v13 = bar === undefined;
    if ($v13) {
      let $v14 = {};
      $v14.baz = "abc";
      bar = $v14;
    }
  }
  let $v15 = function (foo, bar) {
    let $v16 = foo === undefined;
    if ($v16) {
      foo = 10;
    }
    let $v17 = bar === undefined;
    if ($v17) {
      bar = "abc";
    }
  }
  let $v18 = function (foo, bar) {
    let $v19 = foo === undefined;
    if ($v19) {
      foo = 10;
    }
    let $v20 = bar === undefined;
    if ($v20) {
      bar = "abc";
    }
  }

  $ graphjs parse disable_defaults.js --disable-defaults
  let $v1 = {};
  var foo = $v1.foo;
  var bar = $v1.bar;
  let $v2 = [];
  var foo = $v2[0];
  var bar = $v2[1];
  for (let $v3 in qux) {
    foo = $v3.foo;
    bar = $v3.bar;
  }
  for (let $v4 of qux) {
    foo = $v4.foo;
    bar = $v4.bar;
  }
  let $v5 = function (foo, bar) {
    
  }
  let $v6 = function (foo, bar) {
    
  }



Flag for disabling logical operator evaluation with short circuit
  $ graphjs parse disable_short_circuit.js
  let $v1 = true && true;
  if ($v1) {
    $v1 = false && true;
  }
  $v1;
  let $v2 = true && true;
  if ($v2) {
    $v2 = false && true;
  }
  let $v3 = $v2 && true;
  if ($v3) {
    $v3 = true && true;
  }
  $v3;
  let $v4 = true && false;
  if ($v4) {
    
  } else {
    $v4 = false && false;
  }
  $v4;
  let $v5 = 10;
  let $v6 = 10 === null;
  let $v7 = 10 === undefined;
  let $v8 = $v6 || $v7;
  if ($v8) {
    $v5 = "abc";
  }
  $v5;

  $ graphjs parse disable_short_circuit.js --disable-short-circuit
  let $v1 = true && false;
  $v1;
  let $v2 = true && false;
  let $v3 = $v2 && true;
  $v3;
  let $v4 = true || false;
  $v4;
  let $v5 = 10 ?? "abc";
  $v5;



Flag for disabling function and class aliases
  $ graphjs parse disable_aliases.js
  var foo = function () {
    
  }
  let $v1 = function () {
    let bar = function () {
      
    }
    return bar;
  }
  var foo = $v1();
  var Foo = function () {
    
  }
  let $v2 = Foo.prototype;
  $v2.constructor = Foo;
  let $v4 = function () {
    let Bar = function () {
      
    }
    let $v3 = Bar.prototype;
    $v3.constructor = Bar;
    return Bar;
  }
  var Foo = $v4();

  $ graphjs parse disable_aliases.js --disable-aliases
  var foo = function () {
    
  }
  var foo = function () {
    
  }
  var Foo = function () {
    
  }
  let $v1 = Foo.prototype;
  $v1.constructor = Foo;
  var Foo = function () {
    
  }
  let $v2 = Foo.prototype;
  $v2.constructor = Foo;
