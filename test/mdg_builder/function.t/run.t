Graph.js MDG Builder: function header
  $ graphjs mdg --no-export header.js
  [[function]] foo[#9] --< Param(0) >--> this[#10]
  this[#10] -
  [[function]] bar[#11] --< Param(0) >--> this[#12]
  [[function]] bar[#11] --< Param(1) >--> y1[#13]
  this[#12] -
  y1[#13] -
  [[function]] baz[#14] --< Param(0) >--> this[#15]
  [[function]] baz[#14] --< Param(1) >--> z1[#16]
  [[function]] baz[#14] --< Param(2) >--> z2[#17]
  [[function]] baz[#14] --< Param(3) >--> z3[#18]
  this[#15] -
  z1[#16] -
  z2[#17] -
  z3[#18] -
  [[function]] baz[#19] --< Param(0) >--> this[#20]
  [[function]] baz[#19] --< Param(1) >--> w1[#21]
  this[#20] -
  w1[#21] -

Graph.js MDG Builder: function body
  $ graphjs mdg --no-export body.js
  [[function]] foo[#9] --< Param(0) >--> this[#10]
  [[function]] foo[#9] --< Param(1) >--> x1[#11]
  this[#10] -
  x1[#11] -
  $v1[#12] --< V(p1) >--> $v1[#13]
  $v1[#13] --< P(p1) >--> x1[#11]
  [[function]] bar[#14] --< Param(0) >--> this[#15]
  [[function]] bar[#14] --< Param(1) >--> y1[#16]
  [[function]] bar[#14] --< Param(2) >--> y2[#17]
  [[function]] bar[#14] --< Param(3) >--> y3[#18]
  this[#15] -
  y1[#16] -
  y2[#17] -
  y3[#18] -
  $v2[#19] --< V(p1) >--> $v2[#20]
  $v2[#20] --< P(p1) >--> y1[#16]
  $v2[#20] --< V(p2) >--> $v2[#21]
  $v2[#21] --< P(p2) >--> y2[#17]
  $v2[#21] --< V(p3) >--> $v2[#22]
  $v2[#22] --< P(p3) >--> y3[#18]
  [[function]] baz[#23] --< Param(0) >--> this[#24]
  [[function]] baz[#23] --< Param(1) >--> z1[#25]
  this[#24] -
  z1[#25] --< P(p1) >--> z1.p1[#27]
  $v3[#26] --< V(p) >--> $v3[#28]
  z1.p1[#27] -
  $v3[#28] --< P(p) >--> z1.p1[#27]
  [[function]] qux[#29] --< Param(0) >--> this[#30]
  [[function]] qux[#29] --< Param(1) >--> w1[#31]
  this[#30] -
  w1[#31] --< P(p1) >--> w1.p1[#33]
  $v5[#32] --< V(p) >--> $v5[#34]
  $v5[#32] --< P(p) >--> $v5.p[#35]
  w1.p1[#33] -
  $v5[#34] --< P(p) >--> w1.p1[#33]
  $v5.p[#35] -
  $v8[#36] --< V(q) >--> $v8[#37]
  $v8[#37] --< P(q) >--> w1.p1[#33]

Graph.js MDG Builder: return statement
  $ graphjs mdg --no-export return.js
  [[function]] foo[#9] --< Param(0) >--> this[#10]
  [[function]] foo[#9] --< Param(1) >--> x1[#11]
  this[#10] -
  x1[#11] -
  [[function]] bar[#12] --< Param(0) >--> this[#13]
  [[function]] bar[#12] --< Param(1) >--> y1[#14]
  [[function]] bar[#12] --< Retn >--> 10[#15]
  this[#13] -
  y1[#14] -
  10[#15] -
  [[function]] baz[#16] --< Param(0) >--> this[#17]
  [[function]] baz[#16] --< Param(1) >--> z1[#18]
  [[function]] baz[#16] --< Retn >--> $v1[#19]
  this[#17] -
  z1[#18] -
  $v1[#19] -
  [[function]] qux[#20] --< Param(0) >--> this[#21]
  [[function]] qux[#20] --< Param(1) >--> w1[#22]
  [[function]] qux[#20] --< Retn >--> w1[#22]
  this[#21] -
  w1[#22] -

Graph.js MDG Builder: function scope
  $ graphjs mdg --no-export scope.js
  [[function]] foo[#9] --< Param(0) >--> this[#10]
  [[function]] foo[#9] --< Param(1) >--> x[#11]
  this[#10] -
  x[#11] -
  [[function]] bar[#12] --< Param(0) >--> this[#13]
  [[function]] bar[#12] --< Param(1) >--> y[#14]
  this[#13] -
  y[#14] -
  $v1[#15] --< V(p1) >--> $v1[#16]
  $v1[#16] --< P(p1) >--> x[#11]
  $v1[#16] --< V(p2) >--> $v1[#17]
  $v1[#17] --< P(p2) >--> y[#14]

Graph.js MDG Builder: call statement
  $ graphjs mdg --no-export call.js
  [[function]] foo[#9] --< Param(0) >--> this[#10]
  [[function]] foo[#9] --< Param(1) >--> x1[#11]
  this[#10] -
  x1[#11] -
  [[function]] bar[#12] --< Param(0) >--> this[#13]
  [[function]] bar[#12] --< Param(1) >--> y1[#14]
  [[function]] bar[#12] --< Param(2) >--> y2[#15]
  [[function]] bar[#12] --< Param(3) >--> y3[#16]
  this[#13] -
  y1[#14] -
  y2[#15] -
  y3[#16] -
  10[#17] --< Arg(1) >--> foo(...)[#18]
  foo(...)[#18] --< Call >--> [[function]] foo[#9]
  foo(...)[#18] --< D >--> $v1[#19]
  $v1[#19] -
  10[#20] --< Arg(1) >--> bar(...)[#21]
  bar(...)[#21] --< Call >--> [[function]] bar[#12]
  bar(...)[#21] --< D >--> $v2[#22]
  $v2[#22] -
  10[#23] --< Arg(1) >--> foo(...)[#26]
  "abc"[#24] --< Arg(2) >--> foo(...)[#26]
  true[#25] --< Arg(3) >--> foo(...)[#26]
  foo(...)[#26] --< Call >--> [[function]] foo[#9]
  foo(...)[#26] --< D >--> $v3[#27]
  $v3[#27] -
  10[#28] --< Arg(1) >--> bar(...)[#31]
  "abc"[#29] --< Arg(2) >--> bar(...)[#31]
  true[#30] --< Arg(3) >--> bar(...)[#31]
  bar(...)[#31] --< Call >--> [[function]] bar[#12]
  bar(...)[#31] --< D >--> $v4[#32]
  $v4[#32] -
  baz[#33] -
  10[#34] --< Arg(1) >--> baz(...)[#35]
  baz(...)[#35] --< Call >--> baz[#33]
  baz(...)[#35] --< D >--> $v5[#36]
  $v5[#36] -

Graph.js MDG Builder: new call statement
  $ graphjs mdg --no-export new.js
  [[function]] foo[#9] --< Param(0) >--> this[#10]
  [[function]] foo[#9] --< Param(1) >--> x1[#11]
  this[#10] -
  x1[#11] -
  [[function]] bar[#12] --< Param(0) >--> this[#13]
  [[function]] bar[#12] --< Param(1) >--> y1[#14]
  [[function]] bar[#12] --< Param(2) >--> y2[#15]
  [[function]] bar[#12] --< Param(3) >--> y3[#16]
  this[#13] -
  y1[#14] -
  y2[#15] -
  y3[#16] -
  10[#17] --< Arg(1) >--> foo(...)[#18]
  foo(...)[#18] --< Call >--> [[function]] foo[#9]
  foo(...)[#18] --< D >--> $v1[#19]
  $v1[#19] -
  10[#20] --< Arg(1) >--> bar(...)[#21]
  bar(...)[#21] --< Call >--> [[function]] bar[#12]
  bar(...)[#21] --< D >--> $v2[#22]
  $v2[#22] -
  10[#23] --< Arg(1) >--> foo(...)[#26]
  "abc"[#24] --< Arg(2) >--> foo(...)[#26]
  true[#25] --< Arg(3) >--> foo(...)[#26]
  foo(...)[#26] --< Call >--> [[function]] foo[#9]
  foo(...)[#26] --< D >--> $v3[#27]
  $v3[#27] -
  10[#28] --< Arg(1) >--> bar(...)[#31]
  "abc"[#29] --< Arg(2) >--> bar(...)[#31]
  true[#30] --< Arg(3) >--> bar(...)[#31]
  bar(...)[#31] --< Call >--> [[function]] bar[#12]
  bar(...)[#31] --< D >--> $v4[#32]
  $v4[#32] -
  baz[#33] -
  10[#34] --< Arg(1) >--> baz(...)[#35]
  baz(...)[#35] --< Call >--> baz[#33]
  baz(...)[#35] --< D >--> $v5[#36]
  $v5[#36] -

Graph.js MDG Builder: hoisted functions
  $ graphjs mdg --no-export hoisted.js
  [[function]] foo[#9] --< Param(0) >--> this[#10]
  [[function]] foo[#9] --< Param(1) >--> x[#11]
  this[#10] -
  x[#11] --< Arg(1) >--> foo(...)[#21]
  x[#11] --< Arg(1) >--> bar(...)[#23]
  [[function]] bar[#12] --< Param(0) >--> this[#13]
  [[function]] bar[#12] --< Param(1) >--> w[#14]
  this[#13] -
  w[#14] --< Arg(1) >--> bar(...)[#35]
  w[#14] --< Arg(1) >--> foo(...)[#37]
  10[#15] --< Arg(1) >--> foo(...)[#16]
  foo(...)[#16] --< Call >--> [[function]] foo[#9]
  foo(...)[#16] --< D >--> $v1[#17]
  $v1[#17] -
  "abc"[#18] --< Arg(1) >--> bar(...)[#19]
  bar(...)[#19] --< Call >--> [[function]] bar[#12]
  bar(...)[#19] --< D >--> $v2[#20]
  $v2[#20] -
  foo(...)[#21] --< Call >--> [[function]] foo[#9]
  foo(...)[#21] --< D >--> $v3[#22]
  $v3[#22] -
  bar(...)[#23] --< Call >--> [[function]] bar[#12]
  bar(...)[#23] --< D >--> $v4[#24]
  $v4[#24] -
  [[function]] foo[#25] --< Param(0) >--> this[#26]
  [[function]] foo[#25] --< Param(1) >--> y[#27]
  this[#26] -
  y[#27] --< Arg(1) >--> foo(...)[#28]
  foo(...)[#28] --< Call >--> [[function]] foo[#25]
  foo(...)[#28] --< D >--> $v5[#29]
  $v5[#29] -
  [[function]] bar[#30] --< Param(0) >--> this[#31]
  [[function]] bar[#30] --< Param(1) >--> z[#32]
  this[#31] -
  z[#32] --< Arg(1) >--> bar(...)[#33]
  bar(...)[#33] --< Call >--> [[function]] bar[#30]
  bar(...)[#33] --< D >--> $v6[#34]
  $v6[#34] -
  bar(...)[#35] --< Call >--> [[function]] bar[#30]
  bar(...)[#35] --< D >--> $v7[#36]
  $v7[#36] -
  foo(...)[#37] --< Call >--> [[function]] foo[#25]
  foo(...)[#37] --< D >--> $v8[#38]
  $v8[#38] -
  10[#39] --< Arg(1) >--> foo(...)[#40]
  foo(...)[#40] --< Call >--> [[function]] foo[#25]
  foo(...)[#40] --< D >--> $v9[#41]
  $v9[#41] -
  "abc"[#42] --< Arg(1) >--> bar(...)[#43]
  bar(...)[#43] --< Call >--> [[function]] bar[#30]
  bar(...)[#43] --< D >--> $v10[#44]
  $v10[#44] -
