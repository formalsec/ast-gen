  $ graphjs parse function.js
  let $v1 = foo();
  let $v2 = foo(10);
  let $v3 = foo(10, "abc", true);
  let $v4 = 10 + "abc";
  let $v5 = foo($v4);
  let $v6 = 10 + "abc";
  let $v7 = $v6(true);
  let $v8 = foo;
  let $v9 = undefined;
  let $v10 = foo !== null;
  let $v11 = foo !== undefined;
  let $v12 = $v10 && $v11;
  if ($v12) {
    $v9 = $v8(10);
  }
  let $v13 = foo;
  let $v15 = undefined;
  let $v16 = foo !== null;
  let $v17 = foo !== undefined;
  let $v18 = $v16 && $v17;
  if ($v18) {
    let $v14 = 10 + "abc";
    $v15 = $v13($v14);
  }

  $ graphjs parse method.js
  let $v1 = foo.bar();
  let $v2 = foo.bar(10);
  let $v3 = foo.bar(10, "abc", true);
  let $v4 = 10 + "abc";
  let $v5 = foo.bar($v4);
  let $v6 = foo[bar](10);
  let $v7 = 10 + "abc";
  let $v8 = foo[$v7](true);
  let $v9 = foo.bar;
  let $v10 = $v9;
  let $v11 = undefined;
  let $v12 = $v9 !== null;
  let $v13 = $v9 !== undefined;
  let $v14 = $v12 && $v13;
  if ($v14) {
    $v11 = $v10(10);
  }
  let $v15 = foo.bar;
  let $v16 = $v15;
  let $v18 = undefined;
  let $v19 = $v15 !== null;
  let $v20 = $v15 !== undefined;
  let $v21 = $v19 && $v20;
  if ($v21) {
    let $v17 = 10 + "abc";
    $v18 = $v16($v17);
  }

  $ graphjs parse new.js
  let $v1 = new foo();
  let $v2 = new foo(10);
  let $v3 = new foo(10, "abc", true);
  let $v4 = 10 + "abc";
  let $v5 = new foo($v4);
  let $v6 = 10 + "abc";
  let $v7 = new $v6(true);
