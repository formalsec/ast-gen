  $ graphjs parse --mode multifile --verbose dir/main.js 2>&1 | sed '/^\[info\] Dependency tree.*$/d'
  [info] Workspace "" generated successfully.
  {
    "main.js": {
      "../dependency.js": {
        "library.js": {}
      }
    }
  }
  [info] Initializing normalization of the 'library.js' module...
  [info] Module 'library.js' normalized successfully.
  function bar() {
    
  }
  let $v1 = {};
  $v1.bar = bar;
  module.exports = $v1;
  [info] Initializing normalization of the '../dependency.js' module...
  [info] Module '../dependency.js' normalized successfully.
  const lib = require('./dir/library.js');
  let $v2 = lib.bar();
  function foo() {
    
  }
  let $v3 = {};
  $v3.foo = foo;
  module.exports = $v3;
  [info] Initializing normalization of the 'main.js' module...
  [info] Module 'main.js' normalized successfully.
  const dep = require('../dependency.js');
  let $v4 = dep.foo();
