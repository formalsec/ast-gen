  $ graphjs parse flow.js
  while (true) {
    break;
  }
  foo: while (true) {
    break foo;
  }
  foo: bar: while (true) {
    break foo;
  }
  while (true) {
    continue;
  }
  foo: bar: while (true) {
    continue foo;
  }

  $ graphjs parse return.js
  let $v1 = function () {
    return;
  }
  let $v2 = function () {
    return 10;
  }
  let $v3 = function () {
    let $v4 = 10 + "abc";
    return $v4;
  }

  $ graphjs parse throw.js
  let $v1 = function () {
    throw 10;
  }
  let $v2 = function () {
    let $v3 = 10 + "abc";
    throw $v3;
  }

  $ graphjs parse try.js
  try {
    
  } catch {
    
  }
  try {
    
  } finally {
    
  }
  try {
    
  } catch {
    
  } finally {
    
  }
  try {
    x;
  } catch {
    y;
  }
  try {
    x;
  } finally {
    y;
  }
  try {
    x;
  } catch {
    y;
  } finally {
    z;
  }
  try {
    try {
      x;
    } catch {
      y;
    }
  } finally {
    z;
  }
  try {
    x;
  } catch (foo) {
    y;
  }
  try {
    x;
  } catch ($v1) {
    foo = $v1.foo;
    let $v2 = $v1.bar;
    baz = $v2.baz;
    y;
  }
  try {
    x;
  } catch ($v3) {
    foo = $v3.foo;
    let $v4 = foo === undefined;
    if ($v4) {
      foo = 10;
    }
    let $v5 = $v3.bar;
    let $v6 = $v5 === undefined;
    if ($v6) {
      let $v7 = {};
      $v7.baz = "abc";
      $v5 = $v7;
    }
    baz = $v5.baz;
    y;
  }
  try {
    x;
  } catch ($v8) {
    foo = $v8[0];
    let $v9 = $v8[1];
    bar = $v9[0];
    baz = $v9[1];
    y;
  }
  try {
    x;
  } catch ($v10) {
    foo = $v10[0];
    let $v11 = foo === undefined;
    if ($v11) {
      foo = 10;
    }
    let $v12 = $v10[1];
    let $v13 = $v12 === undefined;
    if ($v13) {
      let $v14 = [];
      $v14[0] = "abc";
      $v14[1] = true;
      $v12 = $v14;
    }
    bar = $v12[0];
    baz = $v12[1];
    y;
  }

  $ graphjs parse with.js
  with (foo) {
    
  }
  with (foo) {
    
  }
  with (foo) {
    x;
  }
  with (foo) {
    x;
  }
  with (foo) {
    with (bar) {
      x;
    }
  }
  let $v1 = foo[bar];
  with ($v1) {
    x;
  }

  $ graphjs parse debugger.js
  debugger;
