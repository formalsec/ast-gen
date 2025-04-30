  $ graphjs parse --mode multifile --verbose stdlib.js 2>&1 | sed '/^\[info\] Dependency tree.*$/d'
  [info] Workspace "" generated successfully.
  {
    "stdlib.js": {}
  }
  [info] Initializing normalization of the 'stdlib.js' module...
  [info] Module 'stdlib.js' normalized successfully.
  const dep = require('child_process');
  let $v1 = dep.exec("");
