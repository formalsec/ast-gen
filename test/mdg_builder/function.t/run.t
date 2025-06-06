Graph.js MDG Builder: function header
  $ graphjs mdg --no-export header.js
  [[function]] foo[#7] --< Param(0) >--> this[#8]
  this[#8] -
  [[function]] bar[#9] --< Param(0) >--> this[#10]
  [[function]] bar[#9] --< Param(1) >--> y1[#11]
  this[#10] -
  y1[#11] -
  [[function]] baz[#12] --< Param(0) >--> this[#13]
  [[function]] baz[#12] --< Param(1) >--> z1[#14]
  [[function]] baz[#12] --< Param(2) >--> z2[#15]
  [[function]] baz[#12] --< Param(3) >--> z3[#16]
  this[#13] -
  z1[#14] -
  z2[#15] -
  z3[#16] -
  [[function]] baz[#17] --< Param(0) >--> this[#18]
  [[function]] baz[#17] --< Param(1) >--> w1[#19]
  this[#18] -
  w1[#19] -

Graph.js MDG Builder: function body
  $ graphjs mdg --no-export body.js
  [[function]] foo[#7] --< Param(0) >--> this[#8]
  [[function]] foo[#7] --< Param(1) >--> x1[#9]
  this[#8] -
  x1[#9] -
  $v1[#10] --< V(p1) >--> $v1[#11]
  $v1[#11] --< P(p1) >--> x1[#9]
  [[function]] bar[#12] --< Param(0) >--> this[#13]
  [[function]] bar[#12] --< Param(1) >--> y1[#14]
  [[function]] bar[#12] --< Param(2) >--> y2[#15]
  [[function]] bar[#12] --< Param(3) >--> y3[#16]
  this[#13] -
  y1[#14] -
  y2[#15] -
  y3[#16] -
  $v2[#17] --< V(p1) >--> $v2[#18]
  $v2[#18] --< P(p1) >--> y1[#14]
  $v2[#18] --< V(p2) >--> $v2[#19]
  $v2[#19] --< P(p2) >--> y2[#15]
  $v2[#19] --< V(p3) >--> $v2[#20]
  $v2[#20] --< P(p3) >--> y3[#16]
  [[function]] baz[#21] --< Param(0) >--> this[#22]
  [[function]] baz[#21] --< Param(1) >--> z1[#23]
  this[#22] -
  z1[#23] --< P(p1) >--> z1.p1[#25]
  $v3[#24] --< V(p) >--> $v3[#26]
  z1.p1[#25] -
  $v3[#26] --< P(p) >--> z1.p1[#25]
  [[function]] qux[#27] --< Param(0) >--> this[#28]
  [[function]] qux[#27] --< Param(1) >--> w1[#29]
  this[#28] -
  w1[#29] --< P(p1) >--> w1.p1[#31]
  $v5[#30] --< V(p) >--> $v5[#32]
  $v5[#30] --< P(p) >--> $v5.p[#33]
  w1.p1[#31] -
  $v5[#32] --< P(p) >--> w1.p1[#31]
  $v5.p[#33] -
  $v8[#34] --< V(q) >--> $v8[#35]
  $v8[#35] --< P(q) >--> w1.p1[#31]

Graph.js MDG Builder: return statement
  $ graphjs mdg --no-export return.js
  [[function]] foo[#7] --< Param(0) >--> this[#8]
  [[function]] foo[#7] --< Param(1) >--> x1[#9]
  this[#8] -
  x1[#9] -
  [[function]] bar[#10] --< Param(0) >--> this[#11]
  [[function]] bar[#10] --< Param(1) >--> y1[#12]
  [[function]] bar[#10] --< Retn >--> 10[#13]
  this[#11] -
  y1[#12] -
  10[#13] -
  [[function]] baz[#14] --< Param(0) >--> this[#15]
  [[function]] baz[#14] --< Param(1) >--> z1[#16]
  [[function]] baz[#14] --< Retn >--> $v1[#17]
  this[#15] -
  z1[#16] -
  $v1[#17] -
  [[function]] qux[#18] --< Param(0) >--> this[#19]
  [[function]] qux[#18] --< Param(1) >--> w1[#20]
  [[function]] qux[#18] --< Retn >--> w1[#20]
  this[#19] -
  w1[#20] -

Graph.js MDG Builder: function scope
  $ graphjs mdg --no-export scope.js
  [[function]] foo[#7] --< Param(0) >--> this[#8]
  [[function]] foo[#7] --< Param(1) >--> x[#9]
  this[#8] -
  x[#9] -
  [[function]] bar[#10] --< Param(0) >--> this[#11]
  [[function]] bar[#10] --< Param(1) >--> y[#12]
  this[#11] -
  y[#12] -
  $v1[#13] --< V(p1) >--> $v1[#14]
  $v1[#14] --< P(p1) >--> x[#9]
  $v1[#14] --< V(p2) >--> $v1[#15]
  $v1[#15] --< P(p2) >--> y[#12]

Graph.js MDG Builder: call statement
  $ graphjs mdg --no-export call.js
  [[function]] foo[#7] --< Param(0) >--> this[#8]
  [[function]] foo[#7] --< Param(1) >--> x1[#9]
  this[#8] -
  x1[#9] -
  [[function]] bar[#10] --< Param(0) >--> this[#11]
  [[function]] bar[#10] --< Param(1) >--> y1[#12]
  [[function]] bar[#10] --< Param(2) >--> y2[#13]
  [[function]] bar[#10] --< Param(3) >--> y3[#14]
  this[#11] -
  y1[#12] -
  y2[#13] -
  y3[#14] -
  10[#15] --< Arg(1) >--> foo(...)[#16]
  foo(...)[#16] --< Call >--> [[function]] foo[#7]
  foo(...)[#16] --< D >--> $v1[#17]
  $v1[#17] -
  10[#18] --< Arg(1) >--> bar(...)[#19]
  bar(...)[#19] --< Call >--> [[function]] bar[#10]
  bar(...)[#19] --< D >--> $v2[#20]
  $v2[#20] -
  10[#21] --< Arg(1) >--> foo(...)[#24]
  "abc"[#22] --< Arg(2) >--> foo(...)[#24]
  true[#23] --< Arg(3) >--> foo(...)[#24]
  foo(...)[#24] --< Call >--> [[function]] foo[#7]
  foo(...)[#24] --< D >--> $v3[#25]
  $v3[#25] -
  10[#26] --< Arg(1) >--> bar(...)[#29]
  "abc"[#27] --< Arg(2) >--> bar(...)[#29]
  true[#28] --< Arg(3) >--> bar(...)[#29]
  bar(...)[#29] --< Call >--> [[function]] bar[#10]
  bar(...)[#29] --< D >--> $v4[#30]
  $v4[#30] -
  baz[#31] -
  10[#32] --< Arg(1) >--> baz(...)[#33]
  baz(...)[#33] --< Call >--> baz[#31]
  baz(...)[#33] --< D >--> $v5[#34]
  $v5[#34] -

Graph.js MDG Builder: new call statement
  $ graphjs mdg --no-export new.js
  [[function]] foo[#7] --< Param(0) >--> this[#8]
  [[function]] foo[#7] --< Param(1) >--> x1[#9]
  this[#8] -
  x1[#9] -
  [[function]] bar[#10] --< Param(0) >--> this[#11]
  [[function]] bar[#10] --< Param(1) >--> y1[#12]
  [[function]] bar[#10] --< Param(2) >--> y2[#13]
  [[function]] bar[#10] --< Param(3) >--> y3[#14]
  this[#11] -
  y1[#12] -
  y2[#13] -
  y3[#14] -
  10[#15] --< Arg(1) >--> foo(...)[#16]
  foo(...)[#16] --< Call >--> [[function]] foo[#7]
  foo(...)[#16] --< D >--> $v1[#17]
  $v1[#17] -
  10[#18] --< Arg(1) >--> bar(...)[#19]
  bar(...)[#19] --< Call >--> [[function]] bar[#10]
  bar(...)[#19] --< D >--> $v2[#20]
  $v2[#20] -
  10[#21] --< Arg(1) >--> foo(...)[#24]
  "abc"[#22] --< Arg(2) >--> foo(...)[#24]
  true[#23] --< Arg(3) >--> foo(...)[#24]
  foo(...)[#24] --< Call >--> [[function]] foo[#7]
  foo(...)[#24] --< D >--> $v3[#25]
  $v3[#25] -
  10[#26] --< Arg(1) >--> bar(...)[#29]
  "abc"[#27] --< Arg(2) >--> bar(...)[#29]
  true[#28] --< Arg(3) >--> bar(...)[#29]
  bar(...)[#29] --< Call >--> [[function]] bar[#10]
  bar(...)[#29] --< D >--> $v4[#30]
  $v4[#30] -
  baz[#31] -
  10[#32] --< Arg(1) >--> baz(...)[#33]
  baz(...)[#33] --< Call >--> baz[#31]
  baz(...)[#33] --< D >--> $v5[#34]
  $v5[#34] -

Graph.js MDG Builder: hoisted functions
  $ graphjs mdg --no-export hoisted.js
  [[function]] foo[#7] --< Param(0) >--> this[#8]
  [[function]] foo[#7] --< Param(1) >--> x[#9]
  this[#8] -
  x[#9] --< Arg(1) >--> foo(...)[#19]
  x[#9] --< Arg(1) >--> bar(...)[#21]
  [[function]] bar[#10] --< Param(0) >--> this[#11]
  [[function]] bar[#10] --< Param(1) >--> w[#12]
  this[#11] -
  w[#12] --< Arg(1) >--> bar(...)[#33]
  w[#12] --< Arg(1) >--> foo(...)[#35]
  10[#13] --< Arg(1) >--> foo(...)[#14]
  foo(...)[#14] --< Call >--> [[function]] foo[#7]
  foo(...)[#14] --< D >--> $v1[#15]
  $v1[#15] -
  "abc"[#16] --< Arg(1) >--> bar(...)[#17]
  bar(...)[#17] --< Call >--> [[function]] bar[#10]
  bar(...)[#17] --< D >--> $v2[#18]
  $v2[#18] -
  foo(...)[#19] --< Call >--> [[function]] foo[#7]
  foo(...)[#19] --< D >--> $v3[#20]
  $v3[#20] -
  bar(...)[#21] --< Call >--> [[function]] bar[#10]
  bar(...)[#21] --< D >--> $v4[#22]
  $v4[#22] -
  [[function]] foo[#23] --< Param(0) >--> this[#24]
  [[function]] foo[#23] --< Param(1) >--> y[#25]
  this[#24] -
  y[#25] --< Arg(1) >--> foo(...)[#26]
  foo(...)[#26] --< Call >--> [[function]] foo[#23]
  foo(...)[#26] --< D >--> $v5[#27]
  $v5[#27] -
  [[function]] bar[#28] --< Param(0) >--> this[#29]
  [[function]] bar[#28] --< Param(1) >--> z[#30]
  this[#29] -
  z[#30] --< Arg(1) >--> bar(...)[#31]
  bar(...)[#31] --< Call >--> [[function]] bar[#28]
  bar(...)[#31] --< D >--> $v6[#32]
  $v6[#32] -
  bar(...)[#33] --< Call >--> [[function]] bar[#28]
  bar(...)[#33] --< D >--> $v7[#34]
  $v7[#34] -
  foo(...)[#35] --< Call >--> [[function]] foo[#23]
  foo(...)[#35] --< D >--> $v8[#36]
  $v8[#36] -
  10[#37] --< Arg(1) >--> foo(...)[#38]
  foo(...)[#38] --< Call >--> [[function]] foo[#23]
  foo(...)[#38] --< D >--> $v9[#39]
  $v9[#39] -
  "abc"[#40] --< Arg(1) >--> bar(...)[#41]
  bar(...)[#41] --< Call >--> [[function]] bar[#28]
  bar(...)[#41] --< D >--> $v10[#42]
  $v10[#42] -
