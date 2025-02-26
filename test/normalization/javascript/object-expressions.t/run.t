  $ graphjs parse object.js
  let $v1 = {};
  $v1;
  let $v2 = {};
  $v2.foo = 10;
  $v2;
  let $v3 = {};
  $v3.foo = 10;
  $v3.bar = "abc";
  $v3.baz = true;
  $v3;
  let $v4 = {};
  $v4.foo = 10;
  let $v5 = {};
  $v5.baz = "abc";
  $v5.qux = true;
  $v4.bar = $v5;
  $v4;
  let $v6 = {};
  $v6["foo"] = 10;
  $v6[20] = "abc";
  $v6[30n] = true;
  $v6;
  let $v7 = {};
  let $v8 = 10 + "abc";
  $v7[$v8] = true;
  $v7;

  $ graphjs parse array.js
  let $v1 = [];
  $v1;
  let $v2 = [];
  $v2;
  let $v3 = [];
  $v3[0] = 10;
  $v3;
  let $v4 = [];
  $v4[0] = 10;
  $v4[1] = "abc";
  $v4[2] = true;
  $v4;
  let $v5 = [];
  $v5[0] = 10;
  let $v6 = [];
  $v6[0] = "abc";
  $v6[1] = true;
  $v5[1] = $v6;
  $v5;
  let $v7 = [];
  $v7[0] = 10;
  $v7[1] = "abc";
  $v7;
  let $v8 = [];
  let $v9 = 10 + "abc";
  $v8[0] = $v9;
  $v8;

  $ graphjs parse method.js
  let $v1 = {};
  let $v2 = function () {
    
  }
  $v1.foo = $v2;
  $v1;
  let $v3 = {};
  let $v4 = function () {
    
  }
  $v3[10] = $v4;
  $v3;
  let $v5 = {};
  let $v6 = function () {
    
  }
  $v5[foo] = $v6;
  $v5;
  let $v7 = {};
  let $v8 = function () {
    
  }
  let $v9 = {};
  $v9.get = $v8;
  $v9.configurable = true;
  let $v10 = Object.defineProperty($v7, "foo", $v9);
  $v7;
  let $v11 = {};
  let $v12 = function () {
    
  }
  let $v13 = {};
  $v13.get = $v12;
  $v13.configurable = true;
  let $v14 = Object.defineProperty($v11, 10, $v13);
  $v11;
  let $v15 = {};
  let $v16 = function () {
    
  }
  let $v17 = {};
  $v17.get = $v16;
  $v17.configurable = true;
  let $v18 = Object.defineProperty($v15, foo, $v17);
  $v15;
  let $v19 = {};
  let $v20 = function (x) {
    
  }
  let $v21 = {};
  $v21.set = $v20;
  $v21.configurable = true;
  let $v22 = Object.defineProperty($v19, "foo", $v21);
  $v19;
  let $v23 = {};
  let $v24 = function (x) {
    
  }
  let $v25 = {};
  $v25.set = $v24;
  $v25.configurable = true;
  let $v26 = Object.defineProperty($v23, 10, $v25);
  $v23;
  let $v27 = {};
  let $v28 = function (x) {
    
  }
  let $v29 = {};
  $v29.set = $v28;
  $v29.configurable = true;
  let $v30 = Object.defineProperty($v27, foo, $v29);
  $v27;
  let $v31 = {};
  let $v32 = function () {
    
  }
  $v31.foo = $v32;
  let $v33 = function () {
    
  }
  let $v34 = {};
  $v34.get = $v33;
  $v34.configurable = true;
  let $v35 = Object.defineProperty($v31, "bar", $v34);
  let $v36 = function (x) {
    
  }
  let $v37 = {};
  $v37.set = $v36;
  $v37.configurable = true;
  let $v38 = Object.defineProperty($v31, "baz", $v37);
  $v31;

  $ graphjs parse member.js
  let $v1 = {};
  let $v2 = $v1.foo;
  $v2;
  let $v3 = {};
  let $v4 = $v3.foo;
  let $v5 = $v4.bar;
  $v5;
  let $v6 = {};
  let $v7 = $v6[null];
  $v7;
  let $v8 = {};
  let $v9 = $v8["foo"];
  $v9;
  let $v10 = {};
  let $v11 = $v10[10];
  $v11;
  let $v12 = {};
  let $v13 = $v12[10n];
  $v13;
  let $v14 = {};
  let $v15 = $v14[true];
  $v15;
  let $v16 = {};
  let $v17 = 10 + "abc";
  let $v18 = $v16[$v17];
  $v18;
  let $v19 = {};
  let $v20 = $v19.foo;
  let $v21 = undefined;
  let $v22 = $v20 !== null;
  let $v23 = $v20 !== undefined;
  let $v24 = $v22 && $v23;
  if ($v24) {
    $v21 = $v20.bar;
  }
  $v21;
  let $v25 = {};
  let $v26 = $v25.foo;
  let $v27 = undefined;
  let $v28 = $v26 !== null;
  let $v29 = $v26 !== undefined;
  let $v30 = $v28 && $v29;
  if ($v30) {
    $v27 = $v26.bar;
  }
  let $v31 = undefined;
  let $v32 = $v27 !== null;
  let $v33 = $v27 !== undefined;
  let $v34 = $v32 && $v33;
  if ($v34) {
    $v31 = $v27.baz;
  }
  $v31;
