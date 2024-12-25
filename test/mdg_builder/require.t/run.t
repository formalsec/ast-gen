  $ graphjs mdg --no-svg --mode=singlefile dependency.js
  [[literal]] -
  module[l_3] --< V(exports) >--> module[l_4]
  foo[f_1] --< Param(0) >--> this[p_0]
  this[p_0] -
  $v1[l_1] --< V(foo) >--> $v1[l_2]
  $v1[l_2] --< P(foo) >--> foo[f_1]
  $v1[l_2] --< [[RefParent(foo)]] >--> $v1[l_1]
  module[l_4] --< [[RefParent(exports)]] >--> module[l_3]
  module[l_4] --< P(exports) >--> $v1[l_2]

  $ graphjs mdg --no-svg --mode=singlefile main.js
  [[literal]] --< Arg(1) >--> require(...)[l_1]
  require[f_1] -
  require(...)[l_1] --< Call >--> require[f_1]
  require(...)[l_1] --< Ret >--> dep[l_2]
  dep[l_2] --< P(foo) >--> dep.foo[l_4]
  dep[l_2] --< Arg(0) >--> dep.foo(...)[l_5]
  require(dependency.js)[l_3] --< D >--> dep[l_2]
  dep.foo[l_4] -
  dep.foo(...)[l_5] --< Call >--> dep.foo[l_4]
  dep.foo(...)[l_5] --< Ret >--> $v1[l_6]
  $v1[l_6] -

  $ graphjs mdg --no-svg --mode=multifile dependency.js
  [[literal]] -
  module[l_3] --< V(exports) >--> module[l_4]
  foo[f_1] --< Param(0) >--> this[p_0]
  this[p_0] -
  $v1[l_1] --< V(foo) >--> $v1[l_2]
  $v1[l_2] --< P(foo) >--> foo[f_1]
  $v1[l_2] --< [[RefParent(foo)]] >--> $v1[l_1]
  module[l_4] --< [[RefParent(exports)]] >--> module[l_3]
  module[l_4] --< P(exports) >--> $v1[l_2]

  $ graphjs mdg --no-svg --mode=multifile main.js
  [[literal]] --< Arg(1) >--> require(...)[l_5]
  require[f_2] -
  require(...)[l_5] --< Call >--> require[f_2]
  require(...)[l_5] --< Ret >--> dep[l_6]
  dep[l_6] --< P(foo) >--> dep.foo[l_8]
  dep[l_6] --< Arg(0) >--> dep.foo(...)[l_9]
  require(dependency.js)[l_7] --< D >--> dep[l_6]
  dep.foo[l_8] -
  dep.foo(...)[l_9] --< Call >--> dep.foo[l_8]
  dep.foo(...)[l_9] --< Ret >--> $v2[l_10]
  $v2[l_10] -
