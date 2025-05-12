  $ graphjs mdg --no-export exports.js
  module[#7] --< P(exports) >--> exports[#8]
  exports[#8] --< V(foo) >--> exports[#12]
  $v1[#9] --< Param(0) >--> this[#10]
  $v1[#9] --< Param(1) >--> x1[#11]
  this[#10] -
  x1[#11] -
  exports[#12] --< P(foo) >--> $v1[#9]
  exports[#12] --< V(bar) >--> exports[#18]
  $v2[#13] --< Param(0) >--> this[#14]
  $v2[#13] --< Param(1) >--> x2[#15]
  $v2[#13] --< Param(2) >--> y2[#16]
  $v2[#13] --< Param(3) >--> z2[#17]
  this[#14] -
  x2[#15] -
  y2[#16] -
  z2[#17] -
  exports[#18] --< P(bar) >--> $v2[#13]
  exports[#19] --< V(baz) >--> exports[#23]
  $v3[#20] --< Param(0) >--> this[#21]
  $v3[#20] --< Param(1) >--> x3[#22]
  this[#21] -
  x3[#22] -
  exports[#23] --< P(baz) >--> $v3[#20]
  [[taint]] --< D >--> exports[#8]
  [[taint]] --< D >--> $v1[#9]
  [[taint]] --< D >--> $v2[#13]

  $ graphjs mdg --no-export module.js
  module[#7] --< P(exports) >--> exports[#8]
  module[#7] --< V(exports) >--> module[#20]
  exports[#8] --< V(foo) >--> exports[#12]
  $v1[#9] --< Param(0) >--> this[#10]
  $v1[#9] --< Param(1) >--> x1[#11]
  this[#10] -
  x1[#11] -
  exports[#12] --< P(foo) >--> $v1[#9]
  exports[#12] --< V(bar) >--> exports[#18]
  $v3[#13] --< Param(0) >--> this[#14]
  $v3[#13] --< Param(1) >--> x2[#15]
  $v3[#13] --< Param(2) >--> y2[#16]
  $v3[#13] --< Param(3) >--> z2[#17]
  this[#14] -
  x2[#15] -
  y2[#16] -
  z2[#17] -
  exports[#18] --< P(bar) >--> $v3[#13]
  $v5[#19] --< V(baz) >--> $v5[#24]
  module[#20] --< P(exports) >--> $v5[#19]
  $v6[#21] --< Param(0) >--> this[#22]
  $v6[#21] --< Param(1) >--> x3[#23]
  this[#22] -
  x3[#23] -
  $v5[#24] --< P(baz) >--> $v6[#21]
  [[taint]] --< D >--> $v5[#19]
  [[taint]] --< D >--> $v6[#21]

  $ graphjs mdg --no-export dynamic.js
  module[#7] --< P(exports) >--> exports[#8]
  module[#7] --< P(*) >--> module.*[#18]
  exports[#8] --< V(foo) >--> exports[#12]
  $v1[#9] --< Param(0) >--> this[#10]
  $v1[#9] --< Param(1) >--> x1[#11]
  this[#10] -
  x1[#11] -
  exports[#12] --< P(foo) >--> $v1[#9]
  exports[#12] --< V(bar) >--> $v4[#19]
  $v3[#13] --< Param(0) >--> this[#14]
  $v3[#13] --< Param(1) >--> x2[#15]
  $v3[#13] --< Param(2) >--> y2[#16]
  $v3[#13] --< Param(3) >--> z2[#17]
  this[#14] -
  x2[#15] -
  y2[#16] -
  z2[#17] -
  module.*[#18] --< V(bar) >--> $v4[#19]
  $v4[#19] --< P(bar) >--> $v3[#13]
  $v4[#19] --< V(*) >--> $v4[#23]
  $v5[#20] --< Param(0) >--> this[#21]
  $v5[#20] --< Param(1) >--> x3[#22]
  this[#21] -
  x3[#22] -
  $v4[#23] --< P(*) >--> $v5[#20]
  [[taint]] --< D >--> exports[#8]
  [[taint]] --< D >--> $v1[#9]
  [[taint]] --< D >--> $v3[#13]
  [[taint]] --< D >--> module.*[#18]
  [[taint]] --< D >--> $v5[#20]

  $ graphjs mdg --no-export mixed.js
  module[#7] --< P(exports) >--> exports[#8]
  exports[#8] --< V(foo) >--> exports[#12]
  $v1[#9] --< Param(0) >--> this[#10]
  $v1[#9] --< Param(1) >--> x1[#11]
  this[#10] -
  x1[#11] -
  exports[#12] --< P(foo) >--> $v1[#9]
  exports[#12] --< V(bar) >--> exports[#18]
  $v2[#13] --< Param(0) >--> this[#14]
  $v2[#13] --< Param(1) >--> x2[#15]
  $v2[#13] --< Param(2) >--> y2[#16]
  $v2[#13] --< Param(3) >--> z2[#17]
  this[#14] -
  x2[#15] -
  y2[#16] -
  z2[#17] -
  exports[#18] --< P(bar) >--> $v2[#13]
  [[taint]] --< D >--> exports[#8]
  [[taint]] --< D >--> $v1[#9]
  [[taint]] --< D >--> $v2[#13]
