Graph.js MDG Builder: function header
  $ graphjs mdg --no-export header.js
  [[function]] foo[#19] -
  [[function]] bar[#20] -
  [[function]] baz[#21] -
  [[function]] baz[#22] -

Graph.js MDG Builder: call statement
  $ graphjs mdg --no-export call.js
  [[function]] foo[#19] -
  [[function]] bar[#20] -
  10[#21] -
  foo[#23] --< V(x1) >--> foo[#24]
  foo[#24] --< P(x1) >--> 10[#21]
  foo[#24] --< P(x1) >--> 10[#33]
  10[#25] -
  bar[#27] --< V(y1) >--> bar[#28]
  bar[#28] --< P(y1) >--> 10[#25]
  bar[#28] --< V(y2) >--> bar[#30]
  bar[#28] --< P(y1) >--> 10[#39]
  y2[#29] -
  bar[#30] --< P(y2) >--> y2[#29]
  bar[#30] --< V(y3) >--> bar[#32]
  bar[#30] --< P(y2) >--> "abc"[#40]
  y3[#31] -
  bar[#32] --< P(y3) >--> y3[#31]
  bar[#32] --< P(y3) >--> true[#41]
  10[#33] -
  "abc"[#34] -
  true[#35] -
  10[#39] -
  "abc"[#40] -
  true[#41] -
  baz[#47] -
  10[#48] --< Arg(1) >--> baz(...)[#49]
  baz(...)[#49] --< Call >--> baz[#47]
  baz(...)[#49] --< D >--> $v5[#50]
  $v5[#50] -

Graph.js MDG Builder: new call statement
  $ graphjs mdg --no-export new.js
  [[function]] foo[#19] -
  [[function]] bar[#20] -
  10[#21] -
  o1[#22] --< V(x1) >--> o1[#23]
  o1[#23] --< P(x1) >--> 10[#21]
  o1[#23] --< P(x1) >--> 10[#31]
  10[#24] -
  o2[#25] --< V(y1) >--> o2[#26]
  o2[#26] --< P(y1) >--> 10[#24]
  o2[#26] --< V(y2) >--> o2[#28]
  o2[#26] --< P(y1) >--> 10[#36]
  y2[#27] -
  o2[#28] --< P(y2) >--> y2[#27]
  o2[#28] --< V(y3) >--> o2[#30]
  o2[#28] --< P(y2) >--> "abc"[#37]
  y3[#29] -
  o2[#30] --< P(y3) >--> y3[#29]
  o2[#30] --< P(y3) >--> true[#38]
  10[#31] -
  "abc"[#32] -
  true[#33] -
  o3[#34] --< V(x1) >--> o1[#23]
  10[#36] -
  "abc"[#37] -
  true[#38] -
  o4[#39] --< V(y1) >--> o2[#26]
  baz[#43] -
  10[#44] --< Arg(1) >--> baz(...)[#45]
  baz(...)[#45] --< Call >--> baz[#43]
  baz(...)[#45] --< D >--> o5[#46]
  o5[#46] -

Graph.js MDG Builder: return statement
  $ graphjs mdg --no-export return.js
  [[function]] foo[#19] -
  [[function]] bar[#20] --< Retn >--> 10[#27]
  [[function]] baz[#21] --< Retn >--> $v1[#30]
  [[function]] qux[#22] --< Retn >--> null[#31]
  10[#23] -
  "abc"[#25] -
  10[#27] -
  true[#28] -
  $v1[#30] -
  null[#31] -

Graph.js MDG Builder: hoisted functions
  $ graphjs mdg --no-export hoisted.js
  [[function]] foo[#19] -
  [[function]] bar[#20] -
  10[#21] --< Arg(1) >--> foo(...)[#25]
  10[#21] --< Arg(1) >--> bar(...)[#30]
  10[#21] --< Arg(1) >--> foo(...)[#32]
  foo1[#23] --< V(x) >--> foo1[#24]
  foo1[#24] --< P(x) >--> 10[#21]
  foo1[#24] --< P(x) >--> "abc"[#34]
  foo(...)[#25] --< Call >--> [[function]] foo[#19]
  foo(...)[#25] --< D >--> $v3[#26]
  $v3[#26] -
  bar2[#28] --< V(w) >--> bar2[#29]
  bar2[#29] --< P(w) >--> 10[#21]
  bar2[#29] --< P(w) >--> "abc"[#34]
  bar(...)[#30] --< Call >--> [[function]] bar[#20]
  bar(...)[#30] --< D >--> $v7[#31]
  $v7[#31] -
  foo(...)[#32] --< Call >--> [[function]] foo[#19]
  foo(...)[#32] --< D >--> $v8[#33]
  $v8[#33] -
  "abc"[#34] --< Arg(1) >--> foo(...)[#25]
  "abc"[#34] --< Arg(1) >--> bar(...)[#30]
  "abc"[#34] --< Arg(1) >--> bar(...)[#45]
  bar(...)[#45] --< Call >--> [[function]] bar[#20]
  bar(...)[#45] --< D >--> $v4[#46]
  $v4[#46] -
  [[function]] foo[#47] -
  [[function]] bar[#48] -
  10[#49] --< Arg(1) >--> foo(...)[#53]
  foo2[#51] --< V(y) >--> foo2[#52]
  foo2[#52] --< P(y) >--> 10[#49]
  foo(...)[#53] --< Call >--> [[function]] foo[#47]
  foo(...)[#53] --< D >--> $v5[#54]
  $v5[#54] -
  "abc"[#55] --< Arg(1) >--> bar(...)[#59]
  bar1[#57] --< V(z) >--> bar1[#58]
  bar1[#58] --< P(z) >--> "abc"[#55]
  bar(...)[#59] --< Call >--> [[function]] bar[#48]
  bar(...)[#59] --< D >--> $v6[#60]
  $v6[#60] -

Graph.js MDG Builder: this access
  $ graphjs mdg --no-export this.js
  [[function]] bar[#19] --< Param(0) >--> this[#25]
  obj[#20] --< V(foo) >--> obj[#22]
  obj[#20] --< P(foo) >--> this.foo[#27]
  obj[#20] --< P(bar) >--> obj.bar[#34]
  10[#21] -
  obj[#22] --< P(foo) >--> 10[#21]
  obj[#22] --< V(bar) >--> obj[#23]
  obj[#23] --< P(bar) >--> [[function]] bar[#19]
  obj[#23] --< Arg(0) >--> this.bar(...)[#31]
  10[#24] -
  this[#25] --< P(foo) >--> this.foo[#27]
  this[#25] --< P(bar) >--> this.bar[#30]
  this[#25] --< Arg(0) >--> this.bar(...)[#31]
  x[#26] --< V(foo) >--> x[#28]
  this.foo[#27] -
  x[#28] --< P(foo) >--> 10[#21]
  x[#28] --< P(foo) >--> this.foo[#27]
  "abc"[#29] --< Arg(1) >--> this.bar(...)[#31]
  this.bar[#30] -
  this.bar(...)[#31] --< Call >--> [[function]] bar[#19]
  this.bar(...)[#31] --< Call >--> this.bar[#30]
  this.bar(...)[#31] --< D >--> y[#32]
  y[#32] -
  10[#33] -
  obj.bar[#34] -
