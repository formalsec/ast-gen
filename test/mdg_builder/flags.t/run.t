Graph.js MDG Builder: tainted analysis flag
  $ graphjs mdg --no-export no_tainted_sources.js
  module[#8] --< P(exports) >--> exports[#9]
  exports[#9] --< V(foo) >--> exports[#15]
  [[function]] foo[#10] --< Param(0) >--> this[#11]
  [[function]] foo[#10] --< Param(1) >--> x[#12]
  [[function]] foo[#10] --< Param(2) >--> y[#13]
  this[#11] -
  x[#12] -
  y[#13] --< P(p) >--> y.p[#14]
  y.p[#14] -
  exports[#15] --< P(foo) >--> [[function]] foo[#10]
  exports[#15] --< V(foo) >--> exports[#19]
  $v2[#16] --< V(q) >--> $v2[#18]
  $v3[#17] -
  $v2[#18] --< P(q) >--> $v3[#17]
  exports[#19] --< P(foo) >--> $v2[#18]

  $ graphjs mdg --no-export no_tainted_sources.js --no-tainted-analysis
  module[#8] --< P(exports) >--> exports[#9]
  exports[#9] --< V(foo) >--> exports[#15]
  [[function]] foo[#10] --< Param(0) >--> this[#11]
  [[function]] foo[#10] --< Param(1) >--> x[#12]
  [[function]] foo[#10] --< Param(2) >--> y[#13]
  this[#11] -
  x[#12] -
  y[#13] --< P(p) >--> y.p[#14]
  y.p[#14] -
  exports[#15] --< P(foo) >--> [[function]] foo[#10]
  exports[#15] --< V(foo) >--> exports[#19]
  $v2[#16] --< V(q) >--> $v2[#18]
  $v3[#17] -
  $v2[#18] --< P(q) >--> $v3[#17]
  exports[#19] --< P(foo) >--> $v2[#18]
