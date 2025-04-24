Flag for using unsafe literal properties
  $ graphjs mdg --no-export literal_mode.js
  obj[l_1] --< V(*) >--> obj[l_2]
  obj[l_1] --< P(*) >--> obj.*[l_3]
  10[v_2] --< V(*) >--> $v1[l_4]
  obj[l_2] --< P(*) >--> 10[v_2]
  obj.*[l_3] --< V(*) >--> $v1[l_4]
  20[v_3] -
  $v1[l_4] --< P(*) >--> 20[v_3]
  10[v_4] --< D >--> $v2[l_5]
  "abc"[v_5] --< D >--> $v2[l_5]
  $v2[l_5] -

  $ graphjs mdg --no-export literal_mode.js --literal-mode single
  [[literal]] --< V(*) >--> $v1[l_4]
  [[literal]] --< D >--> $v2[l_5]
  obj[l_1] --< V(*) >--> obj[l_2]
  obj[l_1] --< P(*) >--> obj.*[l_3]
  obj[l_2] --< P(*) >--> [[literal]]
  obj.*[l_3] --< V(*) >--> $v1[l_4]
  $v1[l_4] --< P(*) >--> [[literal]]
  $v2[l_5] -

  $ graphjs mdg --no-export literal_mode.js --literal-mode propwrap
  [[literal]] --< D >--> $v2[l_5]
  obj[l_1] --< V(*) >--> obj[l_2]
  obj[l_1] --< P(*) >--> obj.*[l_3]
  10[v_2] --< V(*) >--> $v1[l_4]
  obj[l_2] --< P(*) >--> 10[v_2]
  obj.*[l_3] --< V(*) >--> $v1[l_4]
  20[v_3] -
  $v1[l_4] --< P(*) >--> 20[v_3]
  $v2[l_5] -



Flag for marking exported values as tainted sources
  $ graphjs mdg --no-export no_tainted_sources.js
  module[l_2] --< P(exports) >--> exports[l_4]
  exports[l_4] --< V(foo) >--> exports[l_5]
  foo[f_1] --< Param(0) >--> this[p_0]
  foo[f_1] --< Param(1) >--> x[p_1]
  foo[f_1] --< Param(2) >--> y[p_2]
  this[p_0] -
  x[p_1] -
  y[p_2] --< P(p) >--> y.p[l_1]
  y.p[l_1] -
  exports[l_5] --< P(foo) >--> foo[f_1]
  exports[l_5] --< V(foo) >--> exports[l_9]
  $v2[l_6] --< V(q) >--> $v2[l_8]
  $v3[l_7] -
  $v2[l_8] --< P(q) >--> $v3[l_7]
  exports[l_9] --< P(foo) >--> $v2[l_8]
  [[taint]] --< D >--> exports[l_4]
  [[taint]] --< D >--> $v3[l_7]
  [[taint]] --< D >--> $v2[l_8]

  $ graphjs mdg --no-export no_tainted_sources.js --no-tainted-sources
  module[l_2] --< P(exports) >--> exports[l_4]
  exports[l_4] --< V(foo) >--> exports[l_5]
  foo[f_1] --< Param(0) >--> this[p_0]
  foo[f_1] --< Param(1) >--> x[p_1]
  foo[f_1] --< Param(2) >--> y[p_2]
  this[p_0] -
  x[p_1] -
  y[p_2] --< P(p) >--> y.p[l_1]
  y.p[l_1] -
  exports[l_5] --< P(foo) >--> foo[f_1]
  exports[l_5] --< V(foo) >--> exports[l_9]
  $v2[l_6] --< V(q) >--> $v2[l_8]
  $v3[l_7] -
  $v2[l_8] --< P(q) >--> $v3[l_7]
  exports[l_9] --< P(foo) >--> $v2[l_8]
