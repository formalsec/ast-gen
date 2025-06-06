Graph.js MDG Builder: tainted analysis flag
  $ graphjs mdg --no-export no_tainted_sources.js
  module[#5] --< P(exports) >--> exports[#6]
  exports[#6] --< V(foo) >--> exports[#12]
  [[function]] foo[#7] --< Param(0) >--> this[#8]
  [[function]] foo[#7] --< Param(1) >--> x[#9]
  [[function]] foo[#7] --< Param(2) >--> y[#10]
  this[#8] -
  x[#9] -
  y[#10] --< P(p) >--> y.p[#11]
  y.p[#11] -
  exports[#12] --< P(foo) >--> [[function]] foo[#7]
  exports[#12] --< V(foo) >--> exports[#16]
  $v2[#13] --< V(q) >--> $v2[#15]
  $v3[#14] -
  $v2[#15] --< P(q) >--> $v3[#14]
  exports[#16] --< P(foo) >--> $v2[#15]

  $ graphjs mdg --no-export no_tainted_sources.js --no-tainted-analysis
  module[#5] --< P(exports) >--> exports[#6]
  exports[#6] --< V(foo) >--> exports[#12]
  [[function]] foo[#7] --< Param(0) >--> this[#8]
  [[function]] foo[#7] --< Param(1) >--> x[#9]
  [[function]] foo[#7] --< Param(2) >--> y[#10]
  this[#8] -
  x[#9] -
  y[#10] --< P(p) >--> y.p[#11]
  y.p[#11] -
  exports[#12] --< P(foo) >--> [[function]] foo[#7]
  exports[#12] --< V(foo) >--> exports[#16]
  $v2[#13] --< V(q) >--> $v2[#15]
  $v3[#14] -
  $v2[#15] --< P(q) >--> $v3[#14]
  exports[#16] --< P(foo) >--> $v2[#15]
