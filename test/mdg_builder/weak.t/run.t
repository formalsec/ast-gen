  $ graphjs mdg --no-export property_lookup.js
  $v1[#10] --< P(foo) >--> obj.foo[#12]
  $v1[#10] --< P(bar) >--> obj.bar[#13]
  $v1[#10] --< P(10) >--> obj.10[#15]
  $v1[#10] --< P(abc) >--> obj.abc[#16]
  $v1[#10] --< P(null) >--> obj.null[#17]
  $v2[#11] --< P(foo) >--> obj.foo[#12]
  $v2[#11] --< P(bar) >--> obj.bar[#13]
  $v2[#11] --< P(10) >--> obj.10[#15]
  $v2[#11] --< P(abc) >--> obj.abc[#16]
  $v2[#11] --< P(null) >--> obj.null[#17]
  obj.foo[#12] -
  obj.bar[#13] --< P(baz) >--> obj.bar.baz[#14]
  obj.bar.baz[#14] -
  obj.10[#15] -
  obj.abc[#16] -
  obj.null[#17] -

  $ graphjs mdg --no-export property_update.js
  $v1[#10] --< V(foo) >--> obj[#13]
  $v1[#10] --< P(bar) >--> obj.bar[#16]
  $v2[#11] --< V(foo) >--> obj[#13]
  $v2[#11] --< P(bar) >--> obj.bar[#16]
  10[#12] -
  obj[#13] --< P(foo) >--> 10[#12]
  obj[#13] --< V(bar) >--> obj[#15]
  $v3[#14] --< V(baz) >--> $v3[#18]
  obj[#15] --< P(bar) >--> $v3[#14]
  obj[#15] --< V(10) >--> obj[#20]
  obj.bar[#16] -
  10[#17] -
  $v3[#18] --< P(baz) >--> 10[#17]
  10[#19] -
  obj[#20] --< P(10) >--> 10[#19]
  obj[#20] --< V(abc) >--> obj[#22]
  10[#21] -
  obj[#22] --< P(abc) >--> 10[#21]
  obj[#22] --< V(null) >--> obj[#24]
  10[#23] -
  obj[#24] --< P(null) >--> 10[#23]

  $ graphjs mdg --no-export property_access.js
  $v1[#10] --< V(foo) >--> obj[#13]
  $v1[#10] --< P(foo) >--> obj.foo[#16]
  $v1[#10] --< P(bar) >--> obj.bar[#18]
  $v2[#11] --< V(foo) >--> obj[#13]
  $v2[#11] --< P(foo) >--> obj.foo[#16]
  $v2[#11] --< P(bar) >--> obj.bar[#18]
  10[#12] -
  obj[#13] --< P(foo) >--> 10[#12]
  obj[#13] --< V(bar) >--> obj[#15]
  $v3[#14] -
  obj[#15] --< P(bar) >--> $v3[#14]
  obj[#15] --< V(baz) >--> obj[#17]
  obj.foo[#16] -
  obj[#17] --< P(baz) >--> 10[#12]
  obj[#17] --< V(baz) >--> obj[#19]
  obj.bar[#18] -
  obj[#19] --< P(baz) >--> $v3[#14]

  $ graphjs mdg --no-export method_call.js
  $v1[#10] --< V(foo) >--> $v1[#14]
  $v1[#10] --< P(foo) >--> obj.foo[#23]
  $v1[#10] --< P(bar) >--> obj.bar[#29]
  $v1[#10] --< P(baz) >--> obj.baz[#33]
  $v2[#11] --< Param(0) >--> this[#12]
  $v2[#11] --< Param(1) >--> x1[#13]
  this[#12] -
  x1[#13] -
  $v1[#14] --< P(foo) >--> $v2[#11]
  $v1[#14] --< Arg(0) >--> obj.foo(...)[#24]
  $v1[#14] --< Arg(0) >--> obj.bar(...)[#30]
  $v1[#14] --< Arg(0) >--> obj.baz(...)[#34]
  $v3[#15] --< V(bar) >--> $v3[#21]
  $v3[#15] --< P(foo) >--> obj.foo[#23]
  $v3[#15] --< P(bar) >--> obj.bar[#29]
  $v3[#15] --< P(baz) >--> obj.baz[#33]
  $v4[#16] --< Param(0) >--> this[#17]
  $v4[#16] --< Param(1) >--> y1[#18]
  $v4[#16] --< Param(2) >--> y2[#19]
  $v4[#16] --< Param(3) >--> y3[#20]
  this[#17] -
  y1[#18] -
  y2[#19] -
  y3[#20] -
  $v3[#21] --< P(bar) >--> $v4[#16]
  $v3[#21] --< Arg(0) >--> obj.foo(...)[#24]
  $v3[#21] --< Arg(0) >--> obj.bar(...)[#30]
  $v3[#21] --< Arg(0) >--> obj.baz(...)[#34]
  10[#22] --< Arg(1) >--> obj.foo(...)[#24]
  obj.foo[#23] -
  obj.foo(...)[#24] --< Call >--> $v2[#11]
  obj.foo(...)[#24] --< Call >--> obj.foo[#23]
  obj.foo(...)[#24] --< D >--> $v5[#25]
  $v5[#25] -
  10[#26] --< Arg(1) >--> obj.bar(...)[#30]
  "abc"[#27] --< Arg(2) >--> obj.bar(...)[#30]
  true[#28] --< Arg(3) >--> obj.bar(...)[#30]
  obj.bar[#29] -
  obj.bar(...)[#30] --< Call >--> $v4[#16]
  obj.bar(...)[#30] --< Call >--> obj.bar[#29]
  obj.bar(...)[#30] --< D >--> $v6[#31]
  $v6[#31] -
  10[#32] --< Arg(1) >--> obj.baz(...)[#34]
  obj.baz[#33] -
  obj.baz(...)[#34] --< Call >--> obj.baz[#33]
  obj.baz(...)[#34] --< D >--> $v7[#35]
  $v7[#35] -

  $ graphjs mdg --no-export property_value.js
  $v1[#10] --< V(foo) >--> obj[#13]
  $v1[#10] --< P(foo) >--> obj.foo[#18]
  $v2[#11] --< V(foo) >--> obj[#13]
  $v2[#11] --< P(foo) >--> obj.foo[#18]
  10[#12] -
  obj[#13] --< P(foo) >--> 10[#12]
  obj[#13] --< V(foo) >--> obj[#16]
  $v4[#14] -
  $v5[#15] -
  obj[#16] --< P(foo) >--> $v4[#14]
  obj[#16] --< P(foo) >--> $v5[#15]
  obj2[#17] --< V(bar) >--> obj2[#19]
  obj.foo[#18] -
  obj2[#19] --< P(bar) >--> $v4[#14]
  obj2[#19] --< P(bar) >--> $v5[#15]

  $ graphjs mdg --no-export function_call.js
  $v1[#10] --< Param(0) >--> this[#11]
  $v1[#10] --< Param(1) >--> x1[#12]
  this[#11] -
  x1[#12] -
  $v2[#13] --< Param(0) >--> this[#14]
  $v2[#13] --< Param(1) >--> y1[#15]
  $v2[#13] --< Param(2) >--> y2[#16]
  $v2[#13] --< Param(3) >--> y3[#17]
  this[#14] -
  y1[#15] -
  y2[#16] -
  y3[#17] -
  10[#18] --< Arg(1) >--> foo(...)[#19]
  foo(...)[#19] --< Call >--> $v1[#10]
  foo(...)[#19] --< Call >--> $v2[#13]
  foo(...)[#19] --< D >--> $v3[#20]
  $v3[#20] -
  10[#21] --< Arg(1) >--> foo(...)[#24]
  "abc"[#22] --< Arg(2) >--> foo(...)[#24]
  true[#23] --< Arg(3) >--> foo(...)[#24]
  foo(...)[#24] --< Call >--> $v1[#10]
  foo(...)[#24] --< Call >--> $v2[#13]
  foo(...)[#24] --< D >--> $v4[#25]
  $v4[#25] -
