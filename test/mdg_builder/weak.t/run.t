Graph.js MDG Builder: week property lookup
  $ graphjs mdg --no-export property_lookup.js
  [[function]] defineProperty[#5] -
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
  [[function]] defineProperty[#5] -
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
  [[function]] defineProperty[#5] -
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
  [[function]] defineProperty[#5] -
  $v1[#17] --< V(foo) >--> $v1[#21]
  $v1[#17] --< P(foo) >--> obj.foo[#30]
  $v1[#17] --< P(bar) >--> obj.bar[#37]
  $v1[#17] --< P(baz) >--> obj.baz[#42]
  [[function]] $v2[#18] --< Param(0) >--> this[#19]
  [[function]] $v2[#18] --< Param(1) >--> x1[#20]
  this[#19] -
  x1[#20] -
  $v1[#21] --< P(foo) >--> [[function]] $v2[#18]
  $v1[#21] --< Arg(0) >--> obj.foo(...)[#32]
  $v1[#21] --< Arg(0) >--> obj.bar(...)[#39]
  $v1[#21] --< Arg(0) >--> obj.baz(...)[#44]
  $v3[#22] --< V(bar) >--> $v3[#28]
  $v3[#22] --< P(foo) >--> obj.foo[#30]
  $v3[#22] --< P(bar) >--> obj.bar[#37]
  $v3[#22] --< P(baz) >--> obj.baz[#42]
  [[function]] $v4[#23] --< Param(0) >--> this[#24]
  [[function]] $v4[#23] --< Param(1) >--> y1[#25]
  [[function]] $v4[#23] --< Param(2) >--> y2[#26]
  [[function]] $v4[#23] --< Param(3) >--> y3[#27]
  this[#24] -
  y1[#25] -
  y2[#26] -
  y3[#27] -
  $v3[#28] --< P(bar) >--> [[function]] $v4[#23]
  $v3[#28] --< Arg(0) >--> obj.foo(...)[#32]
  $v3[#28] --< Arg(0) >--> obj.bar(...)[#39]
  $v3[#28] --< Arg(0) >--> obj.baz(...)[#44]
  10[#29] --< Arg(1) >--> obj.foo(...)[#32]
  obj.foo[#30] -
  obj.foo(...)[#32] --< Call >--> [[function]] $v2[#18]
  obj.foo(...)[#32] --< Call >--> obj.foo[#30]
  obj.foo(...)[#32] --< D >--> $v5[#33]
  $v5[#33] -
  10[#34] --< Arg(1) >--> obj.bar(...)[#39]
  "abc"[#35] --< Arg(2) >--> obj.bar(...)[#39]
  true[#36] --< Arg(3) >--> obj.bar(...)[#39]
  obj.bar[#37] -
  obj.bar(...)[#39] --< Call >--> [[function]] $v4[#23]
  obj.bar(...)[#39] --< Call >--> obj.bar[#37]
  obj.bar(...)[#39] --< D >--> $v6[#40]
  $v6[#40] -
  10[#41] --< Arg(1) >--> obj.baz(...)[#44]
  obj.baz[#42] -
  obj.baz(...)[#44] --< Call >--> obj.baz[#42]
  obj.baz(...)[#44] --< D >--> $v7[#45]
  $v7[#45] -

Graph.js MDG Builder: week property value
  $ graphjs mdg --no-export property_value.js
  [[function]] defineProperty[#5] -
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
  [[function]] defineProperty[#5] -
  [[function]] $v1[#17] --< Param(0) >--> this[#18]
  [[function]] $v1[#17] --< Param(1) >--> x1[#19]
  this[#18] -
  x1[#19] -
  [[function]] $v2[#20] --< Param(0) >--> this[#21]
  [[function]] $v2[#20] --< Param(1) >--> y1[#22]
  [[function]] $v2[#20] --< Param(2) >--> y2[#23]
  [[function]] $v2[#20] --< Param(3) >--> y3[#24]
  this[#21] -
  y1[#22] -
  y2[#23] -
  y3[#24] -
  10[#25] --< Arg(1) >--> foo(...)[#26]
  foo(...)[#26] --< Call >--> [[function]] $v1[#17]
  foo(...)[#26] --< Call >--> [[function]] $v2[#20]
  foo(...)[#26] --< D >--> $v3[#27]
  $v3[#27] -
  10[#28] --< Arg(1) >--> foo(...)[#31]
  "abc"[#29] --< Arg(2) >--> foo(...)[#31]
  true[#30] --< Arg(3) >--> foo(...)[#31]
  foo(...)[#31] --< Call >--> [[function]] $v1[#17]
  foo(...)[#31] --< Call >--> [[function]] $v2[#20]
  foo(...)[#31] --< D >--> $v4[#32]
  $v4[#32] -
