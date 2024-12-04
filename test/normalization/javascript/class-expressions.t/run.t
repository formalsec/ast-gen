  $ graphjs parse constructor.js
  let $v1 = function () {
    
  }
  let $v2 = $v1.prototype;
  $v2.constructor = $v1;
  let $v3 = function () {
    
  }
  let $v4 = $v3.prototype;
  $v4.constructor = $v3;
  let $v5 = function (foo) {
    
  }
  let $v6 = $v5.prototype;
  $v6.constructor = $v5;
  let $v7 = function (foo, bar, baz) {
    
  }
  let $v8 = $v7.prototype;
  $v8.constructor = $v7;
  let $v9 = function (foo) {
    this.foo = foo;
  }
  let $v10 = $v9.prototype;
  $v10.constructor = $v9;

  $ graphjs parse property.js
  let $v1 = function () {
    
  }
  let $v2 = $v1.prototype;
  $v2.constructor = $v1;
  $v2.foo = undefined;
  let $v3 = function () {
    
  }
  let $v4 = $v3.prototype;
  $v4.constructor = $v3;
  $v4[10] = undefined;
  let $v5 = function () {
    
  }
  let $v6 = $v5.prototype;
  $v6.constructor = $v5;
  $v6[foo] = undefined;
  let $v7 = function () {
    
  }
  let $v8 = $v7.prototype;
  $v8.constructor = $v7;
  $v7.foo = undefined;
  let $v9 = function () {
    
  }
  let $v10 = $v9.prototype;
  $v10.constructor = $v9;
  $v10.foo = 10;
  let $v11 = function () {
    
  }
  let $v12 = $v11.prototype;
  $v12.constructor = $v11;
  $v12[10] = 10;
  let $v13 = function () {
    
  }
  let $v14 = $v13.prototype;
  $v14.constructor = $v13;
  $v14[foo] = 10;
  let $v15 = function () {
    
  }
  let $v16 = $v15.prototype;
  $v16.constructor = $v15;
  $v15.foo = 10;

  $ graphjs parse method.js
  let $v1 = function () {
    
  }
  let $v2 = $v1.prototype;
  $v2.constructor = $v1;
  let $v3 = function () {
    
  }
  $v2.foo = $v3;
  let $v4 = function () {
    
  }
  let $v5 = $v4.prototype;
  $v5.constructor = $v4;
  let $v6 = function () {
    
  }
  $v5[10] = $v6;
  let $v7 = function () {
    
  }
  let $v8 = $v7.prototype;
  $v8.constructor = $v7;
  let $v9 = function () {
    
  }
  $v8[foo] = $v9;
  let $v10 = function () {
    
  }
  let $v11 = $v10.prototype;
  $v11.constructor = $v10;
  let $v12 = function () {
    
  }
  $v10.foo = $v12;
  let $v13 = function () {
    
  }
  let $v14 = $v13.prototype;
  $v14.constructor = $v13;
  let $v15 = function () {
    
  }
  let $v16 = {};
  $v16.get = $v15;
  $v16.configurable = true;
  let $v17 = Object.defineProperty($v14, "foo", $v16);
  let $v18 = function () {
    
  }
  let $v19 = $v18.prototype;
  $v19.constructor = $v18;
  let $v20 = function () {
    
  }
  let $v21 = {};
  $v21.get = $v20;
  $v21.configurable = true;
  let $v22 = Object.defineProperty($v19, 10, $v21);
  let $v23 = function () {
    
  }
  let $v24 = $v23.prototype;
  $v24.constructor = $v23;
  let $v25 = function () {
    
  }
  let $v26 = {};
  $v26.get = $v25;
  $v26.configurable = true;
  let $v27 = Object.defineProperty($v24, foo, $v26);
  let $v28 = function () {
    
  }
  let $v29 = $v28.prototype;
  $v29.constructor = $v28;
  let $v30 = function () {
    
  }
  let $v31 = {};
  $v31.get = $v30;
  $v31.configurable = true;
  let $v32 = Object.defineProperty($v28, "foo", $v31);
  let $v33 = function () {
    
  }
  let $v34 = $v33.prototype;
  $v34.constructor = $v33;
  let $v35 = function (bar) {
    
  }
  let $v36 = {};
  $v36.set = $v35;
  $v36.configurable = true;
  let $v37 = Object.defineProperty($v34, "foo", $v36);
  let $v38 = function () {
    
  }
  let $v39 = $v38.prototype;
  $v39.constructor = $v38;
  let $v40 = function (bar) {
    
  }
  let $v41 = {};
  $v41.set = $v40;
  $v41.configurable = true;
  let $v42 = Object.defineProperty($v39, 10, $v41);
  let $v43 = function () {
    
  }
  let $v44 = $v43.prototype;
  $v44.constructor = $v43;
  let $v45 = function (bar) {
    
  }
  let $v46 = {};
  $v46.set = $v45;
  $v46.configurable = true;
  let $v47 = Object.defineProperty($v44, foo, $v46);
  let $v48 = function () {
    
  }
  let $v49 = $v48.prototype;
  $v49.constructor = $v48;
  let $v50 = function (bar) {
    
  }
  let $v51 = {};
  $v51.set = $v50;
  $v51.configurable = true;
  let $v52 = Object.defineProperty($v48, "foo", $v51);
  let $v53 = function () {
    
  }
  let $v54 = $v53.prototype;
  $v54.constructor = $v53;
  let $v55 = function () {
    
  }
  let $v56 = {};
  $v56.get = $v55;
  $v56.configurable = true;
  let $v57 = Object.defineProperty($v54, "foo", $v56);
  let $v58 = function (bar) {
    
  }
  let $v59 = {};
  $v59.set = $v58;
  $v59.configurable = true;
  let $v60 = Object.defineProperty($v54, "foo", $v59);
  let $v61 = function () {
    
  }
  let $v62 = $v61.prototype;
  $v62.constructor = $v61;
  let $v63 = function () {
    
  }
  let $v64 = {};
  $v64.get = $v63;
  $v64.configurable = true;
  let $v65 = Object.defineProperty($v61, "foo", $v64);
  let $v66 = function (bar) {
    
  }
  let $v67 = {};
  $v67.set = $v66;
  $v67.configurable = true;
  let $v68 = Object.defineProperty($v61, "foo", $v67);

  $ graphjs parse extends.js
  let $v1 = function () {
    let $v2 = this.__proto__;
    $v2 = $v2.__proto__;
    let $v3 = $v2.constructor();
  }
  let $v4 = $v1.prototype;
  $v4.constructor = $v1;
  let $v5 = Foo.prototype;
  $v1.__proto__ = Foo;
  $v4.__proto__ = $v5;
  let $v6 = function () {
    let $v7 = this.__proto__;
    $v7 = $v7.__proto__;
    let $v8 = $v7.constructor();
  }
  let $v9 = $v6.prototype;
  $v9.constructor = $v6;
  let $v10 = Foo.prototype;
  $v6.__proto__ = Foo;
  $v9.__proto__ = $v10;
  let $v11 = function () {
    let $v12 = this.__proto__;
    $v12 = $v12.__proto__;
    let $v13 = $v12.constructor();
  }
  let $v14 = $v11.prototype;
  $v14.constructor = $v11;
  let $v15 = Foo.prototype;
  $v11.__proto__ = Foo;
  $v14.__proto__ = $v15;
  let $v16 = function () {
    let $v17 = this.__proto__;
    $v17 = $v17.__proto__;
    let $v18 = $v17.bar;
    $v18;
  }
  $v14.bar = $v16;
  let $v19 = function () {
    let $v20 = this.__proto__;
    $v20 = $v20.__proto__;
    let $v21 = $v20.constructor();
  }
  let $v22 = $v19.prototype;
  $v22.constructor = $v19;
  let $v23 = Foo.prototype;
  $v19.__proto__ = Foo;
  $v22.__proto__ = $v23;
  let $v24 = function () {
    let $v25 = this.__proto__;
    $v25 = $v25.__proto__;
    $v25.bar = 10;
  }
  $v22.bar = $v24;
  let $v26 = function () {
    let $v27 = this.__proto__;
    $v27 = $v27.__proto__;
    let $v28 = $v27.constructor();
  }
  let $v29 = $v26.prototype;
  $v29.constructor = $v26;
  let $v30 = Foo.prototype;
  $v26.__proto__ = Foo;
  $v29.__proto__ = $v30;
  let $v31 = function () {
    let $v32 = this.__proto__;
    $v32 = $v32.__proto__;
    let $v33 = $v32.bar();
  }
  $v29.bar = $v31;
