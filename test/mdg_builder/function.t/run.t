Graph.js MDG Builder: function header
  $ graphjs mdg --no-export header.js
  [[function]] foo[#18] -
  [[function]] bar[#19] -
  [[function]] baz[#20] -
  [[function]] baz[#21] -

Graph.js MDG Builder: call statement
  $ graphjs mdg --no-export call.js
  [[function]] foo[#18] -
  [[function]] bar[#19] -
  10[#20] -
  foo[#22] --< V(x1) >--> foo[#23]
  foo[#23] --< P(x1) >--> 10[#20]
  foo[#23] --< P(x1) >--> 10[#32]
  10[#24] -
  bar[#26] --< V(y1) >--> bar[#27]
  bar[#27] --< P(y1) >--> 10[#24]
  bar[#27] --< V(y2) >--> bar[#29]
  bar[#27] --< P(y1) >--> 10[#38]
  y2[#28] -
  bar[#29] --< P(y2) >--> y2[#28]
  bar[#29] --< V(y3) >--> bar[#31]
  bar[#29] --< P(y2) >--> "abc"[#39]
  y3[#30] -
  bar[#31] --< P(y3) >--> y3[#30]
  bar[#31] --< P(y3) >--> true[#40]
  10[#32] -
  "abc"[#33] -
  true[#34] -
  10[#38] -
  "abc"[#39] -
  true[#40] -
  baz[#46] -
  10[#47] --< Arg(1) >--> baz(...)[#48]
  baz(...)[#48] --< Call >--> baz[#46]
  baz(...)[#48] --< D >--> $v5[#49]
  $v5[#49] -

Graph.js MDG Builder: new call statement
  $ graphjs mdg --no-export new.js
  [[function]] foo[#18] -
  [[function]] bar[#19] -
  10[#20] -
  o1[#21] --< V(x1) >--> o1[#22]
  o1[#22] --< P(x1) >--> 10[#20]
  o1[#22] --< P(x1) >--> 10[#30]
  10[#23] -
  o2[#24] --< V(y1) >--> o2[#25]
  o2[#25] --< P(y1) >--> 10[#23]
  o2[#25] --< V(y2) >--> o2[#27]
  o2[#25] --< P(y1) >--> 10[#35]
  y2[#26] -
  o2[#27] --< P(y2) >--> y2[#26]
  o2[#27] --< V(y3) >--> o2[#29]
  o2[#27] --< P(y2) >--> "abc"[#36]
  y3[#28] -
  o2[#29] --< P(y3) >--> y3[#28]
  o2[#29] --< P(y3) >--> true[#37]
  10[#30] -
  "abc"[#31] -
  true[#32] -
  o3[#33] --< V(x1) >--> o1[#22]
  10[#35] -
  "abc"[#36] -
  true[#37] -
  o4[#38] --< V(y1) >--> o2[#25]
  baz[#42] -
  10[#43] --< Arg(1) >--> baz(...)[#44]
  baz(...)[#44] --< Call >--> baz[#42]
  baz(...)[#44] --< D >--> o5[#45]
  o5[#45] -

Graph.js MDG Builder: return statement
  $ graphjs mdg --no-export return.js
  [[function]] foo[#18] -
  [[function]] bar[#19] --< Retn >--> 10[#26]
  [[function]] baz[#20] --< Retn >--> $v1[#29]
  [[function]] qux[#21] --< Retn >--> null[#30]
  10[#22] -
  "abc"[#24] -
  10[#26] -
  true[#27] -
  $v1[#29] -
  null[#30] -

Graph.js MDG Builder: hoisted functions
  $ graphjs mdg --no-export hoisted.js
  [[function]] foo[#18] -
  [[function]] bar[#19] -
  10[#20] --< Arg(1) >--> foo(...)[#24]
  10[#20] --< Arg(1) >--> bar(...)[#29]
  10[#20] --< Arg(1) >--> foo(...)[#31]
  foo1[#22] --< V(x) >--> foo1[#23]
  foo1[#23] --< P(x) >--> 10[#20]
  foo1[#23] --< P(x) >--> "abc"[#33]
  foo(...)[#24] --< Call >--> [[function]] foo[#18]
  foo(...)[#24] --< D >--> $v3[#25]
  $v3[#25] -
  bar2[#27] --< V(w) >--> bar2[#28]
  bar2[#28] --< P(w) >--> 10[#20]
  bar2[#28] --< P(w) >--> "abc"[#33]
  bar(...)[#29] --< Call >--> [[function]] bar[#19]
  bar(...)[#29] --< D >--> $v7[#30]
  $v7[#30] -
  foo(...)[#31] --< Call >--> [[function]] foo[#18]
  foo(...)[#31] --< D >--> $v8[#32]
  $v8[#32] -
  "abc"[#33] --< Arg(1) >--> foo(...)[#24]
  "abc"[#33] --< Arg(1) >--> bar(...)[#29]
  "abc"[#33] --< Arg(1) >--> bar(...)[#44]
  bar(...)[#44] --< Call >--> [[function]] bar[#19]
  bar(...)[#44] --< D >--> $v4[#45]
  $v4[#45] -
  [[function]] foo[#46] -
  [[function]] bar[#47] -
  10[#48] --< Arg(1) >--> foo(...)[#52]
  foo2[#50] --< V(y) >--> foo2[#51]
  foo2[#51] --< P(y) >--> 10[#48]
  foo(...)[#52] --< Call >--> [[function]] foo[#46]
  foo(...)[#52] --< D >--> $v5[#53]
  $v5[#53] -
  "abc"[#54] --< Arg(1) >--> bar(...)[#58]
  bar1[#56] --< V(z) >--> bar1[#57]
  bar1[#57] --< P(z) >--> "abc"[#54]
  bar(...)[#58] --< Call >--> [[function]] bar[#47]
  bar(...)[#58] --< D >--> $v6[#59]
  $v6[#59] -

Graph.js MDG Builder: this access
  $ graphjs mdg --no-export this.js
  [[function]] bar[#18] --< Param(0) >--> this[#24]
  obj[#19] --< V(foo) >--> obj[#21]
  obj[#19] --< P(foo) >--> this.foo[#26]
  obj[#19] --< P(bar) >--> obj.bar[#33]
  10[#20] -
  obj[#21] --< P(foo) >--> 10[#20]
  obj[#21] --< V(bar) >--> obj[#22]
  obj[#22] --< P(bar) >--> [[function]] bar[#18]
  obj[#22] --< Arg(0) >--> this.bar(...)[#30]
  10[#23] -
  this[#24] --< P(foo) >--> this.foo[#26]
  this[#24] --< P(bar) >--> this.bar[#29]
  this[#24] --< Arg(0) >--> this.bar(...)[#30]
  x[#25] --< V(foo) >--> x[#27]
  this.foo[#26] -
  x[#27] --< P(foo) >--> 10[#20]
  x[#27] --< P(foo) >--> this.foo[#26]
  "abc"[#28] --< Arg(1) >--> this.bar(...)[#30]
  this.bar[#29] -
  this.bar(...)[#30] --< Call >--> [[function]] bar[#18]
  this.bar(...)[#30] --< Call >--> this.bar[#29]
  this.bar(...)[#30] --< D >--> y[#31]
  y[#31] -
  10[#32] -
  obj.bar[#33] -
