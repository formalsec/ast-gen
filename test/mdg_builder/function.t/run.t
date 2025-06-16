Graph.js MDG Builder: function header
  $ graphjs mdg --no-export header.js
  [[function]] foo[#17] -
  [[function]] bar[#18] -
  [[function]] baz[#19] -
  [[function]] baz[#20] -

Graph.js MDG Builder: call statement
  $ graphjs mdg --no-export call.js
  [[function]] foo[#17] -
  [[function]] bar[#18] -
  10[#19] -
  foo[#21] --< V(x1) >--> foo[#22]
  foo[#22] --< P(x1) >--> 10[#19]
  foo[#22] --< P(x1) >--> 10[#31]
  10[#23] -
  bar[#25] --< V(y1) >--> bar[#26]
  bar[#26] --< P(y1) >--> 10[#23]
  bar[#26] --< V(y2) >--> bar[#28]
  bar[#26] --< P(y1) >--> 10[#37]
  y2[#27] -
  bar[#28] --< P(y2) >--> y2[#27]
  bar[#28] --< V(y3) >--> bar[#30]
  bar[#28] --< P(y2) >--> "abc"[#38]
  y3[#29] -
  bar[#30] --< P(y3) >--> y3[#29]
  bar[#30] --< P(y3) >--> true[#39]
  10[#31] -
  "abc"[#32] -
  true[#33] -
  10[#37] -
  "abc"[#38] -
  true[#39] -
  baz[#45] -
  10[#46] --< Arg(1) >--> baz(...)[#47]
  baz(...)[#47] --< Call >--> baz[#45]
  baz(...)[#47] --< D >--> $v5[#48]
  $v5[#48] -

Graph.js MDG Builder: new call statement
  $ graphjs mdg --no-export new.js
  [[function]] foo[#17] -
  [[function]] bar[#18] -
  10[#19] -
  o1[#20] --< V(x1) >--> o1[#21]
  o1[#21] --< P(x1) >--> 10[#19]
  o1[#21] --< P(x1) >--> 10[#29]
  10[#22] -
  o2[#23] --< V(y1) >--> o2[#24]
  o2[#24] --< P(y1) >--> 10[#22]
  o2[#24] --< V(y2) >--> o2[#26]
  o2[#24] --< P(y1) >--> 10[#34]
  y2[#25] -
  o2[#26] --< P(y2) >--> y2[#25]
  o2[#26] --< V(y3) >--> o2[#28]
  o2[#26] --< P(y2) >--> "abc"[#35]
  y3[#27] -
  o2[#28] --< P(y3) >--> y3[#27]
  o2[#28] --< P(y3) >--> true[#36]
  10[#29] -
  "abc"[#30] -
  true[#31] -
  o3[#32] --< V(x1) >--> o1[#21]
  10[#34] -
  "abc"[#35] -
  true[#36] -
  o4[#37] --< V(y1) >--> o2[#24]
  baz[#41] -
  10[#42] --< Arg(1) >--> baz(...)[#43]
  baz(...)[#43] --< Call >--> baz[#41]
  baz(...)[#43] --< D >--> o5[#44]
  o5[#44] -

Graph.js MDG Builder: return statement
  $ graphjs mdg --no-export return.js
  [[function]] foo[#17] -
  [[function]] bar[#18] --< Retn >--> 10[#25]
  [[function]] baz[#19] --< Retn >--> $v1[#28]
  [[function]] qux[#20] --< Retn >--> null[#29]
  10[#21] -
  "abc"[#23] -
  10[#25] -
  true[#26] -
  $v1[#28] -
  null[#29] -

Graph.js MDG Builder: hoisted functions
  $ graphjs mdg --no-export hoisted.js
  [[function]] foo[#17] -
  [[function]] bar[#18] -
  10[#19] --< Arg(1) >--> foo(...)[#23]
  10[#19] --< Arg(1) >--> bar(...)[#28]
  10[#19] --< Arg(1) >--> foo(...)[#30]
  foo1[#21] --< V(x) >--> foo1[#22]
  foo1[#22] --< P(x) >--> 10[#19]
  foo1[#22] --< P(x) >--> "abc"[#32]
  foo(...)[#23] --< Call >--> [[function]] foo[#17]
  foo(...)[#23] --< D >--> $v3[#24]
  $v3[#24] -
  bar2[#26] --< V(w) >--> bar2[#27]
  bar2[#27] --< P(w) >--> 10[#19]
  bar2[#27] --< P(w) >--> "abc"[#32]
  bar(...)[#28] --< Call >--> [[function]] bar[#18]
  bar(...)[#28] --< D >--> $v7[#29]
  $v7[#29] -
  foo(...)[#30] --< Call >--> [[function]] foo[#17]
  foo(...)[#30] --< D >--> $v8[#31]
  $v8[#31] -
  "abc"[#32] --< Arg(1) >--> foo(...)[#23]
  "abc"[#32] --< Arg(1) >--> bar(...)[#28]
  "abc"[#32] --< Arg(1) >--> bar(...)[#43]
  bar(...)[#43] --< Call >--> [[function]] bar[#18]
  bar(...)[#43] --< D >--> $v4[#44]
  $v4[#44] -
  [[function]] foo[#45] -
  [[function]] bar[#46] -
  10[#47] --< Arg(1) >--> foo(...)[#51]
  foo2[#49] --< V(y) >--> foo2[#50]
  foo2[#50] --< P(y) >--> 10[#47]
  foo(...)[#51] --< Call >--> [[function]] foo[#45]
  foo(...)[#51] --< D >--> $v5[#52]
  $v5[#52] -
  "abc"[#53] --< Arg(1) >--> bar(...)[#57]
  bar1[#55] --< V(z) >--> bar1[#56]
  bar1[#56] --< P(z) >--> "abc"[#53]
  bar(...)[#57] --< Call >--> [[function]] bar[#46]
  bar(...)[#57] --< D >--> $v6[#58]
  $v6[#58] -

Graph.js MDG Builder: this access
  $ graphjs mdg --no-export this.js
  [[function]] bar[#17] --< Param(0) >--> this[#23]
  obj[#18] --< V(foo) >--> obj[#20]
  obj[#18] --< P(foo) >--> this.foo[#25]
  obj[#18] --< P(bar) >--> obj.bar[#32]
  10[#19] -
  obj[#20] --< P(foo) >--> 10[#19]
  obj[#20] --< V(bar) >--> obj[#21]
  obj[#21] --< P(bar) >--> [[function]] bar[#17]
  obj[#21] --< Arg(0) >--> this.bar(...)[#29]
  10[#22] -
  this[#23] --< P(foo) >--> this.foo[#25]
  this[#23] --< P(bar) >--> this.bar[#28]
  this[#23] --< Arg(0) >--> this.bar(...)[#29]
  x[#24] --< V(foo) >--> x[#26]
  this.foo[#25] -
  x[#26] --< P(foo) >--> 10[#19]
  x[#26] --< P(foo) >--> this.foo[#25]
  "abc"[#27] --< Arg(1) >--> this.bar(...)[#29]
  this.bar[#28] -
  this.bar(...)[#29] --< Call >--> [[function]] bar[#17]
  this.bar(...)[#29] --< Call >--> this.bar[#28]
  this.bar(...)[#29] --< D >--> y[#30]
  y[#30] -
  10[#31] -
  obj.bar[#32] -
