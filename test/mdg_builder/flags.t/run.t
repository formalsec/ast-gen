Flag for running the tainted analysis, marking exported values as tainted sources
  $ graphjs mdg --no-export no_tainted_sources.js
  module[#7] --< P(exports) >--> exports[#8]
  exports[#8] --< V(foo) >--> exports[#14]
  foo[#9] --< Param(0) >--> this[#10]
  foo[#9] --< Param(1) >--> x[#11]
  foo[#9] --< Param(2) >--> y[#12]
  this[#10] -
  x[#11] -
  y[#12] --< P(p) >--> y.p[#13]
  y.p[#13] -
  exports[#14] --< P(foo) >--> foo[#9]
  exports[#14] --< V(foo) >--> exports[#18]
  $v2[#15] --< V(q) >--> $v2[#17]
  $v3[#16] -
  $v2[#17] --< P(q) >--> $v3[#16]
  exports[#18] --< P(foo) >--> $v2[#17]
  [[taint]] --< D >--> exports[#8]
  [[taint]] --< D >--> $v3[#16]
  [[taint]] --< D >--> $v2[#17]

  $ graphjs mdg --no-export no_tainted_sources.js --no-tainted-analysis
  module[#7] --< P(exports) >--> exports[#8]
  exports[#8] --< V(foo) >--> exports[#14]
  foo[#9] --< Param(0) >--> this[#10]
  foo[#9] --< Param(1) >--> x[#11]
  foo[#9] --< Param(2) >--> y[#12]
  this[#10] -
  x[#11] -
  y[#12] --< P(p) >--> y.p[#13]
  y.p[#13] -
  exports[#14] --< P(foo) >--> foo[#9]
  exports[#14] --< V(foo) >--> exports[#18]
  $v2[#15] --< V(q) >--> $v2[#17]
  $v3[#16] -
  $v2[#17] --< P(q) >--> $v3[#16]
  exports[#18] --< P(foo) >--> $v2[#17]
