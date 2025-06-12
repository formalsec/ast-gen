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
  foo[#20] --< V(x1) >--> foo[#21]
  foo[#21] --< P(x1) >--> 10[#19]
  foo[#21] --< P(x1) >--> 10[#29]
  10[#22] -
  bar[#23] --< V(y1) >--> bar[#24]
  bar[#24] --< P(y1) >--> 10[#22]
  bar[#24] --< V(y2) >--> bar[#26]
  bar[#24] --< P(y1) >--> 10[#34]
  y2[#25] -
  bar[#26] --< P(y2) >--> y2[#25]
  bar[#26] --< V(y3) >--> bar[#28]
  bar[#26] --< P(y2) >--> "abc"[#35]
  y3[#27] -
  bar[#28] --< P(y3) >--> y3[#27]
  bar[#28] --< P(y3) >--> true[#36]
  10[#29] -
  "abc"[#30] -
  true[#31] -
  10[#34] -
  "abc"[#35] -
  true[#36] -
  baz[#41] -
  10[#42] --< Arg(1) >--> baz(...)[#43]
  baz(...)[#43] --< Call >--> baz[#41]
  baz(...)[#43] --< D >--> $v5[#44]
  $v5[#44] -

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
  [[function]] bar[#18] --< Retn >--> 10[#23]
  [[function]] baz[#19] --< Retn >--> $v1[#25]
  [[function]] qux[#20] --< Retn >--> null[#26]
  10[#21] -
  "abc"[#22] -
  10[#23] -
  true[#24] -
  $v1[#25] -
  null[#26] -

Graph.js MDG Builder: hoisted functions
  $ graphjs mdg --no-export hoisted.js
  [[function]] foo[#17] -
  [[function]] bar[#18] -
  10[#19] --< Arg(1) >--> foo(...)[#22]
  10[#19] --< Arg(1) >--> bar(...)[#26]
  10[#19] --< Arg(1) >--> foo(...)[#28]
  foo1[#20] --< V(x) >--> foo1[#21]
  foo1[#21] --< P(x) >--> 10[#19]
  foo1[#21] --< P(x) >--> "abc"[#30]
  foo(...)[#22] --< Call >--> [[function]] foo[#17]
  foo(...)[#22] --< D >--> $v3[#23]
  $v3[#23] -
  bar2[#24] --< V(w) >--> bar2[#25]
  bar2[#25] --< P(w) >--> 10[#19]
  bar2[#25] --< P(w) >--> "abc"[#30]
  bar(...)[#26] --< Call >--> [[function]] bar[#18]
  bar(...)[#26] --< D >--> $v7[#27]
  $v7[#27] -
  foo(...)[#28] --< Call >--> [[function]] foo[#17]
  foo(...)[#28] --< D >--> $v8[#29]
  $v8[#29] -
  "abc"[#30] --< Arg(1) >--> foo(...)[#22]
  "abc"[#30] --< Arg(1) >--> bar(...)[#26]
  "abc"[#30] --< Arg(1) >--> bar(...)[#39]
  bar(...)[#39] --< Call >--> [[function]] bar[#18]
  bar(...)[#39] --< D >--> $v4[#40]
  $v4[#40] -
  [[function]] foo[#41] -
  [[function]] bar[#42] -
  10[#43] --< Arg(1) >--> foo(...)[#46]
  foo2[#44] --< V(y) >--> foo2[#45]
  foo2[#45] --< P(y) >--> 10[#43]
  foo(...)[#46] --< Call >--> [[function]] foo[#41]
  foo(...)[#46] --< D >--> $v5[#47]
  $v5[#47] -
  "abc"[#48] --< Arg(1) >--> bar(...)[#51]
  bar1[#49] --< V(z) >--> bar1[#50]
  bar1[#50] --< P(z) >--> "abc"[#48]
  bar(...)[#51] --< Call >--> [[function]] bar[#42]
  bar(...)[#51] --< D >--> $v6[#52]
  $v6[#52] -

Graph.js MDG Builder: this access
  $ graphjs mdg --no-export this.js
  [[function]] bar[#17] -
  obj[#18] --< V(foo) >--> obj[#20]
  obj[#18] --< P(foo) >--> this.foo[#25]
  obj[#18] --< P(bar) >--> obj.bar[#33]
  10[#19] -
  obj[#20] --< P(foo) >--> 10[#19]
  obj[#20] --< V(bar) >--> obj[#21]
  obj[#21] --< P(bar) >--> [[function]] bar[#17]
  obj[#21] --< Arg(0) >--> this.bar(...)[#30]
  10[#22] -
  x[#23] --< V(foo) >--> x[#26]
  this[#24] --< P(foo) >--> this.foo[#25]
  this.foo[#25] -
  x[#26] --< P(foo) >--> 10[#19]
  x[#26] --< P(foo) >--> this.foo[#25]
  this[#27] --< P(bar) >--> this.bar[#29]
  this[#27] --< Arg(0) >--> this.bar(...)[#30]
  "abc"[#28] --< Arg(1) >--> this.bar(...)[#30]
  this.bar[#29] -
  this.bar(...)[#30] --< Call >--> [[function]] bar[#17]
  this.bar(...)[#30] --< Call >--> this.bar[#29]
  this.bar(...)[#30] --< D >--> y[#31]
  y[#31] -
  10[#32] -
  obj.bar[#33] -
