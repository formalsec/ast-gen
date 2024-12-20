  $ graphjs parse --mode=multi-file --verbose main.js
  [info] Workspace "" generated successfully.
  [info] Dependency tree "/home/arckenimuz/dev/ast-gen/_build/default/test/normalization/nodejs/recursive.t/main.js" generated successfully.
  {
    "/home/arckenimuz/dev/ast-gen/_build/default/test/normalization/nodejs/recursive.t/main.js": {
      "/home/arckenimuz/dev/ast-gen/_build/default/test/normalization/nodejs/recursive.t/dependency.js": {
        "/home/arckenimuz/dev/ast-gen/_build/default/test/normalization/nodejs/recursive.t/main.js": {}
      }
    }
  }
  [info] File "/home/arckenimuz/dev/ast-gen/_build/default/test/normalization/nodejs/recursive.t/dependency.js" normalized successfully.
  var foo = function () {
    
  }
  let $v1 = {};
  $v1.foo = foo;
  module.exports = $v1;
  const main = require('main.js');
  let $v2 = main.foo();
  [info] File "/home/arckenimuz/dev/ast-gen/_build/default/test/normalization/nodejs/recursive.t/main.js" normalized successfully.
  var foo = function () {
    
  }
  let $v3 = {};
  $v3.foo = foo;
  module.exports = $v3;
  const dep = require('dependency.js');
  let $v4 = dep.foo();
