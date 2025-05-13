Graph.js MDG Builder: week property lookup
  $ graphjs mdg --no-export property_lookup.js
  $v1[#9] --< P(foo) >--> obj.foo[#11]
  $v1[#9] --< P(bar) >--> obj.bar[#12]
  $v1[#9] --< P(10) >--> obj.10[#14]
  $v1[#9] --< P(abc) >--> obj.abc[#15]
  $v1[#9] --< P(null) >--> obj.null[#16]
  $v2[#10] --< P(foo) >--> obj.foo[#11]
  $v2[#10] --< P(bar) >--> obj.bar[#12]
  $v2[#10] --< P(10) >--> obj.10[#14]
  $v2[#10] --< P(abc) >--> obj.abc[#15]
  $v2[#10] --< P(null) >--> obj.null[#16]
  obj.foo[#11] -
  obj.bar[#12] --< P(baz) >--> obj.bar.baz[#13]
  obj.bar.baz[#13] -
  obj.10[#14] -
  obj.abc[#15] -
  obj.null[#16] -

Graph.js MDG Builder: week property update
  $ graphjs mdg --no-export property_update.js
  $v1[#9] --< V(foo) >--> obj[#12]
  $v1[#9] --< P(bar) >--> obj.bar[#15]
  $v2[#10] --< V(foo) >--> obj[#12]
  $v2[#10] --< P(bar) >--> obj.bar[#15]
  10[#11] -
  obj[#12] --< P(foo) >--> 10[#11]
  obj[#12] --< V(bar) >--> obj[#14]
  $v3[#13] --< V(baz) >--> $v3[#17]
  obj[#14] --< P(bar) >--> $v3[#13]
  obj[#14] --< V(10) >--> obj[#19]
  obj.bar[#15] -
  10[#16] -
  $v3[#17] --< P(baz) >--> 10[#16]
  10[#18] -
  obj[#19] --< P(10) >--> 10[#18]
  obj[#19] --< V(abc) >--> obj[#21]
  10[#20] -
  obj[#21] --< P(abc) >--> 10[#20]
  obj[#21] --< V(null) >--> obj[#23]
  10[#22] -
  obj[#23] --< P(null) >--> 10[#22]

Graph.js MDG Builder: week property access
  $ graphjs mdg --no-export property_access.js
  $v1[#9] --< V(foo) >--> obj[#12]
  $v1[#9] --< P(foo) >--> obj.foo[#15]
  $v1[#9] --< P(bar) >--> obj.bar[#17]
  $v2[#10] --< V(foo) >--> obj[#12]
  $v2[#10] --< P(foo) >--> obj.foo[#15]
  $v2[#10] --< P(bar) >--> obj.bar[#17]
  10[#11] -
  obj[#12] --< P(foo) >--> 10[#11]
  obj[#12] --< V(bar) >--> obj[#14]
  $v3[#13] -
  obj[#14] --< P(bar) >--> $v3[#13]
  obj[#14] --< V(baz) >--> obj[#16]
  obj.foo[#15] -
  obj[#16] --< P(baz) >--> 10[#11]
  obj[#16] --< V(baz) >--> obj[#18]
  obj.bar[#17] -
  obj[#18] --< P(baz) >--> $v3[#13]

Graph.js MDG Builder: week method call
  $ graphjs mdg --no-export method_call.js
  $v1[#9] --< V(foo) >--> $v1[#13]
  $v1[#9] --< P(foo) >--> obj.foo[#22]
  $v1[#9] --< P(bar) >--> obj.bar[#28]
  $v1[#9] --< P(baz) >--> obj.baz[#32]
  [[function]] $v2[#10] --< Param(0) >--> this[#11]
  [[function]] $v2[#10] --< Param(1) >--> x1[#12]
  this[#11] -
  x1[#12] -
  $v1[#13] --< P(foo) >--> [[function]] $v2[#10]
  $v1[#13] --< Arg(0) >--> obj.foo(...)[#23]
  $v1[#13] --< Arg(0) >--> obj.bar(...)[#29]
  $v1[#13] --< Arg(0) >--> obj.baz(...)[#33]
  $v3[#14] --< V(bar) >--> $v3[#20]
  $v3[#14] --< P(foo) >--> obj.foo[#22]
  $v3[#14] --< P(bar) >--> obj.bar[#28]
  $v3[#14] --< P(baz) >--> obj.baz[#32]
  [[function]] $v4[#15] --< Param(0) >--> this[#16]
  [[function]] $v4[#15] --< Param(1) >--> y1[#17]
  [[function]] $v4[#15] --< Param(2) >--> y2[#18]
  [[function]] $v4[#15] --< Param(3) >--> y3[#19]
  this[#16] -
  y1[#17] -
  y2[#18] -
  y3[#19] -
  $v3[#20] --< P(bar) >--> [[function]] $v4[#15]
  $v3[#20] --< Arg(0) >--> obj.foo(...)[#23]
  $v3[#20] --< Arg(0) >--> obj.bar(...)[#29]
  $v3[#20] --< Arg(0) >--> obj.baz(...)[#33]
  10[#21] --< Arg(1) >--> obj.foo(...)[#23]
  obj.foo[#22] -
  obj.foo(...)[#23] --< Call >--> [[function]] $v2[#10]
  obj.foo(...)[#23] --< Call >--> obj.foo[#22]
  obj.foo(...)[#23] --< D >--> $v5[#24]
  $v5[#24] -
  10[#25] --< Arg(1) >--> obj.bar(...)[#29]
  "abc"[#26] --< Arg(2) >--> obj.bar(...)[#29]
  true[#27] --< Arg(3) >--> obj.bar(...)[#29]
  obj.bar[#28] -
  obj.bar(...)[#29] --< Call >--> [[function]] $v4[#15]
  obj.bar(...)[#29] --< Call >--> obj.bar[#28]
  obj.bar(...)[#29] --< D >--> $v6[#30]
  $v6[#30] -
  10[#31] --< Arg(1) >--> obj.baz(...)[#33]
  obj.baz[#32] -
  obj.baz(...)[#33] --< Call >--> obj.baz[#32]
  obj.baz(...)[#33] --< D >--> $v7[#34]
  $v7[#34] -

Graph.js MDG Builder: week property value
  $ graphjs mdg --no-export property_value.js
  $v1[#9] --< V(foo) >--> obj[#12]
  $v1[#9] --< P(foo) >--> obj.foo[#17]
  $v2[#10] --< V(foo) >--> obj[#12]
  $v2[#10] --< P(foo) >--> obj.foo[#17]
  10[#11] -
  obj[#12] --< P(foo) >--> 10[#11]
  obj[#12] --< V(foo) >--> obj[#15]
  $v4[#13] -
  $v5[#14] -
  obj[#15] --< P(foo) >--> $v4[#13]
  obj[#15] --< P(foo) >--> $v5[#14]
  obj2[#16] --< V(bar) >--> obj2[#18]
  obj.foo[#17] -
  obj2[#18] --< P(bar) >--> $v4[#13]
  obj2[#18] --< P(bar) >--> $v5[#14]

Graph.js MDG Builder: week function call
  $ graphjs mdg --no-export function_call.js
  [[function]] $v1[#9] --< Param(0) >--> this[#10]
  [[function]] $v1[#9] --< Param(1) >--> x1[#11]
  this[#10] -
  x1[#11] -
  [[function]] $v2[#12] --< Param(0) >--> this[#13]
  [[function]] $v2[#12] --< Param(1) >--> y1[#14]
  [[function]] $v2[#12] --< Param(2) >--> y2[#15]
  [[function]] $v2[#12] --< Param(3) >--> y3[#16]
  this[#13] -
  y1[#14] -
  y2[#15] -
  y3[#16] -
  10[#17] --< Arg(1) >--> foo(...)[#18]
  foo(...)[#18] --< Call >--> [[function]] $v1[#9]
  foo(...)[#18] --< Call >--> [[function]] $v2[#12]
  foo(...)[#18] --< D >--> $v3[#19]
  $v3[#19] -
  10[#20] --< Arg(1) >--> foo(...)[#23]
  "abc"[#21] --< Arg(2) >--> foo(...)[#23]
  true[#22] --< Arg(3) >--> foo(...)[#23]
  foo(...)[#23] --< Call >--> [[function]] $v1[#9]
  foo(...)[#23] --< Call >--> [[function]] $v2[#12]
  foo(...)[#23] --< D >--> $v4[#24]
  $v4[#24] -
