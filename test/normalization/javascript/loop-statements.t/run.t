  $ graphjs parse while.js
  while (10) {
    
  }
  while (10) {
    
  }
  while (10) {
    x;
  }
  while (10) {
    x;
  }
  while (10) {
    while ("abc") {
      x;
    }
  }
  let $v1 = 10 + "abc";
  let $v2 = $v1 == true;
  while ($v2) {
    x;
    $v1 = 10 + "abc";
    $v2 = $v1 == true;
  }

  $ graphjs parse dowhile.js
  let $v1 = true;
  while ($v1) {
    $v1 = 10;
  }
  let $v2 = true;
  while ($v2) {
    $v2 = 10;
  }
  let $v3 = true;
  while ($v3) {
    x;
    $v3 = 10;
  }
  let $v4 = true;
  while ($v4) {
    x;
    $v4 = 10;
  }
  let $v5 = true;
  while ($v5) {
    let $v6 = true;
    while ($v6) {
      x;
      $v6 = "abc";
    }
    $v5 = 10;
  }
  let $v7 = true;
  while ($v7) {
    x;
    let $v8 = 10 + "abc";
    let $v9 = $v8 == true;
    $v7 = $v9;
  }

  $ graphjs parse for.js
  let i = 10;
  let $v1 = i < 20;
  while ($v1) {
    let $v2 = i;
    i = i + 1;
    $v1 = i < 20;
  }
  let i = 10;
  let $v3 = i < 20;
  while ($v3) {
    let $v4 = i;
    i = i + 1;
    $v3 = i < 20;
  }
  let i = 10;
  let $v5 = i < 20;
  while ($v5) {
    x;
    let $v6 = i;
    i = i + 1;
    $v5 = i < 20;
  }
  let i = 10;
  let $v7 = i < 20;
  while ($v7) {
    x;
    let $v8 = i;
    i = i + 1;
    $v7 = i < 20;
  }
  const i = 10;
  let $v9 = i < 20;
  while ($v9) {
    x;
    let $v10 = i;
    i = i + 1;
    $v9 = i < 20;
  }
  i = 10;
  let $v11 = i < 20;
  while ($v11) {
    x;
    let $v12 = i;
    i = i + 1;
    $v11 = i < 20;
  }
  let $v13 = i < 20;
  while ($v13) {
    x;
    let $v14 = i;
    i = i + 1;
    $v13 = i < 20;
  }
  let i = 10;
  while (true) {
    x;
    let $v15 = i;
    i = i + 1;
  }
  let i = 10;
  let $v16 = i < 20;
  while ($v16) {
    x;
    $v16 = i < 20;
  }
  while (true) {
    x;
  }
  let i = 10;
  let $v17 = i < 20;
  while ($v17) {
    j = i;
    let $v18 = j < 20;
    while ($v18) {
      x;
      let $v19 = j;
      j = j + 1;
      $v18 = j < 20;
    }
    let $v20 = i;
    i = i + 1;
    $v17 = i < 20;
  }
  let i = 10;
  let j = 20;
  let $v21 = i < 20;
  while ($v21) {
    x;
    let $v22 = i;
    i = i + 1;
    let $v23 = j;
    j = j + 1;
    $v21 = i < 20;
  }
  let i = 10 + 20;
  let $v24 = i < 30;
  while ($v24) {
    x;
    let $v25 = i;
    i = i + 1;
    $v24 = i < 30;
  }
  let i = 10;
  let $v26 = i > 10;
  let $v27 = $v26 && true;
  if ($v27) {
    let $v28 = i < 20;
    $v27 = $v28 && true;
  }
  while ($v27) {
    x;
    let $v29 = i;
    i = i + 1;
    $v26 = i > 10;
    $v27 = $v26 && true;
    if ($v27) {
      let $v28 = i < 20;
      $v27 = $v28 && true;
    }
  }

  $ graphjs parse forin.js
  for (let foo in bar) {
    
  }
  for (let foo in bar) {
    
  }
  for (let foo in bar) {
    x;
  }
  for (let foo in bar) {
    x;
  }
  for (const foo in bar) {
    x;
  }
  for (foo in bar) {
    x;
  }
  for (let foo in bar) {
    for (let baz in qux) {
      x;
    }
  }
  let $v1 = bar + baz;
  for (var foo in $v1) {
    x;
  }
  for (let $v2 in baz) {
    foo.bar = $v2;
    x;
  }
  for (let $v3 in baz) {
    foo[bar] = $v3;
    x;
  }
  for (let $v4 in qux) {
    foo = $v4.foo;
    bar = $v4.bar;
    x;
  }
  for (let $v5 in qux) {
    foo = $v5.foo;
    let $v6 = foo === undefined;
    if ($v6) {
      foo = 10;
    }
    bar = $v5.bar;
    let $v7 = bar === undefined;
    if ($v7) {
      let $v8 = {};
      $v8.baz = "abc";
      bar = $v8;
    }
    x;
  }
  for (let $v9 in qux) {
    foo = $v9[0];
    bar = $v9[1];
    x;
  }
  for (let $v10 in qux) {
    foo = $v10[0];
    let $v11 = foo === undefined;
    if ($v11) {
      foo = 10;
    }
    bar = $v10[1];
    let $v12 = bar === undefined;
    if ($v12) {
      let $v13 = [];
      $v13[0] = "abc";
      $v13[1] = true;
      bar = $v13;
    }
    x;
  }

  $ graphjs parse forof.js
  for (let foo of bar) {
    
  }
  for (let foo of bar) {
    
  }
  for (let foo of bar) {
    x;
  }
  for (let foo of bar) {
    x;
  }
  for (const foo of bar) {
    x;
  }
  for (foo of bar) {
    x;
  }
  for (let foo of bar) {
    for (let baz of qux) {
      x;
    }
  }
  let $v1 = async function () {
    for await (let foo of bar) {
      x;
    }
  }
  let $v2 = bar + baz;
  for (var foo of $v2) {
    x;
  }
  for (let $v3 of baz) {
    foo.bar = $v3;
    x;
  }
  for (let $v4 of baz) {
    foo[bar] = $v4;
    x;
  }
  for (let $v5 of qux) {
    foo = $v5.foo;
    bar = $v5.bar;
    x;
  }
  for (let $v6 of qux) {
    foo = $v6.foo;
    let $v7 = foo === undefined;
    if ($v7) {
      foo = 10;
    }
    bar = $v6.bar;
    let $v8 = bar === undefined;
    if ($v8) {
      let $v9 = {};
      $v9.baz = "abc";
      bar = $v9;
    }
    x;
  }
  for (let $v10 of qux) {
    foo = $v10[0];
    bar = $v10[1];
    x;
  }
  for (let $v11 of qux) {
    foo = $v11[0];
    let $v12 = foo === undefined;
    if ($v12) {
      foo = 10;
    }
    bar = $v11[1];
    let $v13 = bar === undefined;
    if ($v13) {
      let $v14 = [];
      $v14[0] = "abc";
      $v14[1] = true;
      bar = $v14;
    }
    x;
  }
