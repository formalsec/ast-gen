Graph.js MDG Builder: tainted analysis flag
  $ graphjs mdg --no-export no_tainted_sources.js
  [[function]] defineProperty[#5] -
  module[#15] --< P(exports) >--> exports[#16]
  exports[#16] --< V(foo) >--> exports[#22]
  [[function]] foo[#17] --< Param(0) >--> this[#18]
  [[function]] foo[#17] --< Param(1) >--> x[#19]
  [[function]] foo[#17] --< Param(2) >--> y[#20]
  this[#18] -
  x[#19] -
  y[#20] --< P(p) >--> y.p[#21]
  y.p[#21] -
  exports[#22] --< P(foo) >--> [[function]] foo[#17]
  exports[#22] --< V(foo) >--> exports[#26]
  $v2[#23] --< V(q) >--> $v2[#25]
  $v3[#24] -
  $v2[#25] --< P(q) >--> $v3[#24]
  exports[#26] --< P(foo) >--> $v2[#25]

  $ graphjs mdg --no-export no_tainted_sources.js --no-tainted-analysis
  [[function]] defineProperty[#5] -
  module[#15] --< P(exports) >--> exports[#16]
  exports[#16] --< V(foo) >--> exports[#22]
  [[function]] foo[#17] --< Param(0) >--> this[#18]
  [[function]] foo[#17] --< Param(1) >--> x[#19]
  [[function]] foo[#17] --< Param(2) >--> y[#20]
  this[#18] -
  x[#19] -
  y[#20] --< P(p) >--> y.p[#21]
  y.p[#21] -
  exports[#22] --< P(foo) >--> [[function]] foo[#17]
  exports[#22] --< V(foo) >--> exports[#26]
  $v2[#23] --< V(q) >--> $v2[#25]
  $v3[#24] -
  $v2[#25] --< P(q) >--> $v3[#24]
  exports[#26] --< P(foo) >--> $v2[#25]
