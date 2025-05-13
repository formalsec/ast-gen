Graph.js MDG Builder: simple exports
  $ graphjs mdg --no-export exports.js
  module[#7] --< P(exports) >--> exports[#8]
  exports[#8] --< V(foo) >--> exports[#12]
  [[function]] $v1[#9] --< Param(0) >--> this[#10]
  [[function]] $v1[#9] --< Param(1) >--> x1[#11]
  this[#10] -
  x1[#11] -
  exports[#12] --< P(foo) >--> [[function]] $v1[#9]
  exports[#12] --< V(bar) >--> exports[#18]
  [[function]] $v2[#13] --< Param(0) >--> this[#14]
  [[function]] $v2[#13] --< Param(1) >--> x2[#15]
  [[function]] $v2[#13] --< Param(2) >--> y2[#16]
  [[function]] $v2[#13] --< Param(3) >--> z2[#17]
  this[#14] -
  x2[#15] -
  y2[#16] -
  z2[#17] -
  exports[#18] --< P(bar) >--> [[function]] $v2[#13]
  exports[#19] --< V(baz) >--> exports[#23]
  [[function]] $v3[#20] --< Param(0) >--> this[#21]
  [[function]] $v3[#20] --< Param(1) >--> x3[#22]
  this[#21] -
  x3[#22] -
  exports[#23] --< P(baz) >--> [[function]] $v3[#20]
  [[taint]] --< D >--> exports[#8]
  [[taint]] --< D >--> [[function]] $v1[#9]
  [[taint]] --< D >--> [[function]] $v2[#13]

Graph.js MDG Builder: module exports
  $ graphjs mdg --no-export module.js
  module[#7] --< P(exports) >--> exports[#8]
  module[#7] --< V(exports) >--> module[#20]
  exports[#8] --< V(foo) >--> exports[#12]
  [[function]] $v1[#9] --< Param(0) >--> this[#10]
  [[function]] $v1[#9] --< Param(1) >--> x1[#11]
  this[#10] -
  x1[#11] -
  exports[#12] --< P(foo) >--> [[function]] $v1[#9]
  exports[#12] --< V(bar) >--> exports[#18]
  [[function]] $v3[#13] --< Param(0) >--> this[#14]
  [[function]] $v3[#13] --< Param(1) >--> x2[#15]
  [[function]] $v3[#13] --< Param(2) >--> y2[#16]
  [[function]] $v3[#13] --< Param(3) >--> z2[#17]
  this[#14] -
  x2[#15] -
  y2[#16] -
  z2[#17] -
  exports[#18] --< P(bar) >--> [[function]] $v3[#13]
  $v5[#19] --< V(baz) >--> $v5[#24]
  module[#20] --< P(exports) >--> $v5[#19]
  [[function]] $v6[#21] --< Param(0) >--> this[#22]
  [[function]] $v6[#21] --< Param(1) >--> x3[#23]
  this[#22] -
  x3[#23] -
  $v5[#24] --< P(baz) >--> [[function]] $v6[#21]
  [[taint]] --< D >--> $v5[#19]
  [[taint]] --< D >--> [[function]] $v6[#21]

Graph.js MDG Builder: dynamic exports
  $ graphjs mdg --no-export dynamic.js
  module[#7] --< P(exports) >--> exports[#8]
  module[#7] --< P(*) >--> module.*[#19]
  exports[#8] --< V(foo) >--> exports[#12]
  [[function]] $v1[#9] --< Param(0) >--> this[#10]
  [[function]] $v1[#9] --< Param(1) >--> x1[#11]
  this[#10] -
  x1[#11] -
  exports[#12] --< P(foo) >--> [[function]] $v1[#9]
  exports[#12] --< V(bar) >--> $v4[#20]
  [[function]] $v3[#13] --< Param(0) >--> this[#14]
  [[function]] $v3[#13] --< Param(1) >--> x2[#15]
  [[function]] $v3[#13] --< Param(2) >--> y2[#16]
  [[function]] $v3[#13] --< Param(3) >--> z2[#17]
  this[#14] -
  x2[#15] -
  y2[#16] -
  z2[#17] -
  export_prop[#18] --< D >--> module.*[#19]
  module.*[#19] --< V(bar) >--> $v4[#20]
  $v4[#20] --< P(bar) >--> [[function]] $v3[#13]
  $v4[#20] --< V(*) >--> $v4[#26]
  [[function]] $v5[#21] --< Param(0) >--> this[#22]
  [[function]] $v5[#21] --< Param(1) >--> x3[#23]
  this[#22] -
  x3[#23] -
  export_prop[#24] --< D >--> module.*[#19]
  baz[#25] --< D >--> $v4[#26]
  $v4[#26] --< P(*) >--> [[function]] $v5[#21]
  [[taint]] --< D >--> exports[#8]
  [[taint]] --< D >--> [[function]] $v1[#9]
  [[taint]] --< D >--> [[function]] $v3[#13]
  [[taint]] --< D >--> module.*[#19]
  [[taint]] --< D >--> [[function]] $v5[#21]

Graph.js MDG Builder: mixed exports
  $ graphjs mdg --no-export mixed.js
  module[#7] --< P(exports) >--> exports[#8]
  exports[#8] --< V(foo) >--> exports[#12]
  [[function]] $v1[#9] --< Param(0) >--> this[#10]
  [[function]] $v1[#9] --< Param(1) >--> x1[#11]
  this[#10] -
  x1[#11] -
  exports[#12] --< P(foo) >--> [[function]] $v1[#9]
  exports[#12] --< V(bar) >--> exports[#18]
  [[function]] $v2[#13] --< Param(0) >--> this[#14]
  [[function]] $v2[#13] --< Param(1) >--> x2[#15]
  [[function]] $v2[#13] --< Param(2) >--> y2[#16]
  [[function]] $v2[#13] --< Param(3) >--> z2[#17]
  this[#14] -
  x2[#15] -
  y2[#16] -
  z2[#17] -
  exports[#18] --< P(bar) >--> [[function]] $v2[#13]
  [[taint]] --< D >--> exports[#8]
  [[taint]] --< D >--> [[function]] $v1[#9]
  [[taint]] --< D >--> [[function]] $v2[#13]
