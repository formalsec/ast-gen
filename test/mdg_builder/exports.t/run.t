Graph.js MDG Builder: simple exports
  $ graphjs mdg --no-export exports.js
  module[#5] --< P(exports) >--> exports[#6]
  exports[#6] --< V(foo) >--> exports[#10]
  [[function]] $v1[#7] --< Param(0) >--> this[#8]
  [[function]] $v1[#7] --< Param(1) >--> x1[#9]
  this[#8] -
  x1[#9] -
  exports[#10] --< P(foo) >--> [[function]] $v1[#7]
  exports[#10] --< V(bar) >--> exports[#16]
  [[function]] $v2[#11] --< Param(0) >--> this[#12]
  [[function]] $v2[#11] --< Param(1) >--> x2[#13]
  [[function]] $v2[#11] --< Param(2) >--> y2[#14]
  [[function]] $v2[#11] --< Param(3) >--> z2[#15]
  this[#12] -
  x2[#13] -
  y2[#14] -
  z2[#15] -
  exports[#16] --< P(bar) >--> [[function]] $v2[#11]
  exports[#17] --< V(baz) >--> exports[#21]
  [[function]] $v3[#18] --< Param(0) >--> this[#19]
  [[function]] $v3[#18] --< Param(1) >--> x3[#20]
  this[#19] -
  x3[#20] -
  exports[#21] --< P(baz) >--> [[function]] $v3[#18]

Graph.js MDG Builder: module exports
  $ graphjs mdg --no-export module.js
  module[#5] --< P(exports) >--> exports[#6]
  module[#5] --< V(exports) >--> module[#18]
  exports[#6] --< V(foo) >--> exports[#10]
  [[function]] $v1[#7] --< Param(0) >--> this[#8]
  [[function]] $v1[#7] --< Param(1) >--> x1[#9]
  this[#8] -
  x1[#9] -
  exports[#10] --< P(foo) >--> [[function]] $v1[#7]
  exports[#10] --< V(bar) >--> exports[#16]
  [[function]] $v3[#11] --< Param(0) >--> this[#12]
  [[function]] $v3[#11] --< Param(1) >--> x2[#13]
  [[function]] $v3[#11] --< Param(2) >--> y2[#14]
  [[function]] $v3[#11] --< Param(3) >--> z2[#15]
  this[#12] -
  x2[#13] -
  y2[#14] -
  z2[#15] -
  exports[#16] --< P(bar) >--> [[function]] $v3[#11]
  $v5[#17] --< V(baz) >--> $v5[#22]
  module[#18] --< P(exports) >--> $v5[#17]
  [[function]] $v6[#19] --< Param(0) >--> this[#20]
  [[function]] $v6[#19] --< Param(1) >--> x3[#21]
  this[#20] -
  x3[#21] -
  $v5[#22] --< P(baz) >--> [[function]] $v6[#19]

Graph.js MDG Builder: dynamic exports
  $ graphjs mdg --no-export dynamic.js
  module[#5] --< P(exports) >--> exports[#6]
  module[#5] --< P(*) >--> module.*[#17]
  exports[#6] --< V(foo) >--> exports[#10]
  [[function]] $v1[#7] --< Param(0) >--> this[#8]
  [[function]] $v1[#7] --< Param(1) >--> x1[#9]
  this[#8] -
  x1[#9] -
  exports[#10] --< P(foo) >--> [[function]] $v1[#7]
  exports[#10] --< V(bar) >--> $v4[#18]
  [[function]] $v3[#11] --< Param(0) >--> this[#12]
  [[function]] $v3[#11] --< Param(1) >--> x2[#13]
  [[function]] $v3[#11] --< Param(2) >--> y2[#14]
  [[function]] $v3[#11] --< Param(3) >--> z2[#15]
  this[#12] -
  x2[#13] -
  y2[#14] -
  z2[#15] -
  export_prop[#16] --< D >--> module.*[#17]
  module.*[#17] --< V(bar) >--> $v4[#18]
  $v4[#18] --< P(bar) >--> [[function]] $v3[#11]
  $v4[#18] --< V(*) >--> $v4[#24]
  [[function]] $v5[#19] --< Param(0) >--> this[#20]
  [[function]] $v5[#19] --< Param(1) >--> x3[#21]
  this[#20] -
  x3[#21] -
  export_prop[#22] --< D >--> module.*[#17]
  baz[#23] --< D >--> $v4[#24]
  $v4[#24] --< P(*) >--> [[function]] $v5[#19]

Graph.js MDG Builder: mixed exports
  $ graphjs mdg --no-export mixed.js
  module[#5] --< P(exports) >--> exports[#6]
  exports[#6] --< V(foo) >--> exports[#10]
  [[function]] $v1[#7] --< Param(0) >--> this[#8]
  [[function]] $v1[#7] --< Param(1) >--> x1[#9]
  this[#8] -
  x1[#9] -
  exports[#10] --< P(foo) >--> [[function]] $v1[#7]
  exports[#10] --< V(bar) >--> exports[#16]
  [[function]] $v2[#11] --< Param(0) >--> this[#12]
  [[function]] $v2[#11] --< Param(1) >--> x2[#13]
  [[function]] $v2[#11] --< Param(2) >--> y2[#14]
  [[function]] $v2[#11] --< Param(3) >--> z2[#15]
  this[#12] -
  x2[#13] -
  y2[#14] -
  z2[#15] -
  exports[#16] --< P(bar) >--> [[function]] $v2[#11]
