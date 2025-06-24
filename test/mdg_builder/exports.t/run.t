Graph.js MDG Builder: simple exports
  $ graphjs mdg --no-export exports.js
  module[#16] --< P(exports) >--> exports[#17]
  exports[#17] --< V(foo) >--> exports[#19]
  [[function]] $v1[#18] --< Param(1) >--> x1[#26]
  exports[#19] --< P(foo) >--> [[function]] $v1[#18]
  exports[#19] --< V(bar) >--> exports[#21]
  [[function]] $v2[#20] --< Param(1) >--> y1[#30]
  [[function]] $v2[#20] --< Param(2) >--> y2[#31]
  [[function]] $v2[#20] --< Param(3) >--> y3[#32]
  exports[#21] --< P(bar) >--> [[function]] $v2[#20]
  exports[#22] --< V(baz) >--> exports[#24]
  [[function]] $v3[#23] -
  exports[#24] --< P(baz) >--> [[function]] $v3[#23]
  $v1[#25] -
  x1[#26] -
  foo[#27] --< V(x1) >--> foo[#28]
  foo[#28] --< P(x1) >--> x1[#26]
  $v2[#29] -
  y1[#30] -
  y2[#31] -
  y3[#32] -
  bar[#33] --< V(y1) >--> bar[#34]
  bar[#34] --< P(y1) >--> y1[#30]
  bar[#34] --< V(y2) >--> bar[#35]
  bar[#35] --< P(y2) >--> y2[#31]
  bar[#35] --< V(y3) >--> bar[#36]
  bar[#36] --< P(y3) >--> y3[#32]

Graph.js MDG Builder: module exports
  $ graphjs mdg --no-export module.js
  module[#16] --< P(exports) >--> exports[#17]
  module[#16] --< V(exports) >--> module[#21]
  exports[#17] --< V(foo) >--> exports[#19]
  [[function]] $v1[#18] -
  exports[#19] --< P(foo) >--> [[function]] $v1[#18]
  $v3[#20] --< V(bar) >--> $v3[#23]
  module[#21] --< P(exports) >--> $v3[#20]
  [[function]] $v4[#22] --< Param(1) >--> y1[#27]
  $v3[#23] --< P(bar) >--> [[function]] $v4[#22]
  $v3[#23] --< V(baz) >--> $v3[#25]
  [[function]] $v6[#24] --< Param(1) >--> z1[#31]
  [[function]] $v6[#24] --< Param(2) >--> z2[#32]
  [[function]] $v6[#24] --< Param(3) >--> z3[#33]
  $v3[#25] --< P(baz) >--> [[function]] $v6[#24]
  $v4[#26] -
  y1[#27] -
  bar[#28] --< V(y1) >--> bar[#29]
  bar[#29] --< P(y1) >--> y1[#27]
  $v6[#30] -
  z1[#31] -
  z2[#32] -
  z3[#33] -
  baz[#34] --< V(z1) >--> baz[#35]
  baz[#35] --< P(z1) >--> z1[#31]
  baz[#35] --< V(z2) >--> baz[#36]
  baz[#36] --< P(z2) >--> z2[#32]
  baz[#36] --< V(z3) >--> baz[#37]
  baz[#37] --< P(z3) >--> z3[#33]

Graph.js MDG Builder: dynamic exports
  $ graphjs mdg --no-export dynamic.js
  module[#16] --< P(exports) >--> exports[#17]
  module[#16] --< P(*) >--> module.*[#22]
  exports[#17] --< V(foo) >--> exports[#19]
  [[function]] $v1[#18] --< Param(1) >--> x1[#29]
  exports[#19] --< P(foo) >--> [[function]] $v1[#18]
  exports[#19] --< V(bar) >--> $v4[#23]
  [[function]] $v3[#20] --< Param(1) >--> y1[#33]
  [[function]] $v3[#20] --< Param(2) >--> y2[#34]
  [[function]] $v3[#20] --< Param(3) >--> y3[#35]
  export_prop[#21] --< D >--> module.*[#22]
  module.*[#22] --< V(bar) >--> $v4[#23]
  $v4[#23] --< P(bar) >--> [[function]] $v3[#20]
  $v4[#23] --< V(*) >--> $v4[#27]
  [[function]] $v5[#24] --< Param(1) >--> z1[#41]
  export_prop[#25] --< D >--> module.*[#22]
  baz[#26] --< D >--> $v4[#27]
  $v4[#27] --< P(*) >--> [[function]] $v5[#24]
  $v1[#28] -
  x1[#29] -
  foo[#30] --< V(x1) >--> foo[#31]
  foo[#31] --< P(x1) >--> x1[#29]
  $v3[#32] -
  y1[#33] -
  y2[#34] -
  y3[#35] -
  bar[#36] --< V(y1) >--> bar[#37]
  bar[#37] --< P(y1) >--> y1[#33]
  bar[#37] --< V(y2) >--> bar[#38]
  bar[#38] --< P(y2) >--> y2[#34]
  bar[#38] --< V(y3) >--> bar[#39]
  bar[#39] --< P(y3) >--> y3[#35]
  $v5[#40] -
  z1[#41] -
  baz[#42] --< V(z1) >--> baz[#43]
  baz[#43] --< P(z1) >--> z1[#41]

Graph.js MDG Builder: mixed exports
  $ graphjs mdg --no-export mixed.js
  module[#16] --< P(exports) >--> exports[#17]
  exports[#17] --< V(foo) >--> exports[#19]
  [[function]] $v1[#18] --< Param(1) >--> x1[#23]
  exports[#19] --< P(foo) >--> [[function]] $v1[#18]
  exports[#19] --< V(bar) >--> exports[#21]
  [[function]] $v2[#20] --< Param(1) >--> y1[#27]
  [[function]] $v2[#20] --< Param(2) >--> y2[#28]
  [[function]] $v2[#20] --< Param(3) >--> y3[#29]
  exports[#21] --< P(bar) >--> [[function]] $v2[#20]
  $v1[#22] -
  x1[#23] -
  foo[#24] --< V(x1) >--> foo[#25]
  foo[#25] --< P(x1) >--> x1[#23]
  $v2[#26] -
  y1[#27] -
  y2[#28] -
  y3[#29] -
  bar[#30] --< V(y1) >--> bar[#31]
  bar[#31] --< P(y1) >--> y1[#27]
  bar[#31] --< V(y2) >--> bar[#32]
  bar[#32] --< P(y2) >--> y2[#28]
  bar[#32] --< V(y3) >--> bar[#33]
  bar[#33] --< P(y3) >--> y3[#29]
