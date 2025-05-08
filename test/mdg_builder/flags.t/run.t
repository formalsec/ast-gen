Flag for using unsafe literal properties
  $ graphjs mdg --no-export literal_mode.js
  obj[#10] --< V(*) >--> obj[#12]
  obj[#10] --< P(*) >--> obj.*[#13]
  10[#11] --< V(*) >--> $v1[#15]
  obj[#12] --< P(*) >--> 10[#11]
  obj.*[#13] --< V(*) >--> $v1[#15]
  20[#14] -
  $v1[#15] --< P(*) >--> 20[#14]
  10[#16] --< D >--> $v2[#18]
  "abc"[#17] --< D >--> $v2[#18]
  $v2[#18] -

  $ graphjs mdg --no-export literal_mode.js --literal-mode single
  [[literal]] --< V(*) >--> $v1[#13]
  [[literal]] --< D >--> $v2[#14]
  obj[#10] --< V(*) >--> obj[#11]
  obj[#10] --< P(*) >--> obj.*[#12]
  obj[#11] --< P(*) >--> [[literal]]
  obj.*[#12] --< V(*) >--> $v1[#13]
  $v1[#13] --< P(*) >--> [[literal]]
  $v2[#14] -

  $ graphjs mdg --no-export literal_mode.js --literal-mode propwrap
  [[literal]] --< D >--> $v2[#16]
  obj[#10] --< V(*) >--> obj[#12]
  obj[#10] --< P(*) >--> obj.*[#13]
  10[#11] --< V(*) >--> $v1[#15]
  obj[#12] --< P(*) >--> 10[#11]
  obj.*[#13] --< V(*) >--> $v1[#15]
  20[#14] -
  $v1[#15] --< P(*) >--> 20[#14]
  $v2[#16] -



Flag for running the tainted analysis, marking exported values as tainted sources
  $ graphjs mdg --no-export no_tainted_sources.js
  module[#8] --< P(exports) >--> exports[#9]
  exports[#9] --< V(foo) >--> exports[#15]
  foo[#10] --< Param(0) >--> this[#11]
  foo[#10] --< Param(1) >--> x[#12]
  foo[#10] --< Param(2) >--> y[#13]
  this[#11] -
  x[#12] -
  y[#13] --< P(p) >--> y.p[#14]
  y.p[#14] -
  exports[#15] --< P(foo) >--> foo[#10]
  exports[#15] --< V(foo) >--> exports[#19]
  $v2[#16] --< V(q) >--> $v2[#18]
  $v3[#17] -
  $v2[#18] --< P(q) >--> $v3[#17]
  exports[#19] --< P(foo) >--> $v2[#18]
  [[taint]] --< D >--> exports[#9]
  [[taint]] --< D >--> $v3[#17]
  [[taint]] --< D >--> $v2[#18]

  $ graphjs mdg --no-export no_tainted_sources.js --no-tainted-analysis
  module[#8] --< P(exports) >--> exports[#9]
  exports[#9] --< V(foo) >--> exports[#15]
  foo[#10] --< Param(0) >--> this[#11]
  foo[#10] --< Param(1) >--> x[#12]
  foo[#10] --< Param(2) >--> y[#13]
  this[#11] -
  x[#12] -
  y[#13] --< P(p) >--> y.p[#14]
  y.p[#14] -
  exports[#15] --< P(foo) >--> foo[#10]
  exports[#15] --< V(foo) >--> exports[#19]
  $v2[#16] --< V(q) >--> $v2[#18]
  $v3[#17] -
  $v2[#18] --< P(q) >--> $v3[#17]
  exports[#19] --< P(foo) >--> $v2[#18]
