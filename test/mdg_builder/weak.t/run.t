Graph.js MDG Builder: week property lookup
  $ graphjs mdg --no-export property_lookup.js
  $v1[#17] --< P(foo) >--> obj.foo[#19]
  $v1[#17] --< P(bar) >--> obj.bar[#21]
  $v1[#17] --< P(10) >--> obj.10[#24]
  $v1[#17] --< P(abc) >--> obj.abc[#26]
  $v1[#17] --< P(null) >--> obj.null[#28]
  $v2[#18] --< P(foo) >--> obj.foo[#19]
  $v2[#18] --< P(bar) >--> obj.bar[#21]
  $v2[#18] --< P(10) >--> obj.10[#24]
  $v2[#18] --< P(abc) >--> obj.abc[#26]
  $v2[#18] --< P(null) >--> obj.null[#28]
  obj.foo[#19] -
  obj.bar[#21] --< P(baz) >--> obj.bar.baz[#23]
  obj.bar.baz[#23] -
  obj.10[#24] -
  obj.abc[#26] -
  obj.null[#28] -

Graph.js MDG Builder: week property update
  $ graphjs mdg --no-export property_update.js
  $v1[#17] --< V(foo) >--> obj[#20]
  $v1[#17] --< P(bar) >--> obj.bar[#23]
  $v2[#18] --< V(foo) >--> obj[#20]
  $v2[#18] --< P(bar) >--> obj.bar[#23]
  10[#19] -
  obj[#20] --< P(foo) >--> 10[#19]
  obj[#20] --< V(bar) >--> obj[#22]
  $v3[#21] --< V(baz) >--> $v3[#26]
  obj[#22] --< P(bar) >--> $v3[#21]
  obj[#22] --< V(10) >--> obj[#28]
  obj.bar[#23] -
  10[#25] -
  $v3[#26] --< P(baz) >--> 10[#25]
  10[#27] -
  obj[#28] --< P(10) >--> 10[#27]
  obj[#28] --< V(abc) >--> obj[#30]
  10[#29] -
  obj[#30] --< P(abc) >--> 10[#29]
  obj[#30] --< V(null) >--> obj[#32]
  10[#31] -
  obj[#32] --< P(null) >--> 10[#31]

Graph.js MDG Builder: week property access
  $ graphjs mdg --no-export property_access.js
  $v1[#17] --< V(foo) >--> obj[#20]
  $v1[#17] --< P(foo) >--> obj.foo[#23]
  $v1[#17] --< P(bar) >--> obj.bar[#26]
  $v2[#18] --< V(foo) >--> obj[#20]
  $v2[#18] --< P(foo) >--> obj.foo[#23]
  $v2[#18] --< P(bar) >--> obj.bar[#26]
  10[#19] -
  obj[#20] --< P(foo) >--> 10[#19]
  obj[#20] --< V(bar) >--> obj[#22]
  $v3[#21] -
  obj[#22] --< P(bar) >--> $v3[#21]
  obj[#22] --< V(baz) >--> obj[#25]
  obj.foo[#23] -
  obj[#25] --< P(baz) >--> 10[#19]
  obj[#25] --< V(baz) >--> obj[#28]
  obj.bar[#26] -
  obj[#28] --< P(baz) >--> $v3[#21]

Graph.js MDG Builder: week method call
  $ graphjs mdg --no-export method_call.js
  $v1[#17] --< V(foo) >--> $v1[#19]
  $v1[#17] --< P(foo) >--> obj.foo[#24]
  $v1[#17] --< P(bar) >--> obj.bar[#33]
  $v1[#17] --< P(baz) >--> obj.baz[#42]
  [[function]] $v2[#18] -
  $v1[#19] --< P(foo) >--> [[function]] $v2[#18]
  $v1[#19] --< Arg(0) >--> obj.foo(...)[#28]
  $v1[#19] --< Arg(0) >--> obj.bar(...)[#39]
  $v1[#19] --< Arg(0) >--> obj.baz(...)[#44]
  $v3[#20] --< V(bar) >--> $v3[#22]
  $v3[#20] --< P(foo) >--> obj.foo[#24]
  $v3[#20] --< P(bar) >--> obj.bar[#33]
  $v3[#20] --< P(baz) >--> obj.baz[#42]
  [[function]] $v4[#21] -
  $v3[#22] --< P(bar) >--> [[function]] $v4[#21]
  $v3[#22] --< Arg(0) >--> obj.foo(...)[#28]
  $v3[#22] --< Arg(0) >--> obj.bar(...)[#39]
  $v3[#22] --< Arg(0) >--> obj.baz(...)[#44]
  10[#23] --< Arg(1) >--> obj.foo(...)[#28]
  obj.foo[#24] -
  foo[#26] --< V(x1) >--> foo[#27]
  foo[#27] --< P(x1) >--> 10[#23]
  obj.foo(...)[#28] --< Call >--> obj.foo[#24]
  obj.foo(...)[#28] --< D >--> $v5[#29]
  $v5[#29] -
  10[#30] --< Arg(1) >--> obj.bar(...)[#39]
  "abc"[#31] --< Arg(2) >--> obj.bar(...)[#39]
  true[#32] --< Arg(3) >--> obj.bar(...)[#39]
  obj.bar[#33] -
  baz[#35] --< V(y1) >--> baz[#36]
  baz[#36] --< P(y1) >--> 10[#30]
  baz[#36] --< V(y2) >--> baz[#37]
  baz[#37] --< P(y2) >--> "abc"[#31]
  baz[#37] --< V(y3) >--> baz[#38]
  baz[#38] --< P(y3) >--> true[#32]
  obj.bar(...)[#39] --< Call >--> obj.bar[#33]
  obj.bar(...)[#39] --< D >--> $v6[#40]
  $v6[#40] -
  10[#41] --< Arg(1) >--> obj.baz(...)[#44]
  obj.baz[#42] -
  obj.baz(...)[#44] --< Call >--> obj.baz[#42]
  obj.baz(...)[#44] --< D >--> $v7[#45]
  $v7[#45] -

Graph.js MDG Builder: week property value
  $ graphjs mdg --no-export property_value.js
  $v1[#17] --< V(foo) >--> obj[#20]
  $v1[#17] --< P(foo) >--> obj.foo[#25]
  $v2[#18] --< V(foo) >--> obj[#20]
  $v2[#18] --< P(foo) >--> obj.foo[#25]
  10[#19] -
  obj[#20] --< P(foo) >--> 10[#19]
  obj[#20] --< V(foo) >--> obj[#23]
  $v4[#21] -
  $v5[#22] -
  obj[#23] --< P(foo) >--> $v4[#21]
  obj[#23] --< P(foo) >--> $v5[#22]
  obj2[#24] --< V(bar) >--> obj2[#27]
  obj.foo[#25] -
  obj2[#27] --< P(bar) >--> $v4[#21]
  obj2[#27] --< P(bar) >--> $v5[#22]

Graph.js MDG Builder: week function call
  $ graphjs mdg --no-export function_call.js
  [[function]] $v1[#17] -
  [[function]] $v2[#18] -
  10[#19] -
  bar[#20] --< V(x1) >--> bar[#21]
  bar[#21] --< P(x1) >--> 10[#19]
  bar[#21] --< P(x1) >--> 10[#28]
  baz[#22] --< V(y1) >--> baz[#23]
  baz[#23] --< P(y1) >--> 10[#19]
  baz[#23] --< V(y2) >--> baz[#25]
  baz[#23] --< P(y1) >--> 10[#28]
  y2[#24] -
  baz[#25] --< P(y2) >--> y2[#24]
  baz[#25] --< V(y3) >--> baz[#27]
  baz[#25] --< P(y2) >--> "abc"[#29]
  y3[#26] -
  baz[#27] --< P(y3) >--> y3[#26]
  baz[#27] --< P(y3) >--> true[#30]
  10[#28] -
  "abc"[#29] -
  true[#30] -
