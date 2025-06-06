Graph.js MDG Builder: week property lookup
  $ graphjs mdg --no-export property_lookup.js
  $v1[#7] --< P(foo) >--> obj.foo[#9]
  $v1[#7] --< P(bar) >--> obj.bar[#10]
  $v1[#7] --< P(10) >--> obj.10[#12]
  $v1[#7] --< P(abc) >--> obj.abc[#13]
  $v1[#7] --< P(null) >--> obj.null[#14]
  $v2[#8] --< P(foo) >--> obj.foo[#9]
  $v2[#8] --< P(bar) >--> obj.bar[#10]
  $v2[#8] --< P(10) >--> obj.10[#12]
  $v2[#8] --< P(abc) >--> obj.abc[#13]
  $v2[#8] --< P(null) >--> obj.null[#14]
  obj.foo[#9] -
  obj.bar[#10] --< P(baz) >--> obj.bar.baz[#11]
  obj.bar.baz[#11] -
  obj.10[#12] -
  obj.abc[#13] -
  obj.null[#14] -

Graph.js MDG Builder: week property update
  $ graphjs mdg --no-export property_update.js
  $v1[#7] --< V(foo) >--> obj[#10]
  $v1[#7] --< P(bar) >--> obj.bar[#13]
  $v2[#8] --< V(foo) >--> obj[#10]
  $v2[#8] --< P(bar) >--> obj.bar[#13]
  10[#9] -
  obj[#10] --< P(foo) >--> 10[#9]
  obj[#10] --< V(bar) >--> obj[#12]
  $v3[#11] --< V(baz) >--> $v3[#15]
  obj[#12] --< P(bar) >--> $v3[#11]
  obj[#12] --< V(10) >--> obj[#17]
  obj.bar[#13] -
  10[#14] -
  $v3[#15] --< P(baz) >--> 10[#14]
  10[#16] -
  obj[#17] --< P(10) >--> 10[#16]
  obj[#17] --< V(abc) >--> obj[#19]
  10[#18] -
  obj[#19] --< P(abc) >--> 10[#18]
  obj[#19] --< V(null) >--> obj[#21]
  10[#20] -
  obj[#21] --< P(null) >--> 10[#20]

Graph.js MDG Builder: week property access
  $ graphjs mdg --no-export property_access.js
  $v1[#7] --< V(foo) >--> obj[#10]
  $v1[#7] --< P(foo) >--> obj.foo[#13]
  $v1[#7] --< P(bar) >--> obj.bar[#15]
  $v2[#8] --< V(foo) >--> obj[#10]
  $v2[#8] --< P(foo) >--> obj.foo[#13]
  $v2[#8] --< P(bar) >--> obj.bar[#15]
  10[#9] -
  obj[#10] --< P(foo) >--> 10[#9]
  obj[#10] --< V(bar) >--> obj[#12]
  $v3[#11] -
  obj[#12] --< P(bar) >--> $v3[#11]
  obj[#12] --< V(baz) >--> obj[#14]
  obj.foo[#13] -
  obj[#14] --< P(baz) >--> 10[#9]
  obj[#14] --< V(baz) >--> obj[#16]
  obj.bar[#15] -
  obj[#16] --< P(baz) >--> $v3[#11]

Graph.js MDG Builder: week method call
  $ graphjs mdg --no-export method_call.js
  $v1[#7] --< V(foo) >--> $v1[#11]
  $v1[#7] --< P(foo) >--> obj.foo[#20]
  $v1[#7] --< P(bar) >--> obj.bar[#26]
  $v1[#7] --< P(baz) >--> obj.baz[#30]
  [[function]] $v2[#8] --< Param(0) >--> this[#9]
  [[function]] $v2[#8] --< Param(1) >--> x1[#10]
  this[#9] -
  x1[#10] -
  $v1[#11] --< P(foo) >--> [[function]] $v2[#8]
  $v1[#11] --< Arg(0) >--> obj.foo(...)[#21]
  $v1[#11] --< Arg(0) >--> obj.bar(...)[#27]
  $v1[#11] --< Arg(0) >--> obj.baz(...)[#31]
  $v3[#12] --< V(bar) >--> $v3[#18]
  $v3[#12] --< P(foo) >--> obj.foo[#20]
  $v3[#12] --< P(bar) >--> obj.bar[#26]
  $v3[#12] --< P(baz) >--> obj.baz[#30]
  [[function]] $v4[#13] --< Param(0) >--> this[#14]
  [[function]] $v4[#13] --< Param(1) >--> y1[#15]
  [[function]] $v4[#13] --< Param(2) >--> y2[#16]
  [[function]] $v4[#13] --< Param(3) >--> y3[#17]
  this[#14] -
  y1[#15] -
  y2[#16] -
  y3[#17] -
  $v3[#18] --< P(bar) >--> [[function]] $v4[#13]
  $v3[#18] --< Arg(0) >--> obj.foo(...)[#21]
  $v3[#18] --< Arg(0) >--> obj.bar(...)[#27]
  $v3[#18] --< Arg(0) >--> obj.baz(...)[#31]
  10[#19] --< Arg(1) >--> obj.foo(...)[#21]
  obj.foo[#20] -
  obj.foo(...)[#21] --< Call >--> [[function]] $v2[#8]
  obj.foo(...)[#21] --< Call >--> obj.foo[#20]
  obj.foo(...)[#21] --< D >--> $v5[#22]
  $v5[#22] -
  10[#23] --< Arg(1) >--> obj.bar(...)[#27]
  "abc"[#24] --< Arg(2) >--> obj.bar(...)[#27]
  true[#25] --< Arg(3) >--> obj.bar(...)[#27]
  obj.bar[#26] -
  obj.bar(...)[#27] --< Call >--> [[function]] $v4[#13]
  obj.bar(...)[#27] --< Call >--> obj.bar[#26]
  obj.bar(...)[#27] --< D >--> $v6[#28]
  $v6[#28] -
  10[#29] --< Arg(1) >--> obj.baz(...)[#31]
  obj.baz[#30] -
  obj.baz(...)[#31] --< Call >--> obj.baz[#30]
  obj.baz(...)[#31] --< D >--> $v7[#32]
  $v7[#32] -

Graph.js MDG Builder: week property value
  $ graphjs mdg --no-export property_value.js
  $v1[#7] --< V(foo) >--> obj[#10]
  $v1[#7] --< P(foo) >--> obj.foo[#15]
  $v2[#8] --< V(foo) >--> obj[#10]
  $v2[#8] --< P(foo) >--> obj.foo[#15]
  10[#9] -
  obj[#10] --< P(foo) >--> 10[#9]
  obj[#10] --< V(foo) >--> obj[#13]
  $v4[#11] -
  $v5[#12] -
  obj[#13] --< P(foo) >--> $v4[#11]
  obj[#13] --< P(foo) >--> $v5[#12]
  obj2[#14] --< V(bar) >--> obj2[#16]
  obj.foo[#15] -
  obj2[#16] --< P(bar) >--> $v4[#11]
  obj2[#16] --< P(bar) >--> $v5[#12]

Graph.js MDG Builder: week function call
  $ graphjs mdg --no-export function_call.js
  [[function]] $v1[#7] --< Param(0) >--> this[#8]
  [[function]] $v1[#7] --< Param(1) >--> x1[#9]
  this[#8] -
  x1[#9] -
  [[function]] $v2[#10] --< Param(0) >--> this[#11]
  [[function]] $v2[#10] --< Param(1) >--> y1[#12]
  [[function]] $v2[#10] --< Param(2) >--> y2[#13]
  [[function]] $v2[#10] --< Param(3) >--> y3[#14]
  this[#11] -
  y1[#12] -
  y2[#13] -
  y3[#14] -
  10[#15] --< Arg(1) >--> foo(...)[#16]
  foo(...)[#16] --< Call >--> [[function]] $v1[#7]
  foo(...)[#16] --< Call >--> [[function]] $v2[#10]
  foo(...)[#16] --< D >--> $v3[#17]
  $v3[#17] -
  10[#18] --< Arg(1) >--> foo(...)[#21]
  "abc"[#19] --< Arg(2) >--> foo(...)[#21]
  true[#20] --< Arg(3) >--> foo(...)[#21]
  foo(...)[#21] --< Call >--> [[function]] $v1[#7]
  foo(...)[#21] --< Call >--> [[function]] $v2[#10]
  foo(...)[#21] --< D >--> $v4[#22]
  $v4[#22] -
