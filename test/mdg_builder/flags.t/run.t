Flag for using unsafe literal properties
  $ graphjs mdg --no-export literal_mode.js
  obj[#11] --< V(*) >--> obj[#13]
  obj[#11] --< P(*) >--> obj.*[#14]
  10[#12] --< V(*) >--> $v1[#16]
  obj[#13] --< P(*) >--> 10[#12]
  obj.*[#14] --< V(*) >--> $v1[#16]
  20[#15] -
  $v1[#16] --< P(*) >--> 20[#15]
  10[#17] --< D >--> $v2[#19]
  "abc"[#18] --< D >--> $v2[#19]
  $v2[#19] -

  $ graphjs mdg --no-export literal_mode.js --literal-mode single
  [[literal]] --< V(*) >--> $v1[#14]
  [[literal]] --< D >--> $v2[#15]
  obj[#11] --< V(*) >--> obj[#12]
  obj[#11] --< P(*) >--> obj.*[#13]
  obj[#12] --< P(*) >--> [[literal]]
  obj.*[#13] --< V(*) >--> $v1[#14]
  $v1[#14] --< P(*) >--> [[literal]]
  $v2[#15] -

  $ graphjs mdg --no-export literal_mode.js --literal-mode propwrap
  [[literal]] --< D >--> $v2[#17]
  obj[#11] --< V(*) >--> obj[#13]
  obj[#11] --< P(*) >--> obj.*[#14]
  10[#12] --< V(*) >--> $v1[#16]
  obj[#13] --< P(*) >--> 10[#12]
  obj.*[#14] --< V(*) >--> $v1[#16]
  20[#15] -
  $v1[#16] --< P(*) >--> 20[#15]
  $v2[#17] -



Flag for running the tainted analysis, marking exported values as tainted sources
  $ graphjs mdg --no-export no_tainted_sources.js
  module[#9] --< P(exports) >--> exports[#10]
  exports[#10] --< V(foo) >--> exports[#16]
  foo[#11] --< Param(0) >--> this[#12]
  foo[#11] --< Param(1) >--> x[#13]
  foo[#11] --< Param(2) >--> y[#14]
  this[#12] -
  x[#13] -
  y[#14] --< P(p) >--> y.p[#15]
  y.p[#15] -
  exports[#16] --< P(foo) >--> foo[#11]
  exports[#16] --< V(foo) >--> exports[#20]
  $v2[#17] --< V(q) >--> $v2[#19]
  $v3[#18] -
  $v2[#19] --< P(q) >--> $v3[#18]
  exports[#20] --< P(foo) >--> $v2[#19]
  [[taint]] --< D >--> exports[#10]
  [[taint]] --< D >--> $v3[#18]
  [[taint]] --< D >--> $v2[#19]

  $ graphjs mdg --no-export no_tainted_sources.js --no-tainted-analysis
  module[#9] --< P(exports) >--> exports[#10]
  exports[#10] --< V(foo) >--> exports[#16]
  foo[#11] --< Param(0) >--> this[#12]
  foo[#11] --< Param(1) >--> x[#13]
  foo[#11] --< Param(2) >--> y[#14]
  this[#12] -
  x[#13] -
  y[#14] --< P(p) >--> y.p[#15]
  y.p[#15] -
  exports[#16] --< P(foo) >--> foo[#11]
  exports[#16] --< V(foo) >--> exports[#20]
  $v2[#17] --< V(q) >--> $v2[#19]
  $v3[#18] -
  $v2[#19] --< P(q) >--> $v3[#18]
  exports[#20] --< P(foo) >--> $v2[#19]
