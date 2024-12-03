  $ graphjs parse --mode=multi-file --verbose main.js
  [info] Dependency tree of "/home/arckenimuz/dev/ast-gen/_build/default/test/normalization/nodejs/main.t/main.js" generated successfully.
  "/home/arckenimuz/dev/ast-gen/_build/default/test/normalization/nodejs/main.t/main.js": {
    "/home/arckenimuz/dev/ast-gen/_build/default/test/normalization/nodejs/main.t/dependency.js": {}
  }
  [info] File "/home/arckenimuz/dev/ast-gen/_build/default/test/normalization/nodejs/main.t/dependency.js" normalized successfully.
  var foo = function () {
    
  }
  let $v1 = {};
  $v1.foo = foo;
  module.exports = $v1;
  [info] File "/home/arckenimuz/dev/ast-gen/_build/default/test/normalization/nodejs/main.t/main.js" normalized successfully.
  const dep = require('dependency.js');
  let $v2 = dep.foo();
