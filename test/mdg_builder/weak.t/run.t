Graph.js MDG Builder: week property lookup
  $ graphjs mdg --no-export property_lookup.js
  $v1[#19] --< P(foo) >--> obj.foo[#21]
  $v1[#19] --< P(bar) >--> obj.bar[#23]
  $v1[#19] --< P(10) >--> obj.10[#26]
  $v1[#19] --< P(abc) >--> obj.abc[#28]
  $v1[#19] --< P(null) >--> obj.null[#30]
  $v2[#20] --< P(foo) >--> obj.foo[#21]
  $v2[#20] --< P(bar) >--> obj.bar[#23]
  $v2[#20] --< P(10) >--> obj.10[#26]
  $v2[#20] --< P(abc) >--> obj.abc[#28]
  $v2[#20] --< P(null) >--> obj.null[#30]
  obj.foo[#21] -
  obj.bar[#23] --< P(baz) >--> obj.bar.baz[#25]
  obj.bar.baz[#25] -
  obj.10[#26] -
  obj.abc[#28] -
  obj.null[#30] -

Graph.js MDG Builder: week property update
  $ graphjs mdg --no-export property_update.js
  $v1[#19] --< V(foo) >--> obj[#22]
  $v1[#19] --< P(bar) >--> obj.bar[#25]
  $v2[#20] --< V(foo) >--> obj[#22]
  $v2[#20] --< P(bar) >--> obj.bar[#25]
  10[#21] -
  obj[#22] --< P(foo) >--> 10[#21]
  obj[#22] --< V(bar) >--> obj[#24]
  $v3[#23] --< V(baz) >--> $v3[#28]
  obj[#24] --< P(bar) >--> $v3[#23]
  obj[#24] --< V(10) >--> obj[#30]
  obj.bar[#25] -
  10[#27] -
  $v3[#28] --< P(baz) >--> 10[#27]
  10[#29] -
  obj[#30] --< P(10) >--> 10[#29]
  obj[#30] --< V(abc) >--> obj[#32]
  10[#31] -
  obj[#32] --< P(abc) >--> 10[#31]
  obj[#32] --< V(null) >--> obj[#34]
  10[#33] -
  obj[#34] --< P(null) >--> 10[#33]

Graph.js MDG Builder: week property access
  $ graphjs mdg --no-export property_access.js
  $v1[#19] --< V(foo) >--> obj[#22]
  $v1[#19] --< P(foo) >--> obj.foo[#25]
  $v1[#19] --< P(bar) >--> obj.bar[#28]
  $v2[#20] --< V(foo) >--> obj[#22]
  $v2[#20] --< P(foo) >--> obj.foo[#25]
  $v2[#20] --< P(bar) >--> obj.bar[#28]
  10[#21] -
  obj[#22] --< P(foo) >--> 10[#21]
  obj[#22] --< V(bar) >--> obj[#24]
  $v3[#23] -
  obj[#24] --< P(bar) >--> $v3[#23]
  obj[#24] --< V(baz) >--> obj[#27]
  obj.foo[#25] -
  obj[#27] --< P(baz) >--> 10[#21]
  obj[#27] --< V(baz) >--> obj[#30]
  obj.bar[#28] -
  obj[#30] --< P(baz) >--> $v3[#23]

Graph.js MDG Builder: week method call
  $ graphjs mdg --no-export method_call.js
  $v1[#19] --< V(foo) >--> $v1[#21]
  $v1[#19] --< P(foo) >--> obj.foo[#26]
  $v1[#19] --< P(bar) >--> obj.bar[#35]
  $v1[#19] --< P(baz) >--> obj.baz[#44]
  [[function]] $v2[#20] -
  $v1[#21] --< P(foo) >--> [[function]] $v2[#20]
  $v1[#21] --< Arg(0) >--> obj.foo(...)[#30]
  $v1[#21] --< Arg(0) >--> obj.bar(...)[#41]
  $v1[#21] --< Arg(0) >--> obj.baz(...)[#46]
  $v3[#22] --< V(bar) >--> $v3[#24]
  $v3[#22] --< P(foo) >--> obj.foo[#26]
  $v3[#22] --< P(bar) >--> obj.bar[#35]
  $v3[#22] --< P(baz) >--> obj.baz[#44]
  [[function]] $v4[#23] -
  $v3[#24] --< P(bar) >--> [[function]] $v4[#23]
  $v3[#24] --< Arg(0) >--> obj.foo(...)[#30]
  $v3[#24] --< Arg(0) >--> obj.bar(...)[#41]
  $v3[#24] --< Arg(0) >--> obj.baz(...)[#46]
  10[#25] --< Arg(1) >--> obj.foo(...)[#30]
  obj.foo[#26] -
  foo[#28] --< V(x1) >--> foo[#29]
  foo[#29] --< P(x1) >--> 10[#25]
  obj.foo(...)[#30] --< Call >--> obj.foo[#26]
  obj.foo(...)[#30] --< D >--> $v5[#31]
  $v5[#31] -
  10[#32] --< Arg(1) >--> obj.bar(...)[#41]
  "abc"[#33] --< Arg(2) >--> obj.bar(...)[#41]
  true[#34] --< Arg(3) >--> obj.bar(...)[#41]
  obj.bar[#35] -
  baz[#37] --< V(y1) >--> baz[#38]
  baz[#38] --< P(y1) >--> 10[#32]
  baz[#38] --< V(y2) >--> baz[#39]
  baz[#39] --< P(y2) >--> "abc"[#33]
  baz[#39] --< V(y3) >--> baz[#40]
  baz[#40] --< P(y3) >--> true[#34]
  obj.bar(...)[#41] --< Call >--> obj.bar[#35]
  obj.bar(...)[#41] --< D >--> $v6[#42]
  $v6[#42] -
  10[#43] --< Arg(1) >--> obj.baz(...)[#46]
  obj.baz[#44] -
  obj.baz(...)[#46] --< Call >--> obj.baz[#44]
  obj.baz(...)[#46] --< D >--> $v7[#47]
  $v7[#47] -

Graph.js MDG Builder: week property value
  $ graphjs mdg --no-export property_value.js
  $v1[#19] --< V(foo) >--> obj[#22]
  $v1[#19] --< P(foo) >--> obj.foo[#27]
  $v2[#20] --< V(foo) >--> obj[#22]
  $v2[#20] --< P(foo) >--> obj.foo[#27]
  10[#21] -
  obj[#22] --< P(foo) >--> 10[#21]
  obj[#22] --< V(foo) >--> obj[#25]
  $v4[#23] -
  $v5[#24] -
  obj[#25] --< P(foo) >--> $v4[#23]
  obj[#25] --< P(foo) >--> $v5[#24]
  obj2[#26] --< V(bar) >--> obj2[#29]
  obj.foo[#27] -
  obj2[#29] --< P(bar) >--> $v4[#23]
  obj2[#29] --< P(bar) >--> $v5[#24]

Graph.js MDG Builder: week function call
  $ graphjs mdg --no-export function_call.js
  [[function]] $v1[#19] -
  [[function]] $v2[#20] -
  10[#21] -
  bar[#23] --< V(x1) >--> bar[#24]
  bar[#24] --< P(x1) >--> 10[#21]
  bar[#24] --< P(x1) >--> 10[#32]
  baz[#26] --< V(y1) >--> baz[#27]
  baz[#27] --< P(y1) >--> 10[#21]
  baz[#27] --< V(y2) >--> baz[#29]
  baz[#27] --< P(y1) >--> 10[#32]
  y2[#28] -
  baz[#29] --< P(y2) >--> y2[#28]
  baz[#29] --< V(y3) >--> baz[#31]
  baz[#29] --< P(y2) >--> "abc"[#33]
  y3[#30] -
  baz[#31] --< P(y3) >--> y3[#30]
  baz[#31] --< P(y3) >--> true[#34]
  10[#32] -
  "abc"[#33] -
  true[#34] -
