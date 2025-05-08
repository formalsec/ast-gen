  $ graphjs mdg --no-export exports.js
  module[#8] --< P(exports) >--> exports[#9]
  exports[#9] --< V(foo) >--> exports[#13]
  $v1[#10] --< Param(0) >--> this[#11]
  $v1[#10] --< Param(1) >--> x1[#12]
  this[#11] -
  x1[#12] -
  exports[#13] --< P(foo) >--> $v1[#10]
  exports[#13] --< V(bar) >--> exports[#19]
  $v2[#14] --< Param(0) >--> this[#15]
  $v2[#14] --< Param(1) >--> x2[#16]
  $v2[#14] --< Param(2) >--> y2[#17]
  $v2[#14] --< Param(3) >--> z2[#18]
  this[#15] -
  x2[#16] -
  y2[#17] -
  z2[#18] -
  exports[#19] --< P(bar) >--> $v2[#14]
  exports[#20] --< V(baz) >--> exports[#24]
  $v3[#21] --< Param(0) >--> this[#22]
  $v3[#21] --< Param(1) >--> x3[#23]
  this[#22] -
  x3[#23] -
  exports[#24] --< P(baz) >--> $v3[#21]
  [[taint]] --< D >--> exports[#9]
  [[taint]] --< D >--> $v1[#10]
  [[taint]] --< D >--> $v2[#14]

  $ graphjs mdg --no-export module.js
  module[#8] --< P(exports) >--> exports[#9]
  module[#8] --< V(exports) >--> module[#21]
  exports[#9] --< V(foo) >--> exports[#13]
  $v1[#10] --< Param(0) >--> this[#11]
  $v1[#10] --< Param(1) >--> x1[#12]
  this[#11] -
  x1[#12] -
  exports[#13] --< P(foo) >--> $v1[#10]
  exports[#13] --< V(bar) >--> exports[#19]
  $v3[#14] --< Param(0) >--> this[#15]
  $v3[#14] --< Param(1) >--> x2[#16]
  $v3[#14] --< Param(2) >--> y2[#17]
  $v3[#14] --< Param(3) >--> z2[#18]
  this[#15] -
  x2[#16] -
  y2[#17] -
  z2[#18] -
  exports[#19] --< P(bar) >--> $v3[#14]
  $v5[#20] --< V(baz) >--> $v5[#25]
  module[#21] --< P(exports) >--> $v5[#20]
  $v6[#22] --< Param(0) >--> this[#23]
  $v6[#22] --< Param(1) >--> x3[#24]
  this[#23] -
  x3[#24] -
  $v5[#25] --< P(baz) >--> $v6[#22]
  [[taint]] --< D >--> $v5[#20]
  [[taint]] --< D >--> $v6[#22]

  $ graphjs mdg --no-export dynamic.js
  module[#8] --< P(exports) >--> exports[#9]
  module[#8] --< P(*) >--> module.*[#19]
  exports[#9] --< V(foo) >--> exports[#13]
  $v1[#10] --< Param(0) >--> this[#11]
  $v1[#10] --< Param(1) >--> x1[#12]
  this[#11] -
  x1[#12] -
  exports[#13] --< P(foo) >--> $v1[#10]
  exports[#13] --< V(bar) >--> $v4[#20]
  $v3[#14] --< Param(0) >--> this[#15]
  $v3[#14] --< Param(1) >--> x2[#16]
  $v3[#14] --< Param(2) >--> y2[#17]
  $v3[#14] --< Param(3) >--> z2[#18]
  this[#15] -
  x2[#16] -
  y2[#17] -
  z2[#18] -
  module.*[#19] --< V(bar) >--> $v4[#20]
  $v4[#20] --< P(bar) >--> $v3[#14]
  $v4[#20] --< V(*) >--> $v4[#24]
  $v5[#21] --< Param(0) >--> this[#22]
  $v5[#21] --< Param(1) >--> x3[#23]
  this[#22] -
  x3[#23] -
  $v4[#24] --< P(*) >--> $v5[#21]
  [[taint]] --< D >--> exports[#9]
  [[taint]] --< D >--> $v1[#10]
  [[taint]] --< D >--> $v3[#14]
  [[taint]] --< D >--> module.*[#19]
  [[taint]] --< D >--> $v5[#21]

  $ graphjs mdg --no-export mixed.js
  module[#8] --< P(exports) >--> exports[#9]
  exports[#9] --< V(foo) >--> exports[#13]
  $v1[#10] --< Param(0) >--> this[#11]
  $v1[#10] --< Param(1) >--> x1[#12]
  this[#11] -
  x1[#12] -
  exports[#13] --< P(foo) >--> $v1[#10]
  exports[#13] --< V(bar) >--> exports[#19]
  $v2[#14] --< Param(0) >--> this[#15]
  $v2[#14] --< Param(1) >--> x2[#16]
  $v2[#14] --< Param(2) >--> y2[#17]
  $v2[#14] --< Param(3) >--> z2[#18]
  this[#15] -
  x2[#16] -
  y2[#17] -
  z2[#18] -
  exports[#19] --< P(bar) >--> $v2[#14]
  [[taint]] --< D >--> exports[#9]
  [[taint]] --< D >--> $v1[#10]
  [[taint]] --< D >--> $v2[#14]
