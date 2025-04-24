  $ graphjs mdg --no-export exports.js
  exports[l_1] --< V(foo) >--> exports[l_2]
  $v1[f_1] --< Param(0) >--> this[p_0]
  $v1[f_1] --< Param(1) >--> x1[p_1]
  this[p_0] -
  x1[p_1] -
  exports[l_2] --< P(foo) >--> $v1[f_1]
  exports[l_2] --< V(bar) >--> exports[l_3]
  $v2[f_2] --< Param(0) >--> this[p_0]
  $v2[f_2] --< Param(1) >--> x2[p_1]
  $v2[f_2] --< Param(2) >--> y2[p_2]
  $v2[f_2] --< Param(3) >--> z2[p_3]
  this[p_0] -
  x2[p_1] -
  y2[p_2] -
  z2[p_3] -
  exports[l_3] --< P(bar) >--> $v2[f_2]
  exports[l_4] --< V(baz) >--> exports[l_5]
  $v3[f_3] --< Param(0) >--> this[p_0]
  $v3[f_3] --< Param(1) >--> x3[p_1]
  this[p_0] -
  x3[p_1] -
  exports[l_5] --< P(baz) >--> $v3[f_3]
  [[taint]] --< D >--> exports[l_1]
  [[taint]] --< D >--> $v1[f_1]
  [[taint]] --< D >--> this[p_0]
  [[taint]] --< D >--> x1[p_1]
  [[taint]] --< D >--> $v2[f_2]
  [[taint]] --< D >--> this[p_0]
  [[taint]] --< D >--> x2[p_1]
  [[taint]] --< D >--> y2[p_2]
  [[taint]] --< D >--> z2[p_3]

  $ graphjs mdg --no-export module.js
  module[l_1] --< P(exports) >--> exports[l_3]
  module[l_1] --< V(exports) >--> module[l_7]
  exports[l_3] --< V(foo) >--> exports[l_4]
  $v1[f_1] --< Param(0) >--> this[p_0]
  $v1[f_1] --< Param(1) >--> x1[p_1]
  this[p_0] -
  x1[p_1] -
  exports[l_4] --< P(foo) >--> $v1[f_1]
  exports[l_4] --< V(bar) >--> exports[l_5]
  $v3[f_2] --< Param(0) >--> this[p_0]
  $v3[f_2] --< Param(1) >--> x2[p_1]
  $v3[f_2] --< Param(2) >--> y2[p_2]
  $v3[f_2] --< Param(3) >--> z2[p_3]
  this[p_0] -
  x2[p_1] -
  y2[p_2] -
  z2[p_3] -
  exports[l_5] --< P(bar) >--> $v3[f_2]
  $v5[l_6] --< V(baz) >--> $v5[l_8]
  module[l_7] --< P(exports) >--> $v5[l_6]
  $v6[f_3] --< Param(0) >--> this[p_0]
  $v6[f_3] --< Param(1) >--> x3[p_1]
  this[p_0] -
  x3[p_1] -
  $v5[l_8] --< P(baz) >--> $v6[f_3]
  [[taint]] --< D >--> $v5[l_6]
  [[taint]] --< D >--> $v6[f_3]
  [[taint]] --< D >--> this[p_0]
  [[taint]] --< D >--> x3[p_1]

  $ graphjs mdg --no-export dynamic.js
  module[l_1] --< P(exports) >--> exports[l_3]
  module[l_1] --< P(*) >--> module.*[l_5]
  exports[l_3] --< V(foo) >--> exports[l_4]
  $v1[f_1] --< Param(0) >--> this[p_0]
  $v1[f_1] --< Param(1) >--> x1[p_1]
  this[p_0] -
  x1[p_1] -
  exports[l_4] --< P(foo) >--> $v1[f_1]
  exports[l_4] --< V(bar) >--> $v4[l_6]
  $v3[f_2] --< Param(0) >--> this[p_0]
  $v3[f_2] --< Param(1) >--> x2[p_1]
  $v3[f_2] --< Param(2) >--> y2[p_2]
  $v3[f_2] --< Param(3) >--> z2[p_3]
  this[p_0] -
  x2[p_1] -
  y2[p_2] -
  z2[p_3] -
  module.*[l_5] --< V(bar) >--> $v4[l_6]
  $v4[l_6] --< P(bar) >--> $v3[f_2]
  $v4[l_6] --< V(*) >--> $v6[l_7]
  $v5[f_3] --< Param(0) >--> this[p_0]
  $v5[f_3] --< Param(1) >--> x3[p_1]
  this[p_0] -
  x3[p_1] -
  $v6[l_7] --< P(*) >--> $v5[f_3]
  [[taint]] --< D >--> exports[l_3]
  [[taint]] --< D >--> $v1[f_1]
  [[taint]] --< D >--> this[p_0]
  [[taint]] --< D >--> x1[p_1]
  [[taint]] --< D >--> $v3[f_2]
  [[taint]] --< D >--> this[p_0]
  [[taint]] --< D >--> x2[p_1]
  [[taint]] --< D >--> y2[p_2]
  [[taint]] --< D >--> z2[p_3]
  [[taint]] --< D >--> module.*[l_5]
  [[taint]] --< D >--> $v5[f_3]
  [[taint]] --< D >--> this[p_0]
  [[taint]] --< D >--> x3[p_1]

  $ graphjs mdg --no-export mixed.js
  module[l_3] --< P(exports) >--> exports[l_1]
  exports[l_1] --< V(foo) >--> exports[l_2]
  $v1[f_1] --< Param(0) >--> this[p_0]
  $v1[f_1] --< Param(1) >--> x1[p_1]
  this[p_0] -
  x1[p_1] -
  exports[l_2] --< P(foo) >--> $v1[f_1]
  exports[l_2] --< V(bar) >--> exports[l_5]
  $v2[f_2] --< Param(0) >--> this[p_0]
  $v2[f_2] --< Param(1) >--> x2[p_1]
  $v2[f_2] --< Param(2) >--> y2[p_2]
  $v2[f_2] --< Param(3) >--> z2[p_3]
  this[p_0] -
  x2[p_1] -
  y2[p_2] -
  z2[p_3] -
  exports[l_5] --< P(bar) >--> $v2[f_2]
  [[taint]] --< D >--> exports[l_1]
  [[taint]] --< D >--> $v1[f_1]
  [[taint]] --< D >--> this[p_0]
  [[taint]] --< D >--> x1[p_1]
  [[taint]] --< D >--> $v2[f_2]
  [[taint]] --< D >--> this[p_0]
  [[taint]] --< D >--> x2[p_1]
  [[taint]] --< D >--> y2[p_2]
  [[taint]] --< D >--> z2[p_3]
