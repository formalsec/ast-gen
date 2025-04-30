  $ graphjs parse --mode multifile --verbose . 2>&1 | sed '/^\[info\] Dependency tree.*$/d'
  [info] Workspace "" generated successfully.
  {
    "main.js": {
      "dependency.js": {}
    }
  }
  [info] Initializing normalization of the 'dependency.js' module...
  [info] Module 'dependency.js' normalized successfully.
  function foo() {
    
  }
  let $v1 = {};
  $v1.foo = foo;
  module.exports = $v1;
  [info] Initializing normalization of the 'main.js' module...
  [info] Module 'main.js' normalized successfully.
  const dep = require('./dependency.js');
  let $v2 = dep.foo();
