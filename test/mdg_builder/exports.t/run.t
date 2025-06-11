Graph.js MDG Builder: simple exports
  $ graphjs mdg --no-export exports.js
  [[function]] defineProperty[#5] -
  module[#15] --< P(exports) >--> exports[#16]
  exports[#16] --< V(foo) >--> exports[#20]
  [[function]] $v1[#17] --< Param(0) >--> this[#18]
  [[function]] $v1[#17] --< Param(1) >--> x1[#19]
  this[#18] -
  x1[#19] -
  exports[#20] --< P(foo) >--> [[function]] $v1[#17]
  exports[#20] --< V(bar) >--> exports[#26]
  [[function]] $v2[#21] --< Param(0) >--> this[#22]
  [[function]] $v2[#21] --< Param(1) >--> x2[#23]
  [[function]] $v2[#21] --< Param(2) >--> y2[#24]
  [[function]] $v2[#21] --< Param(3) >--> z2[#25]
  this[#22] -
  x2[#23] -
  y2[#24] -
  z2[#25] -
  exports[#26] --< P(bar) >--> [[function]] $v2[#21]
  exports[#27] --< V(baz) >--> exports[#31]
  [[function]] $v3[#28] --< Param(0) >--> this[#29]
  [[function]] $v3[#28] --< Param(1) >--> x3[#30]
  this[#29] -
  x3[#30] -
  exports[#31] --< P(baz) >--> [[function]] $v3[#28]

Graph.js MDG Builder: module exports
  $ graphjs mdg --no-export module.js
  [[function]] defineProperty[#5] -
  module[#15] --< P(exports) >--> exports[#16]
  module[#15] --< V(exports) >--> module[#28]
  exports[#16] --< V(foo) >--> exports[#20]
  [[function]] $v1[#17] --< Param(0) >--> this[#18]
  [[function]] $v1[#17] --< Param(1) >--> x1[#19]
  this[#18] -
  x1[#19] -
  exports[#20] --< P(foo) >--> [[function]] $v1[#17]
  exports[#20] --< V(bar) >--> exports[#26]
  [[function]] $v3[#21] --< Param(0) >--> this[#22]
  [[function]] $v3[#21] --< Param(1) >--> x2[#23]
  [[function]] $v3[#21] --< Param(2) >--> y2[#24]
  [[function]] $v3[#21] --< Param(3) >--> z2[#25]
  this[#22] -
  x2[#23] -
  y2[#24] -
  z2[#25] -
  exports[#26] --< P(bar) >--> [[function]] $v3[#21]
  $v5[#27] --< V(baz) >--> $v5[#32]
  module[#28] --< P(exports) >--> $v5[#27]
  [[function]] $v6[#29] --< Param(0) >--> this[#30]
  [[function]] $v6[#29] --< Param(1) >--> x3[#31]
  this[#30] -
  x3[#31] -
  $v5[#32] --< P(baz) >--> [[function]] $v6[#29]

Graph.js MDG Builder: dynamic exports
  $ graphjs mdg --no-export dynamic.js
  [[function]] defineProperty[#5] -
  module[#15] --< P(exports) >--> exports[#16]
  module[#15] --< P(*) >--> module.*[#27]
  exports[#16] --< V(foo) >--> exports[#20]
  [[function]] $v1[#17] --< Param(0) >--> this[#18]
  [[function]] $v1[#17] --< Param(1) >--> x1[#19]
  this[#18] -
  x1[#19] -
  exports[#20] --< P(foo) >--> [[function]] $v1[#17]
  exports[#20] --< V(bar) >--> $v4[#28]
  [[function]] $v3[#21] --< Param(0) >--> this[#22]
  [[function]] $v3[#21] --< Param(1) >--> x2[#23]
  [[function]] $v3[#21] --< Param(2) >--> y2[#24]
  [[function]] $v3[#21] --< Param(3) >--> z2[#25]
  this[#22] -
  x2[#23] -
  y2[#24] -
  z2[#25] -
  export_prop[#26] --< D >--> module.*[#27]
  module.*[#27] --< V(bar) >--> $v4[#28]
  $v4[#28] --< P(bar) >--> [[function]] $v3[#21]
  $v4[#28] --< V(*) >--> $v4[#34]
  [[function]] $v5[#29] --< Param(0) >--> this[#30]
  [[function]] $v5[#29] --< Param(1) >--> x3[#31]
  this[#30] -
  x3[#31] -
  export_prop[#32] --< D >--> module.*[#27]
  baz[#33] --< D >--> $v4[#34]
  $v4[#34] --< P(*) >--> [[function]] $v5[#29]

Graph.js MDG Builder: mixed exports
  $ graphjs mdg --no-export mixed.js
  [[function]] defineProperty[#5] -
  module[#15] --< P(exports) >--> exports[#16]
  exports[#16] --< V(foo) >--> exports[#20]
  [[function]] $v1[#17] --< Param(0) >--> this[#18]
  [[function]] $v1[#17] --< Param(1) >--> x1[#19]
  this[#18] -
  x1[#19] -
  exports[#20] --< P(foo) >--> [[function]] $v1[#17]
  exports[#20] --< V(bar) >--> exports[#26]
  [[function]] $v2[#21] --< Param(0) >--> this[#22]
  [[function]] $v2[#21] --< Param(1) >--> x2[#23]
  [[function]] $v2[#21] --< Param(2) >--> y2[#24]
  [[function]] $v2[#21] --< Param(3) >--> z2[#25]
  this[#22] -
  x2[#23] -
  y2[#24] -
  z2[#25] -
  exports[#26] --< P(bar) >--> [[function]] $v2[#21]
