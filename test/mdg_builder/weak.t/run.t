Graph.js MDG Builder: week property lookup
  $ graphjs mdg --no-export property_lookup.js
  $v1[#18] --< P(foo) >--> obj.foo[#20]
  $v1[#18] --< P(bar) >--> obj.bar[#22]
  $v1[#18] --< P(10) >--> obj.10[#25]
  $v1[#18] --< P(abc) >--> obj.abc[#27]
  $v1[#18] --< P(null) >--> obj.null[#29]
  $v2[#19] --< P(foo) >--> obj.foo[#20]
  $v2[#19] --< P(bar) >--> obj.bar[#22]
  $v2[#19] --< P(10) >--> obj.10[#25]
  $v2[#19] --< P(abc) >--> obj.abc[#27]
  $v2[#19] --< P(null) >--> obj.null[#29]
  obj.foo[#20] -
  obj.bar[#22] --< P(baz) >--> obj.bar.baz[#24]
  obj.bar.baz[#24] -
  obj.10[#25] -
  obj.abc[#27] -
  obj.null[#29] -

Graph.js MDG Builder: week property update
  $ graphjs mdg --no-export property_update.js
  $v1[#18] --< V(foo) >--> obj[#21]
  $v1[#18] --< P(bar) >--> obj.bar[#24]
  $v2[#19] --< V(foo) >--> obj[#21]
  $v2[#19] --< P(bar) >--> obj.bar[#24]
  10[#20] -
  obj[#21] --< P(foo) >--> 10[#20]
  obj[#21] --< V(bar) >--> obj[#23]
  $v3[#22] --< V(baz) >--> $v3[#27]
  obj[#23] --< P(bar) >--> $v3[#22]
  obj[#23] --< V(10) >--> obj[#29]
  obj.bar[#24] -
  10[#26] -
  $v3[#27] --< P(baz) >--> 10[#26]
  10[#28] -
  obj[#29] --< P(10) >--> 10[#28]
  obj[#29] --< V(abc) >--> obj[#31]
  10[#30] -
  obj[#31] --< P(abc) >--> 10[#30]
  obj[#31] --< V(null) >--> obj[#33]
  10[#32] -
  obj[#33] --< P(null) >--> 10[#32]

Graph.js MDG Builder: week property access
  $ graphjs mdg --no-export property_access.js
  $v1[#18] --< V(foo) >--> obj[#21]
  $v1[#18] --< P(foo) >--> obj.foo[#24]
  $v1[#18] --< P(bar) >--> obj.bar[#27]
  $v2[#19] --< V(foo) >--> obj[#21]
  $v2[#19] --< P(foo) >--> obj.foo[#24]
  $v2[#19] --< P(bar) >--> obj.bar[#27]
  10[#20] -
  obj[#21] --< P(foo) >--> 10[#20]
  obj[#21] --< V(bar) >--> obj[#23]
  $v3[#22] -
  obj[#23] --< P(bar) >--> $v3[#22]
  obj[#23] --< V(baz) >--> obj[#26]
  obj.foo[#24] -
  obj[#26] --< P(baz) >--> 10[#20]
  obj[#26] --< V(baz) >--> obj[#29]
  obj.bar[#27] -
  obj[#29] --< P(baz) >--> $v3[#22]

Graph.js MDG Builder: week method call
  $ graphjs mdg --no-export method_call.js
  $v1[#18] --< V(foo) >--> $v1[#20]
  $v1[#18] --< P(foo) >--> obj.foo[#25]
  $v1[#18] --< P(bar) >--> obj.bar[#34]
  $v1[#18] --< P(baz) >--> obj.baz[#43]
  [[function]] $v2[#19] -
  $v1[#20] --< P(foo) >--> [[function]] $v2[#19]
  $v1[#20] --< Arg(0) >--> obj.foo(...)[#29]
  $v1[#20] --< Arg(0) >--> obj.bar(...)[#40]
  $v1[#20] --< Arg(0) >--> obj.baz(...)[#45]
  $v3[#21] --< V(bar) >--> $v3[#23]
  $v3[#21] --< P(foo) >--> obj.foo[#25]
  $v3[#21] --< P(bar) >--> obj.bar[#34]
  $v3[#21] --< P(baz) >--> obj.baz[#43]
  [[function]] $v4[#22] -
  $v3[#23] --< P(bar) >--> [[function]] $v4[#22]
  $v3[#23] --< Arg(0) >--> obj.foo(...)[#29]
  $v3[#23] --< Arg(0) >--> obj.bar(...)[#40]
  $v3[#23] --< Arg(0) >--> obj.baz(...)[#45]
  10[#24] --< Arg(1) >--> obj.foo(...)[#29]
  obj.foo[#25] -
  foo[#27] --< V(x1) >--> foo[#28]
  foo[#28] --< P(x1) >--> 10[#24]
  obj.foo(...)[#29] --< Call >--> obj.foo[#25]
  obj.foo(...)[#29] --< D >--> $v5[#30]
  $v5[#30] -
  10[#31] --< Arg(1) >--> obj.bar(...)[#40]
  "abc"[#32] --< Arg(2) >--> obj.bar(...)[#40]
  true[#33] --< Arg(3) >--> obj.bar(...)[#40]
  obj.bar[#34] -
  baz[#36] --< V(y1) >--> baz[#37]
  baz[#37] --< P(y1) >--> 10[#31]
  baz[#37] --< V(y2) >--> baz[#38]
  baz[#38] --< P(y2) >--> "abc"[#32]
  baz[#38] --< V(y3) >--> baz[#39]
  baz[#39] --< P(y3) >--> true[#33]
  obj.bar(...)[#40] --< Call >--> obj.bar[#34]
  obj.bar(...)[#40] --< D >--> $v6[#41]
  $v6[#41] -
  10[#42] --< Arg(1) >--> obj.baz(...)[#45]
  obj.baz[#43] -
  obj.baz(...)[#45] --< Call >--> obj.baz[#43]
  obj.baz(...)[#45] --< D >--> $v7[#46]
  $v7[#46] -

Graph.js MDG Builder: week property value
  $ graphjs mdg --no-export property_value.js
  $v1[#18] --< V(foo) >--> obj[#21]
  $v1[#18] --< P(foo) >--> obj.foo[#26]
  $v2[#19] --< V(foo) >--> obj[#21]
  $v2[#19] --< P(foo) >--> obj.foo[#26]
  10[#20] -
  obj[#21] --< P(foo) >--> 10[#20]
  obj[#21] --< V(foo) >--> obj[#24]
  $v4[#22] -
  $v5[#23] -
  obj[#24] --< P(foo) >--> $v4[#22]
  obj[#24] --< P(foo) >--> $v5[#23]
  obj2[#25] --< V(bar) >--> obj2[#28]
  obj.foo[#26] -
  obj2[#28] --< P(bar) >--> $v4[#22]
  obj2[#28] --< P(bar) >--> $v5[#23]

Graph.js MDG Builder: week function call
  $ graphjs mdg --no-export function_call.js
  [[function]] $v1[#18] -
  [[function]] $v2[#19] -
  10[#20] -
  bar[#22] --< V(x1) >--> bar[#23]
  bar[#23] --< P(x1) >--> 10[#20]
  bar[#23] --< P(x1) >--> 10[#31]
  baz[#25] --< V(y1) >--> baz[#26]
  baz[#26] --< P(y1) >--> 10[#20]
  baz[#26] --< V(y2) >--> baz[#28]
  baz[#26] --< P(y1) >--> 10[#31]
  y2[#27] -
  baz[#28] --< P(y2) >--> y2[#27]
  baz[#28] --< V(y3) >--> baz[#30]
  baz[#28] --< P(y2) >--> "abc"[#32]
  y3[#29] -
  baz[#30] --< P(y3) >--> y3[#29]
  baz[#30] --< P(y3) >--> true[#33]
  10[#31] -
  "abc"[#32] -
  true[#33] -
