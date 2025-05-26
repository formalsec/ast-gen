Graph.js MDG Builder: simple exports
  $ graphjs mdg --no-export exports.js
  module[#8] --< P(exports) >--> exports[#9]
  exports[#9] --< V(foo) >--> exports[#13]
  [[function]] $v1[#10] --< Param(0) >--> this[#11]
  [[function]] $v1[#10] --< Param(1) >--> x1[#12]
  this[#11] -
  x1[#12] -
  exports[#13] --< P(foo) >--> [[function]] $v1[#10]
  exports[#13] --< V(bar) >--> exports[#19]
  [[function]] $v2[#14] --< Param(0) >--> this[#15]
  [[function]] $v2[#14] --< Param(1) >--> x2[#16]
  [[function]] $v2[#14] --< Param(2) >--> y2[#17]
  [[function]] $v2[#14] --< Param(3) >--> z2[#18]
  this[#15] -
  x2[#16] -
  y2[#17] -
  z2[#18] -
  exports[#19] --< P(bar) >--> [[function]] $v2[#14]
  exports[#20] --< V(baz) >--> exports[#24]
  [[function]] $v3[#21] --< Param(0) >--> this[#22]
  [[function]] $v3[#21] --< Param(1) >--> x3[#23]
  this[#22] -
  x3[#23] -
  exports[#24] --< P(baz) >--> [[function]] $v3[#21]

Graph.js MDG Builder: module exports
  $ graphjs mdg --no-export module.js
  module[#8] --< P(exports) >--> exports[#9]
  module[#8] --< V(exports) >--> module[#21]
  exports[#9] --< V(foo) >--> exports[#13]
  [[function]] $v1[#10] --< Param(0) >--> this[#11]
  [[function]] $v1[#10] --< Param(1) >--> x1[#12]
  this[#11] -
  x1[#12] -
  exports[#13] --< P(foo) >--> [[function]] $v1[#10]
  exports[#13] --< V(bar) >--> exports[#19]
  [[function]] $v3[#14] --< Param(0) >--> this[#15]
  [[function]] $v3[#14] --< Param(1) >--> x2[#16]
  [[function]] $v3[#14] --< Param(2) >--> y2[#17]
  [[function]] $v3[#14] --< Param(3) >--> z2[#18]
  this[#15] -
  x2[#16] -
  y2[#17] -
  z2[#18] -
  exports[#19] --< P(bar) >--> [[function]] $v3[#14]
  $v5[#20] --< V(baz) >--> $v5[#25]
  module[#21] --< P(exports) >--> $v5[#20]
  [[function]] $v6[#22] --< Param(0) >--> this[#23]
  [[function]] $v6[#22] --< Param(1) >--> x3[#24]
  this[#23] -
  x3[#24] -
  $v5[#25] --< P(baz) >--> [[function]] $v6[#22]

Graph.js MDG Builder: dynamic exports
  $ graphjs mdg --no-export dynamic.js
  module[#8] --< P(exports) >--> exports[#9]
  module[#8] --< P(*) >--> module.*[#20]
  exports[#9] --< V(foo) >--> exports[#13]
  [[function]] $v1[#10] --< Param(0) >--> this[#11]
  [[function]] $v1[#10] --< Param(1) >--> x1[#12]
  this[#11] -
  x1[#12] -
  exports[#13] --< P(foo) >--> [[function]] $v1[#10]
  exports[#13] --< V(bar) >--> $v4[#21]
  [[function]] $v3[#14] --< Param(0) >--> this[#15]
  [[function]] $v3[#14] --< Param(1) >--> x2[#16]
  [[function]] $v3[#14] --< Param(2) >--> y2[#17]
  [[function]] $v3[#14] --< Param(3) >--> z2[#18]
  this[#15] -
  x2[#16] -
  y2[#17] -
  z2[#18] -
  export_prop[#19] --< D >--> module.*[#20]
  module.*[#20] --< V(bar) >--> $v4[#21]
  $v4[#21] --< P(bar) >--> [[function]] $v3[#14]
  $v4[#21] --< V(*) >--> $v4[#27]
  [[function]] $v5[#22] --< Param(0) >--> this[#23]
  [[function]] $v5[#22] --< Param(1) >--> x3[#24]
  this[#23] -
  x3[#24] -
  export_prop[#25] --< D >--> module.*[#20]
  baz[#26] --< D >--> $v4[#27]
  $v4[#27] --< P(*) >--> [[function]] $v5[#22]

Graph.js MDG Builder: mixed exports
  $ graphjs mdg --no-export mixed.js
  module[#8] --< P(exports) >--> exports[#9]
  exports[#9] --< V(foo) >--> exports[#13]
  [[function]] $v1[#10] --< Param(0) >--> this[#11]
  [[function]] $v1[#10] --< Param(1) >--> x1[#12]
  this[#11] -
  x1[#12] -
  exports[#13] --< P(foo) >--> [[function]] $v1[#10]
  exports[#13] --< V(bar) >--> exports[#19]
  [[function]] $v2[#14] --< Param(0) >--> this[#15]
  [[function]] $v2[#14] --< Param(1) >--> x2[#16]
  [[function]] $v2[#14] --< Param(2) >--> y2[#17]
  [[function]] $v2[#14] --< Param(3) >--> z2[#18]
  this[#15] -
  x2[#16] -
  y2[#17] -
  z2[#18] -
  exports[#19] --< P(bar) >--> [[function]] $v2[#14]
