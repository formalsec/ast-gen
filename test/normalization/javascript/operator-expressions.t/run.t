  $ graphjs parse unary.js
  let $v1 = +10;
  $v1;
  let $v2 = +10;
  let $v3 = +$v2;
  $v3;
  let $v4 = -10;
  $v4;
  let $v5 = ~10;
  $v5;
  let $v6 = !true;
  $v6;
  let $v7 = typeof 10;
  $v7;
  let $v8 = void 10;
  $v8;
  let $v9 = delete 10;
  $v9;
  let $v10 = delete foo.bar;
  $v10;
  let $v11 = delete foo["bar"];
  $v11;

  $ graphjs parse binary.js
  let $v1 = 10 + 5;
  $v1;
  let $v2 = 10 + 5;
  let $v3 = $v2 + 2;
  $v3;
  let $v4 = 10 - 5;
  $v4;
  let $v5 = 10 * 5;
  $v5;
  let $v6 = 10 / 5;
  $v6;
  let $v7 = 10 % 5;
  $v7;
  let $v8 = 10 ** 5;
  $v8;
  let $v9 = 10 & 5;
  $v9;
  let $v10 = 10 | 5;
  $v10;
  let $v11 = 10 ^ 5;
  $v11;
  let $v12 = 10 << 5;
  $v12;
  let $v13 = 10 >> 5;
  $v13;
  let $v14 = 10 >>> 5;
  $v14;
  let $v15 = 10 == 5;
  $v15;
  let $v16 = 10 != 5;
  $v16;
  let $v17 = 10 === 5;
  $v17;
  let $v18 = 10 !== 5;
  $v18;
  let $v19 = 10 < 5;
  $v19;
  let $v20 = 10 <= 5;
  $v20;
  let $v21 = 10 > 5;
  $v21;
  let $v22 = 10 >= 5;
  $v22;
  let $v23 = 10 instanceof 5;
  $v23;
  let $v24 = 10 in 5;
  $v24;

  $ graphjs parse logical.js
  let $v1 = true && true;
  if ($v1) {
    $v1 = false && true;
  }
  $v1;
  let $v2 = true && false;
  if ($v2) {
    
  } else {
    $v2 = false && false;
  }
  $v2;
  let $v3 = 10;
  let $v4 = 10 === null;
  let $v5 = 10 === undefined;
  let $v6 = $v4 || $v5;
  if ($v6) {
    $v3 = "abc";
  }
  $v3;

  $ graphjs parse conditional.js
  let $v1;
  if (true) {
    $v1 = 10;
  } else {
    $v1 = "abc";
  }
  $v1;

  $ graphjs parse update.js
  foo = foo + 1;
  let $v1 = foo;
  foo = foo - 1;
  let $v2 = foo;
  let $v3 = foo;
  foo = foo + 1;
  let $v4 = foo;
  foo = foo - 1;
  let $v6 = foo.bar;
  let $v6 = $v6 + 1;
  let $v5 = $v6;
  foo.bar = $v6;
  let $v8 = foo[bar];
  let $v7 = $v8;
  let $v8 = $v8 + 1;
  foo[bar] = $v8;
