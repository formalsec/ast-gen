  $ graphjs mdg --no-export exports.js
  module[#9] --< P(exports) >--> exports[#10]
  exports[#10] --< V(foo) >--> exports[#14]
  $v1[#11] --< Param(0) >--> this[#12]
  $v1[#11] --< Param(1) >--> x1[#13]
  this[#12] -
  x1[#13] -
  exports[#14] --< P(foo) >--> $v1[#11]
  exports[#14] --< V(bar) >--> exports[#20]
  $v2[#15] --< Param(0) >--> this[#16]
  $v2[#15] --< Param(1) >--> x2[#17]
  $v2[#15] --< Param(2) >--> y2[#18]
  $v2[#15] --< Param(3) >--> z2[#19]
  this[#16] -
  x2[#17] -
  y2[#18] -
  z2[#19] -
  exports[#20] --< P(bar) >--> $v2[#15]
  exports[#21] --< V(baz) >--> exports[#25]
  $v3[#22] --< Param(0) >--> this[#23]
  $v3[#22] --< Param(1) >--> x3[#24]
  this[#23] -
  x3[#24] -
  exports[#25] --< P(baz) >--> $v3[#22]
  [[taint]] --< D >--> exports[#10]
  [[taint]] --< D >--> $v1[#11]
  [[taint]] --< D >--> this[#12]
  [[taint]] --< D >--> x1[#13]
  [[taint]] --< D >--> $v2[#15]
  [[taint]] --< D >--> this[#16]
  [[taint]] --< D >--> x2[#17]
  [[taint]] --< D >--> y2[#18]
  [[taint]] --< D >--> z2[#19]

  $ graphjs mdg --no-export module.js
  module[#9] --< P(exports) >--> exports[#10]
  module[#9] --< V(exports) >--> module[#22]
  exports[#10] --< V(foo) >--> exports[#14]
  $v1[#11] --< Param(0) >--> this[#12]
  $v1[#11] --< Param(1) >--> x1[#13]
  this[#12] -
  x1[#13] -
  exports[#14] --< P(foo) >--> $v1[#11]
  exports[#14] --< V(bar) >--> exports[#20]
  $v3[#15] --< Param(0) >--> this[#16]
  $v3[#15] --< Param(1) >--> x2[#17]
  $v3[#15] --< Param(2) >--> y2[#18]
  $v3[#15] --< Param(3) >--> z2[#19]
  this[#16] -
  x2[#17] -
  y2[#18] -
  z2[#19] -
  exports[#20] --< P(bar) >--> $v3[#15]
  $v5[#21] --< V(baz) >--> $v5[#26]
  module[#22] --< P(exports) >--> $v5[#21]
  $v6[#23] --< Param(0) >--> this[#24]
  $v6[#23] --< Param(1) >--> x3[#25]
  this[#24] -
  x3[#25] -
  $v5[#26] --< P(baz) >--> $v6[#23]
  [[taint]] --< D >--> $v5[#21]
  [[taint]] --< D >--> $v6[#23]
  [[taint]] --< D >--> this[#24]
  [[taint]] --< D >--> x3[#25]

  $ graphjs mdg --no-export dynamic.js
  module[#9] --< P(exports) >--> exports[#10]
  module[#9] --< P(*) >--> module.*[#20]
  exports[#10] --< V(foo) >--> exports[#14]
  $v1[#11] --< Param(0) >--> this[#12]
  $v1[#11] --< Param(1) >--> x1[#13]
  this[#12] -
  x1[#13] -
  exports[#14] --< P(foo) >--> $v1[#11]
  exports[#14] --< V(bar) >--> $v4[#21]
  $v3[#15] --< Param(0) >--> this[#16]
  $v3[#15] --< Param(1) >--> x2[#17]
  $v3[#15] --< Param(2) >--> y2[#18]
  $v3[#15] --< Param(3) >--> z2[#19]
  this[#16] -
  x2[#17] -
  y2[#18] -
  z2[#19] -
  module.*[#20] --< V(bar) >--> $v4[#21]
  $v4[#21] --< P(bar) >--> $v3[#15]
  $v4[#21] --< V(*) >--> $v6[#25]
  $v5[#22] --< Param(0) >--> this[#23]
  $v5[#22] --< Param(1) >--> x3[#24]
  this[#23] -
  x3[#24] -
  $v6[#25] --< P(*) >--> $v5[#22]
  [[taint]] --< D >--> exports[#10]
  [[taint]] --< D >--> $v1[#11]
  [[taint]] --< D >--> this[#12]
  [[taint]] --< D >--> x1[#13]
  [[taint]] --< D >--> $v3[#15]
  [[taint]] --< D >--> this[#16]
  [[taint]] --< D >--> x2[#17]
  [[taint]] --< D >--> y2[#18]
  [[taint]] --< D >--> z2[#19]
  [[taint]] --< D >--> module.*[#20]
  [[taint]] --< D >--> $v5[#22]
  [[taint]] --< D >--> this[#23]
  [[taint]] --< D >--> x3[#24]

  $ graphjs mdg --no-export mixed.js
  module[#9] --< P(exports) >--> exports[#10]
  exports[#10] --< V(foo) >--> exports[#14]
  $v1[#11] --< Param(0) >--> this[#12]
  $v1[#11] --< Param(1) >--> x1[#13]
  this[#12] -
  x1[#13] -
  exports[#14] --< P(foo) >--> $v1[#11]
  exports[#14] --< V(bar) >--> exports[#20]
  $v2[#15] --< Param(0) >--> this[#16]
  $v2[#15] --< Param(1) >--> x2[#17]
  $v2[#15] --< Param(2) >--> y2[#18]
  $v2[#15] --< Param(3) >--> z2[#19]
  this[#16] -
  x2[#17] -
  y2[#18] -
  z2[#19] -
  exports[#20] --< P(bar) >--> $v2[#15]
  [[taint]] --< D >--> exports[#10]
  [[taint]] --< D >--> $v1[#11]
  [[taint]] --< D >--> this[#12]
  [[taint]] --< D >--> x1[#13]
  [[taint]] --< D >--> $v2[#15]
  [[taint]] --< D >--> this[#16]
  [[taint]] --< D >--> x2[#17]
  [[taint]] --< D >--> y2[#18]
  [[taint]] --< D >--> z2[#19]
