  $ graphjs mdg --no-export property_lookup.js
  $v1[#11] --< P(foo) >--> obj.foo[#13]
  $v1[#11] --< P(bar) >--> obj.bar[#14]
  $v1[#11] --< P(10) >--> obj.10[#16]
  $v1[#11] --< P(abc) >--> obj.abc[#17]
  $v1[#11] --< P(null) >--> obj.null[#18]
  $v2[#12] --< P(foo) >--> obj.foo[#13]
  $v2[#12] --< P(bar) >--> obj.bar[#14]
  $v2[#12] --< P(10) >--> obj.10[#16]
  $v2[#12] --< P(abc) >--> obj.abc[#17]
  $v2[#12] --< P(null) >--> obj.null[#18]
  obj.foo[#13] -
  obj.bar[#14] --< P(baz) >--> obj.bar.baz[#15]
  obj.bar.baz[#15] -
  obj.10[#16] -
  obj.abc[#17] -
  obj.null[#18] -

  $ graphjs mdg --no-export property_update.js
  $v1[#11] --< V(foo) >--> obj[#14]
  $v1[#11] --< P(bar) >--> obj.bar[#17]
  $v2[#12] --< V(foo) >--> obj[#14]
  $v2[#12] --< P(bar) >--> obj.bar[#17]
  10[#13] -
  obj[#14] --< P(foo) >--> 10[#13]
  obj[#14] --< V(bar) >--> obj[#16]
  $v3[#15] --< V(baz) >--> $v3[#19]
  obj[#16] --< P(bar) >--> $v3[#15]
  obj[#16] --< V(10) >--> obj[#21]
  obj.bar[#17] -
  10[#18] -
  $v3[#19] --< P(baz) >--> 10[#18]
  10[#20] -
  obj[#21] --< P(10) >--> 10[#20]
  obj[#21] --< V(abc) >--> obj[#23]
  10[#22] -
  obj[#23] --< P(abc) >--> 10[#22]
  obj[#23] --< V(null) >--> obj[#25]
  10[#24] -
  obj[#25] --< P(null) >--> 10[#24]

  $ graphjs mdg --no-export property_access.js
  $v1[#11] --< V(foo) >--> obj[#14]
  $v1[#11] --< P(foo) >--> obj.foo[#17]
  $v1[#11] --< P(bar) >--> obj.bar[#19]
  $v2[#12] --< V(foo) >--> obj[#14]
  $v2[#12] --< P(foo) >--> obj.foo[#17]
  $v2[#12] --< P(bar) >--> obj.bar[#19]
  10[#13] -
  obj[#14] --< P(foo) >--> 10[#13]
  obj[#14] --< V(bar) >--> obj[#16]
  $v3[#15] -
  obj[#16] --< P(bar) >--> $v3[#15]
  obj[#16] --< V(baz) >--> obj[#18]
  obj.foo[#17] -
  obj[#18] --< P(baz) >--> 10[#13]
  obj[#18] --< V(baz) >--> obj[#20]
  obj.bar[#19] -
  obj[#20] --< P(baz) >--> $v3[#15]

  $ graphjs mdg --no-export method_call.js
  $v1[#11] --< V(foo) >--> $v1[#15]
  $v1[#11] --< P(foo) >--> obj.foo[#24]
  $v1[#11] --< P(bar) >--> obj.bar[#30]
  $v1[#11] --< P(baz) >--> obj.baz[#34]
  $v2[#12] --< Param(0) >--> this[#13]
  $v2[#12] --< Param(1) >--> x1[#14]
  this[#13] -
  x1[#14] -
  $v1[#15] --< P(foo) >--> $v2[#12]
  $v1[#15] --< Arg(0) >--> obj.foo(...)[#25]
  $v1[#15] --< Arg(0) >--> obj.bar(...)[#31]
  $v1[#15] --< Arg(0) >--> obj.baz(...)[#35]
  $v3[#16] --< V(bar) >--> $v3[#22]
  $v3[#16] --< P(foo) >--> obj.foo[#24]
  $v3[#16] --< P(bar) >--> obj.bar[#30]
  $v3[#16] --< P(baz) >--> obj.baz[#34]
  $v4[#17] --< Param(0) >--> this[#18]
  $v4[#17] --< Param(1) >--> y1[#19]
  $v4[#17] --< Param(2) >--> y2[#20]
  $v4[#17] --< Param(3) >--> y3[#21]
  this[#18] -
  y1[#19] -
  y2[#20] -
  y3[#21] -
  $v3[#22] --< P(bar) >--> $v4[#17]
  $v3[#22] --< Arg(0) >--> obj.foo(...)[#25]
  $v3[#22] --< Arg(0) >--> obj.bar(...)[#31]
  $v3[#22] --< Arg(0) >--> obj.baz(...)[#35]
  10[#23] --< Arg(1) >--> obj.foo(...)[#25]
  obj.foo[#24] -
  obj.foo(...)[#25] --< Call >--> $v2[#12]
  obj.foo(...)[#25] --< Call >--> obj.foo[#24]
  obj.foo(...)[#25] --< D >--> $v5[#26]
  $v5[#26] -
  10[#27] --< Arg(1) >--> obj.bar(...)[#31]
  "abc"[#28] --< Arg(2) >--> obj.bar(...)[#31]
  true[#29] --< Arg(3) >--> obj.bar(...)[#31]
  obj.bar[#30] -
  obj.bar(...)[#31] --< Call >--> $v4[#17]
  obj.bar(...)[#31] --< Call >--> obj.bar[#30]
  obj.bar(...)[#31] --< D >--> $v6[#32]
  $v6[#32] -
  10[#33] --< Arg(1) >--> obj.baz(...)[#35]
  obj.baz[#34] -
  obj.baz(...)[#35] --< Call >--> obj.baz[#34]
  obj.baz(...)[#35] --< D >--> $v7[#36]
  $v7[#36] -

  $ graphjs mdg --no-export property_value.js
  $v1[#11] --< V(foo) >--> obj[#14]
  $v1[#11] --< P(foo) >--> obj.foo[#19]
  $v2[#12] --< V(foo) >--> obj[#14]
  $v2[#12] --< P(foo) >--> obj.foo[#19]
  10[#13] -
  obj[#14] --< P(foo) >--> 10[#13]
  obj[#14] --< V(foo) >--> obj[#17]
  $v4[#15] -
  $v5[#16] -
  obj[#17] --< P(foo) >--> $v4[#15]
  obj[#17] --< P(foo) >--> $v5[#16]
  obj2[#18] --< V(bar) >--> obj2[#20]
  obj.foo[#19] -
  obj2[#20] --< P(bar) >--> $v4[#15]
  obj2[#20] --< P(bar) >--> $v5[#16]

  $ graphjs mdg --no-export function_call.js
  $v1[#11] --< Param(0) >--> this[#12]
  $v1[#11] --< Param(1) >--> x1[#13]
  this[#12] -
  x1[#13] -
  $v2[#14] --< Param(0) >--> this[#15]
  $v2[#14] --< Param(1) >--> y1[#16]
  $v2[#14] --< Param(2) >--> y2[#17]
  $v2[#14] --< Param(3) >--> y3[#18]
  this[#15] -
  y1[#16] -
  y2[#17] -
  y3[#18] -
  10[#19] --< Arg(1) >--> foo(...)[#20]
  foo(...)[#20] --< Call >--> $v1[#11]
  foo(...)[#20] --< Call >--> $v2[#14]
  foo(...)[#20] --< D >--> $v3[#21]
  $v3[#21] -
  10[#22] --< Arg(1) >--> foo(...)[#25]
  "abc"[#23] --< Arg(2) >--> foo(...)[#25]
  true[#24] --< Arg(3) >--> foo(...)[#25]
  foo(...)[#25] --< Call >--> $v1[#11]
  foo(...)[#25] --< Call >--> $v2[#14]
  foo(...)[#25] --< D >--> $v4[#26]
  $v4[#26] -
