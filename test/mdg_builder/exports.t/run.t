Graph.js MDG Builder: simple exports
  $ graphjs mdg --no-export exports.js
  module[#15] --< P(exports) >--> exports[#16]
  exports[#16] --< V(foo) >--> exports[#18]
  [[function]] $v1[#17] --< Param(1) >--> x1[#25]
  exports[#18] --< P(foo) >--> [[function]] $v1[#17]
  exports[#18] --< V(bar) >--> exports[#20]
  [[function]] $v2[#19] --< Param(1) >--> y1[#29]
  [[function]] $v2[#19] --< Param(2) >--> y2[#30]
  [[function]] $v2[#19] --< Param(3) >--> y3[#31]
  exports[#20] --< P(bar) >--> [[function]] $v2[#19]
  exports[#21] --< V(baz) >--> exports[#23]
  [[function]] $v3[#22] -
  exports[#23] --< P(baz) >--> [[function]] $v3[#22]
  $v1[#24] -
  x1[#25] -
  foo[#26] --< V(x1) >--> foo[#27]
  foo[#27] --< P(x1) >--> x1[#25]
  $v2[#28] -
  y1[#29] -
  y2[#30] -
  y3[#31] -
  bar[#32] --< V(y1) >--> bar[#33]
  bar[#33] --< P(y1) >--> y1[#29]
  bar[#33] --< V(y2) >--> bar[#34]
  bar[#34] --< P(y2) >--> y2[#30]
  bar[#34] --< V(y3) >--> bar[#35]
  bar[#35] --< P(y3) >--> y3[#31]

Graph.js MDG Builder: module exports
  $ graphjs mdg --no-export module.js
  module[#15] --< P(exports) >--> exports[#16]
  module[#15] --< V(exports) >--> module[#20]
  exports[#16] --< V(foo) >--> exports[#18]
  [[function]] $v1[#17] -
  exports[#18] --< P(foo) >--> [[function]] $v1[#17]
  $v3[#19] --< V(bar) >--> $v3[#22]
  module[#20] --< P(exports) >--> $v3[#19]
  [[function]] $v4[#21] --< Param(1) >--> y1[#26]
  $v3[#22] --< P(bar) >--> [[function]] $v4[#21]
  $v3[#22] --< V(baz) >--> $v3[#24]
  [[function]] $v6[#23] --< Param(1) >--> z1[#30]
  [[function]] $v6[#23] --< Param(2) >--> z2[#31]
  [[function]] $v6[#23] --< Param(3) >--> z3[#32]
  $v3[#24] --< P(baz) >--> [[function]] $v6[#23]
  $v4[#25] -
  y1[#26] -
  bar[#27] --< V(y1) >--> bar[#28]
  bar[#28] --< P(y1) >--> y1[#26]
  $v6[#29] -
  z1[#30] -
  z2[#31] -
  z3[#32] -
  baz[#33] --< V(z1) >--> baz[#34]
  baz[#34] --< P(z1) >--> z1[#30]
  baz[#34] --< V(z2) >--> baz[#35]
  baz[#35] --< P(z2) >--> z2[#31]
  baz[#35] --< V(z3) >--> baz[#36]
  baz[#36] --< P(z3) >--> z3[#32]

Graph.js MDG Builder: dynamic exports
  $ graphjs mdg --no-export dynamic.js
  module[#15] --< P(exports) >--> exports[#16]
  module[#15] --< P(*) >--> module.*[#21]
  exports[#16] --< V(foo) >--> exports[#18]
  [[function]] $v1[#17] --< Param(1) >--> x1[#28]
  exports[#18] --< P(foo) >--> [[function]] $v1[#17]
  exports[#18] --< V(bar) >--> $v4[#22]
  [[function]] $v3[#19] --< Param(1) >--> y1[#32]
  [[function]] $v3[#19] --< Param(2) >--> y2[#33]
  [[function]] $v3[#19] --< Param(3) >--> y3[#34]
  export_prop[#20] --< D >--> module.*[#21]
  module.*[#21] --< V(bar) >--> $v4[#22]
  $v4[#22] --< P(bar) >--> [[function]] $v3[#19]
  $v4[#22] --< V(*) >--> $v4[#26]
  [[function]] $v5[#23] --< Param(1) >--> z1[#40]
  export_prop[#24] --< D >--> module.*[#21]
  baz[#25] --< D >--> $v4[#26]
  $v4[#26] --< P(*) >--> [[function]] $v5[#23]
  $v1[#27] -
  x1[#28] -
  foo[#29] --< V(x1) >--> foo[#30]
  foo[#30] --< P(x1) >--> x1[#28]
  $v3[#31] -
  y1[#32] -
  y2[#33] -
  y3[#34] -
  bar[#35] --< V(y1) >--> bar[#36]
  bar[#36] --< P(y1) >--> y1[#32]
  bar[#36] --< V(y2) >--> bar[#37]
  bar[#37] --< P(y2) >--> y2[#33]
  bar[#37] --< V(y3) >--> bar[#38]
  bar[#38] --< P(y3) >--> y3[#34]
  $v5[#39] -
  z1[#40] -
  baz[#41] --< V(z1) >--> baz[#42]
  baz[#42] --< P(z1) >--> z1[#40]

Graph.js MDG Builder: mixed exports
  $ graphjs mdg --no-export mixed.js
  module[#15] --< P(exports) >--> exports[#16]
  exports[#16] --< V(foo) >--> exports[#18]
  [[function]] $v1[#17] --< Param(1) >--> x1[#22]
  exports[#18] --< P(foo) >--> [[function]] $v1[#17]
  exports[#18] --< V(bar) >--> exports[#20]
  [[function]] $v2[#19] --< Param(1) >--> y1[#26]
  [[function]] $v2[#19] --< Param(2) >--> y2[#27]
  [[function]] $v2[#19] --< Param(3) >--> y3[#28]
  exports[#20] --< P(bar) >--> [[function]] $v2[#19]
  $v1[#21] -
  x1[#22] -
  foo[#23] --< V(x1) >--> foo[#24]
  foo[#24] --< P(x1) >--> x1[#22]
  $v2[#25] -
  y1[#26] -
  y2[#27] -
  y3[#28] -
  bar[#29] --< V(y1) >--> bar[#30]
  bar[#30] --< P(y1) >--> y1[#26]
  bar[#30] --< V(y2) >--> bar[#31]
  bar[#31] --< P(y2) >--> y2[#27]
  bar[#31] --< V(y3) >--> bar[#32]
  bar[#32] --< P(y3) >--> y3[#28]
