  $ graphjs parse sequence.js
  "abc";
  true;
  let $v1 = 10 * 20;
  let $v2 = "abc" + "def";
  let $v3 = true && true;
  if ($v3) {
    $v3 = false && true;
  }
  $v3;

  $ graphjs parse yield.js
  let $v1 = function* () {
    let $v2 = yield;
  }
  let $v3 = function* () {
    let $v4 = yield 10;
  }
  let $v5 = function* () {
    let $v6 = yield* 10;
  }
  let $v7 = function* () {
    let $v8 = function* () {
      let $v9 = yield 10;
    }
    let $v10 = $v8();
    let $v11 = yield* $v10;
  }

$ graphjs parse metaproperty.js
[error] Flow was unable to parse the file "/home/arckenimuz/dev/ast-gen/_build/default/test/normalization/javascript/other-expressions.t/metaproperty.js".
Unexpected token `.`
File "/home/arckenimuz/dev/ast-gen/_build/default/test/normalization/javascript/other-expressions.t/metaproperty.js", line 2, characters 7-8
[3]

  $ graphjs parse tagged_template.js
  let $v1 = [];
  $v1[0] = "abc";
  let $v2 = foo($v1);
  let $v3 = [];
  $v3[0] = "abc\n def";
  let $v4 = foo($v3);
  let $v5 = [];
  $v5[0] = "abc";
  $v5[1] = " def";
  let $v6 = foo($v5, 10);
  let $v7 = [];
  $v7[0] = "abc";
  $v7[1] = " def";
  $v7[2] = "";
  let $v8 = foo($v7, 10, true);
  let $v9 = 10 + true;
  let $v10 = [];
  $v10[0] = "abc";
  $v10[1] = "";
  let $v11 = foo($v10, $v9);

  $ graphjs parse dynamic_import.js
  let $v1 = import("");
  let $v2 = import("foo");
  let $v3 = "foo" + "bar";
  let $v4 = import($v3);
