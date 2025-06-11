Graph.js MDG Builder: function header
  $ graphjs mdg --no-export header.js
  [[function]] defineProperty[#5] -
  [[function]] foo[#17] --< Param(0) >--> this[#18]
  this[#18] -
  [[function]] bar[#19] --< Param(0) >--> this[#20]
  [[function]] bar[#19] --< Param(1) >--> y1[#21]
  this[#20] -
  y1[#21] -
  [[function]] baz[#22] --< Param(0) >--> this[#23]
  [[function]] baz[#22] --< Param(1) >--> z1[#24]
  [[function]] baz[#22] --< Param(2) >--> z2[#25]
  [[function]] baz[#22] --< Param(3) >--> z3[#26]
  this[#23] -
  z1[#24] -
  z2[#25] -
  z3[#26] -
  [[function]] baz[#27] --< Param(0) >--> this[#28]
  [[function]] baz[#27] --< Param(1) >--> w1[#29]
  this[#28] -
  w1[#29] -

Graph.js MDG Builder: function body
  $ graphjs mdg --no-export body.js
  [[function]] defineProperty[#5] -
  [[function]] foo[#17] --< Param(0) >--> this[#18]
  [[function]] foo[#17] --< Param(1) >--> x1[#19]
  this[#18] -
  x1[#19] -
  $v1[#20] --< V(p1) >--> $v1[#21]
  $v1[#21] --< P(p1) >--> x1[#19]
  [[function]] bar[#22] --< Param(0) >--> this[#23]
  [[function]] bar[#22] --< Param(1) >--> y1[#24]
  [[function]] bar[#22] --< Param(2) >--> y2[#25]
  [[function]] bar[#22] --< Param(3) >--> y3[#26]
  this[#23] -
  y1[#24] -
  y2[#25] -
  y3[#26] -
  $v2[#27] --< V(p1) >--> $v2[#28]
  $v2[#28] --< P(p1) >--> y1[#24]
  $v2[#28] --< V(p2) >--> $v2[#29]
  $v2[#29] --< P(p2) >--> y2[#25]
  $v2[#29] --< V(p3) >--> $v2[#30]
  $v2[#30] --< P(p3) >--> y3[#26]
  [[function]] baz[#31] --< Param(0) >--> this[#32]
  [[function]] baz[#31] --< Param(1) >--> z1[#33]
  this[#32] -
  z1[#33] --< P(p1) >--> z1.p1[#35]
  $v3[#34] --< V(p) >--> $v3[#36]
  z1.p1[#35] -
  $v3[#36] --< P(p) >--> z1.p1[#35]
  [[function]] qux[#37] --< Param(0) >--> this[#38]
  [[function]] qux[#37] --< Param(1) >--> w1[#39]
  this[#38] -
  w1[#39] --< P(p1) >--> w1.p1[#41]
  $v5[#40] --< V(p) >--> $v5[#42]
  $v5[#40] --< P(p) >--> $v5.p[#43]
  w1.p1[#41] -
  $v5[#42] --< P(p) >--> w1.p1[#41]
  $v5.p[#43] -
  $v8[#44] --< V(q) >--> $v8[#45]
  $v8[#45] --< P(q) >--> w1.p1[#41]

Graph.js MDG Builder: return statement
  $ graphjs mdg --no-export return.js
  [[function]] defineProperty[#5] -
  [[function]] foo[#17] --< Param(0) >--> this[#18]
  [[function]] foo[#17] --< Param(1) >--> x1[#19]
  this[#18] -
  x1[#19] -
  [[function]] bar[#20] --< Param(0) >--> this[#21]
  [[function]] bar[#20] --< Param(1) >--> y1[#22]
  [[function]] bar[#20] --< Retn >--> 10[#23]
  this[#21] -
  y1[#22] -
  10[#23] -
  [[function]] baz[#24] --< Param(0) >--> this[#25]
  [[function]] baz[#24] --< Param(1) >--> z1[#26]
  [[function]] baz[#24] --< Retn >--> $v1[#27]
  this[#25] -
  z1[#26] -
  $v1[#27] -
  [[function]] qux[#28] --< Param(0) >--> this[#29]
  [[function]] qux[#28] --< Param(1) >--> w1[#30]
  [[function]] qux[#28] --< Retn >--> w1[#30]
  this[#29] -
  w1[#30] -

Graph.js MDG Builder: function scope
  $ graphjs mdg --no-export scope.js
  [[function]] defineProperty[#5] -
  [[function]] foo[#17] --< Param(0) >--> this[#18]
  [[function]] foo[#17] --< Param(1) >--> x[#19]
  this[#18] -
  x[#19] -
  [[function]] bar[#20] --< Param(0) >--> this[#21]
  [[function]] bar[#20] --< Param(1) >--> y[#22]
  this[#21] -
  y[#22] -
  $v1[#23] --< V(p1) >--> $v1[#24]
  $v1[#24] --< P(p1) >--> x[#19]
  $v1[#24] --< V(p2) >--> $v1[#25]
  $v1[#25] --< P(p2) >--> y[#22]

Graph.js MDG Builder: call statement
  $ graphjs mdg --no-export call.js
  [[function]] defineProperty[#5] -
  [[function]] foo[#17] --< Param(0) >--> this[#18]
  [[function]] foo[#17] --< Param(1) >--> x1[#19]
  this[#18] -
  x1[#19] -
  [[function]] bar[#20] --< Param(0) >--> this[#21]
  [[function]] bar[#20] --< Param(1) >--> y1[#22]
  [[function]] bar[#20] --< Param(2) >--> y2[#23]
  [[function]] bar[#20] --< Param(3) >--> y3[#24]
  this[#21] -
  y1[#22] -
  y2[#23] -
  y3[#24] -
  10[#25] --< Arg(1) >--> foo(...)[#26]
  foo(...)[#26] --< Call >--> [[function]] foo[#17]
  foo(...)[#26] --< D >--> $v1[#27]
  $v1[#27] -
  10[#28] --< Arg(1) >--> bar(...)[#29]
  bar(...)[#29] --< Call >--> [[function]] bar[#20]
  bar(...)[#29] --< D >--> $v2[#30]
  $v2[#30] -
  10[#31] --< Arg(1) >--> foo(...)[#34]
  "abc"[#32] --< Arg(2) >--> foo(...)[#34]
  true[#33] --< Arg(3) >--> foo(...)[#34]
  foo(...)[#34] --< Call >--> [[function]] foo[#17]
  foo(...)[#34] --< D >--> $v3[#35]
  $v3[#35] -
  10[#36] --< Arg(1) >--> bar(...)[#39]
  "abc"[#37] --< Arg(2) >--> bar(...)[#39]
  true[#38] --< Arg(3) >--> bar(...)[#39]
  bar(...)[#39] --< Call >--> [[function]] bar[#20]
  bar(...)[#39] --< D >--> $v4[#40]
  $v4[#40] -
  baz[#41] -
  10[#42] --< Arg(1) >--> baz(...)[#43]
  baz(...)[#43] --< Call >--> baz[#41]
  baz(...)[#43] --< D >--> $v5[#44]
  $v5[#44] -

Graph.js MDG Builder: new call statement
  $ graphjs mdg --no-export new.js
  [[function]] defineProperty[#5] -
  [[function]] foo[#17] --< Param(0) >--> this[#18]
  [[function]] foo[#17] --< Param(1) >--> x1[#19]
  this[#18] -
  x1[#19] -
  [[function]] bar[#20] --< Param(0) >--> this[#21]
  [[function]] bar[#20] --< Param(1) >--> y1[#22]
  [[function]] bar[#20] --< Param(2) >--> y2[#23]
  [[function]] bar[#20] --< Param(3) >--> y3[#24]
  this[#21] -
  y1[#22] -
  y2[#23] -
  y3[#24] -
  10[#25] --< Arg(1) >--> foo(...)[#26]
  foo(...)[#26] --< Call >--> [[function]] foo[#17]
  foo(...)[#26] --< D >--> $v1[#27]
  $v1[#27] -
  10[#28] --< Arg(1) >--> bar(...)[#29]
  bar(...)[#29] --< Call >--> [[function]] bar[#20]
  bar(...)[#29] --< D >--> $v2[#30]
  $v2[#30] -
  10[#31] --< Arg(1) >--> foo(...)[#34]
  "abc"[#32] --< Arg(2) >--> foo(...)[#34]
  true[#33] --< Arg(3) >--> foo(...)[#34]
  foo(...)[#34] --< Call >--> [[function]] foo[#17]
  foo(...)[#34] --< D >--> $v3[#35]
  $v3[#35] -
  10[#36] --< Arg(1) >--> bar(...)[#39]
  "abc"[#37] --< Arg(2) >--> bar(...)[#39]
  true[#38] --< Arg(3) >--> bar(...)[#39]
  bar(...)[#39] --< Call >--> [[function]] bar[#20]
  bar(...)[#39] --< D >--> $v4[#40]
  $v4[#40] -
  baz[#41] -
  10[#42] --< Arg(1) >--> baz(...)[#43]
  baz(...)[#43] --< Call >--> baz[#41]
  baz(...)[#43] --< D >--> $v5[#44]
  $v5[#44] -

Graph.js MDG Builder: hoisted functions
  $ graphjs mdg --no-export hoisted.js
  [[function]] defineProperty[#5] -
  [[function]] foo[#17] --< Param(0) >--> this[#18]
  [[function]] foo[#17] --< Param(1) >--> x[#19]
  this[#18] -
  x[#19] --< Arg(1) >--> foo(...)[#29]
  x[#19] --< Arg(1) >--> bar(...)[#31]
  [[function]] bar[#20] --< Param(0) >--> this[#21]
  [[function]] bar[#20] --< Param(1) >--> w[#22]
  this[#21] -
  w[#22] --< Arg(1) >--> bar(...)[#43]
  w[#22] --< Arg(1) >--> foo(...)[#45]
  10[#23] --< Arg(1) >--> foo(...)[#24]
  foo(...)[#24] --< Call >--> [[function]] foo[#17]
  foo(...)[#24] --< D >--> $v1[#25]
  $v1[#25] -
  "abc"[#26] --< Arg(1) >--> bar(...)[#27]
  bar(...)[#27] --< Call >--> [[function]] bar[#20]
  bar(...)[#27] --< D >--> $v2[#28]
  $v2[#28] -
  foo(...)[#29] --< Call >--> [[function]] foo[#17]
  foo(...)[#29] --< D >--> $v3[#30]
  $v3[#30] -
  bar(...)[#31] --< Call >--> [[function]] bar[#20]
  bar(...)[#31] --< D >--> $v4[#32]
  $v4[#32] -
  [[function]] foo[#33] --< Param(0) >--> this[#34]
  [[function]] foo[#33] --< Param(1) >--> y[#35]
  this[#34] -
  y[#35] --< Arg(1) >--> foo(...)[#36]
  foo(...)[#36] --< Call >--> [[function]] foo[#33]
  foo(...)[#36] --< D >--> $v5[#37]
  $v5[#37] -
  [[function]] bar[#38] --< Param(0) >--> this[#39]
  [[function]] bar[#38] --< Param(1) >--> z[#40]
  this[#39] -
  z[#40] --< Arg(1) >--> bar(...)[#41]
  bar(...)[#41] --< Call >--> [[function]] bar[#38]
  bar(...)[#41] --< D >--> $v6[#42]
  $v6[#42] -
  bar(...)[#43] --< Call >--> [[function]] bar[#38]
  bar(...)[#43] --< D >--> $v7[#44]
  $v7[#44] -
  foo(...)[#45] --< Call >--> [[function]] foo[#33]
  foo(...)[#45] --< D >--> $v8[#46]
  $v8[#46] -
  10[#47] --< Arg(1) >--> foo(...)[#48]
  foo(...)[#48] --< Call >--> [[function]] foo[#33]
  foo(...)[#48] --< D >--> $v9[#49]
  $v9[#49] -
  "abc"[#50] --< Arg(1) >--> bar(...)[#51]
  bar(...)[#51] --< Call >--> [[function]] bar[#38]
  bar(...)[#51] --< D >--> $v10[#52]
  $v10[#52] -
