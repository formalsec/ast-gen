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
  let $v6 = 10 + "abc";
  let $v7 = foo[$v6](true);
  let $v8 = foo.bar;
  let $v9 = $v8;
  let $v10 = undefined;
  let $v11 = $v8 !== null;
  let $v12 = $v8 !== undefined;
  let $v13 = $v11 && $v12;
  if ($v13) {
    $v10 = $v9(10);
  }
  let $v14 = foo.bar;
  let $v15 = $v14;
  let $v17 = undefined;
  let $v18 = $v14 !== null;
  let $v19 = $v14 !== undefined;
  let $v20 = $v18 && $v19;
  if ($v20) {
    let $v16 = 10 + "abc";
    $v17 = $v15($v16);
  }

  $ graphjs parse new.js
  let $v1 = new foo();
  let $v2 = new foo(10);
  let $v3 = new foo(10, "abc", true);
  let $v4 = 10 + "abc";
  let $v5 = new foo($v4);
  let $v6 = 10 + "abc";
  let $v7 = new $v6(true);
