  $ graphjs mdg --no-svg --mode=singlefile dependency.js
  [[literal]] -
  foo[f_1] --< Param(0) >--> this[p_0]
  this[p_0] -
  $v1[l_1] --< V(foo) >--> $v1[l_2]
  $v1[l_2] --< P(foo) >--> foo[f_1]
  $v1[l_2] --< [[RefParent(foo)]] >--> $v1[l_1]

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
  foo[f_1] --< Param(0) >--> this[p_0]
  this[p_0] -
  $v1[l_1] --< V(foo) >--> $v1[l_2]
  $v1[l_2] --< P(foo) >--> foo[f_1]
  $v1[l_2] --< [[RefParent(foo)]] >--> $v1[l_1]

  $ graphjs mdg --no-svg --mode=multifile main.js
  [[literal]] --< Arg(1) >--> require(...)[l_3]
  require[f_2] -
  require(...)[l_3] --< Call >--> require[f_2]
  require(...)[l_3] --< Ret >--> dep[l_4]
  dep[l_4] --< P(foo) >--> dep.foo[l_6]
  dep[l_4] --< Arg(0) >--> dep.foo(...)[l_7]
  require(dependency.js)[l_5] --< D >--> dep[l_4]
  dep.foo[l_6] -
  dep.foo(...)[l_7] --< Call >--> dep.foo[l_6]
  dep.foo(...)[l_7] --< Ret >--> $v2[l_8]
  $v2[l_8] -
