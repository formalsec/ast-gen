Graph.js MDG Builder: simple exports
  $ graphjs mdg --no-export exports.js
  module[#17] --< P(exports) >--> exports[#18]
  exports[#18] --< V(foo) >--> exports[#20]
  [[function]] $v1[#19] --< Param(1) >--> x1[#27]
  exports[#20] --< P(foo) >--> [[function]] $v1[#19]
  exports[#20] --< V(bar) >--> exports[#22]
  [[function]] $v2[#21] --< Param(1) >--> y1[#31]
  [[function]] $v2[#21] --< Param(2) >--> y2[#32]
  [[function]] $v2[#21] --< Param(3) >--> y3[#33]
  exports[#22] --< P(bar) >--> [[function]] $v2[#21]
  exports[#23] --< V(baz) >--> exports[#25]
  [[function]] $v3[#24] -
  exports[#25] --< P(baz) >--> [[function]] $v3[#24]
  $v1[#26] -
  x1[#27] -
  foo[#28] --< V(x1) >--> foo[#29]
  foo[#29] --< P(x1) >--> x1[#27]
  $v2[#30] -
  y1[#31] -
  y2[#32] -
  y3[#33] -
  bar[#34] --< V(y1) >--> bar[#35]
  bar[#35] --< P(y1) >--> y1[#31]
  bar[#35] --< V(y2) >--> bar[#36]
  bar[#36] --< P(y2) >--> y2[#32]
  bar[#36] --< V(y3) >--> bar[#37]
  bar[#37] --< P(y3) >--> y3[#33]

Graph.js MDG Builder: module exports
  $ graphjs mdg --no-export module.js
  module[#17] --< P(exports) >--> exports[#18]
  module[#17] --< V(exports) >--> module[#22]
  exports[#18] --< V(foo) >--> exports[#20]
  [[function]] $v1[#19] -
  exports[#20] --< P(foo) >--> [[function]] $v1[#19]
  $v3[#21] --< V(bar) >--> $v3[#24]
  module[#22] --< P(exports) >--> $v3[#21]
  [[function]] $v4[#23] --< Param(1) >--> y1[#28]
  $v3[#24] --< P(bar) >--> [[function]] $v4[#23]
  $v3[#24] --< V(baz) >--> $v3[#26]
  [[function]] $v6[#25] --< Param(1) >--> z1[#32]
  [[function]] $v6[#25] --< Param(2) >--> z2[#33]
  [[function]] $v6[#25] --< Param(3) >--> z3[#34]
  $v3[#26] --< P(baz) >--> [[function]] $v6[#25]
  $v4[#27] -
  y1[#28] -
  bar[#29] --< V(y1) >--> bar[#30]
  bar[#30] --< P(y1) >--> y1[#28]
  $v6[#31] -
  z1[#32] -
  z2[#33] -
  z3[#34] -
  baz[#35] --< V(z1) >--> baz[#36]
  baz[#36] --< P(z1) >--> z1[#32]
  baz[#36] --< V(z2) >--> baz[#37]
  baz[#37] --< P(z2) >--> z2[#33]
  baz[#37] --< V(z3) >--> baz[#38]
  baz[#38] --< P(z3) >--> z3[#34]

Graph.js MDG Builder: dynamic exports
  $ graphjs mdg --no-export dynamic.js
  module[#17] --< P(exports) >--> exports[#18]
  module[#17] --< P(*) >--> module.*[#23]
  exports[#18] --< V(foo) >--> exports[#20]
  [[function]] $v1[#19] --< Param(1) >--> x1[#30]
  exports[#20] --< P(foo) >--> [[function]] $v1[#19]
  exports[#20] --< V(bar) >--> $v4[#24]
  [[function]] $v3[#21] --< Param(1) >--> y1[#34]
  [[function]] $v3[#21] --< Param(2) >--> y2[#35]
  [[function]] $v3[#21] --< Param(3) >--> y3[#36]
  export_prop[#22] --< D >--> module.*[#23]
  module.*[#23] --< V(bar) >--> $v4[#24]
  $v4[#24] --< P(bar) >--> [[function]] $v3[#21]
  $v4[#24] --< V(*) >--> $v4[#28]
  [[function]] $v5[#25] --< Param(1) >--> z1[#42]
  export_prop[#26] --< D >--> module.*[#23]
  baz[#27] --< D >--> $v4[#28]
  $v4[#28] --< P(*) >--> [[function]] $v5[#25]
  $v1[#29] -
  x1[#30] -
  foo[#31] --< V(x1) >--> foo[#32]
  foo[#32] --< P(x1) >--> x1[#30]
  $v3[#33] -
  y1[#34] -
  y2[#35] -
  y3[#36] -
  bar[#37] --< V(y1) >--> bar[#38]
  bar[#38] --< P(y1) >--> y1[#34]
  bar[#38] --< V(y2) >--> bar[#39]
  bar[#39] --< P(y2) >--> y2[#35]
  bar[#39] --< V(y3) >--> bar[#40]
  bar[#40] --< P(y3) >--> y3[#36]
  $v5[#41] -
  z1[#42] -
  baz[#43] --< V(z1) >--> baz[#44]
  baz[#44] --< P(z1) >--> z1[#42]

Graph.js MDG Builder: mixed exports
  $ graphjs mdg --no-export mixed.js
  module[#17] --< P(exports) >--> exports[#18]
  exports[#18] --< V(foo) >--> exports[#20]
  [[function]] $v1[#19] --< Param(1) >--> x1[#24]
  exports[#20] --< P(foo) >--> [[function]] $v1[#19]
  exports[#20] --< V(bar) >--> exports[#22]
  [[function]] $v2[#21] --< Param(1) >--> y1[#28]
  [[function]] $v2[#21] --< Param(2) >--> y2[#29]
  [[function]] $v2[#21] --< Param(3) >--> y3[#30]
  exports[#22] --< P(bar) >--> [[function]] $v2[#21]
  $v1[#23] -
  x1[#24] -
  foo[#25] --< V(x1) >--> foo[#26]
  foo[#26] --< P(x1) >--> x1[#24]
  $v2[#27] -
  y1[#28] -
  y2[#29] -
  y3[#30] -
  bar[#31] --< V(y1) >--> bar[#32]
  bar[#32] --< P(y1) >--> y1[#28]
  bar[#32] --< V(y2) >--> bar[#33]
  bar[#33] --< P(y2) >--> y2[#29]
  bar[#33] --< V(y3) >--> bar[#34]
  bar[#34] --< P(y3) >--> y3[#30]
