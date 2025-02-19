  $ graphjs parse --mode=multifile --verbose main.js 2>&1 | sed '/^\[info\] Dependency tree.*$/d'
  [info] Workspace "" generated successfully.
  {
    "main.js": {
      "dependency.js": {
        "main.js": {}
      }
    }
  }
  [info] Initializing normalization of the 'dependency.js' module...
  [info] Module 'dependency.js' normalized successfully.
  var foo = function () {
    
  }
  let $v1 = {};
  $v1.foo = foo;
  module.exports = $v1;
  const main = require('./main.js');
  let $v2 = main.foo();
  [info] Initializing normalization of the 'main.js' module...
  [info] Module 'main.js' normalized successfully.
  var foo = function () {
    
  }
  let $v3 = {};
  $v3.foo = foo;
  module.exports = $v3;
  const dep = require('./dependency.js');
  let $v4 = dep.foo();
