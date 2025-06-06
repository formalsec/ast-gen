Graph.js MDG Builder: static lookup
  $ graphjs mdg --no-export static_lookup.js
  obj[#7] --< P(foo) >--> obj.foo[#8]
  obj[#7] --< P(bar) >--> obj.bar[#9]
  obj[#7] --< P(10) >--> obj.10[#11]
  obj[#7] --< P(abc) >--> obj.abc[#12]
  obj[#7] --< P(null) >--> obj.null[#13]
  obj.foo[#8] -
  obj.bar[#9] --< P(baz) >--> obj.bar.baz[#10]
  obj.bar.baz[#10] -
  obj.10[#11] -
  obj.abc[#12] -
  obj.null[#13] -
  undef[#14] --< P(foo) >--> undef.foo[#15]
  undef.foo[#15] -

Graph.js MDG Builder: dynamic lookup
  $ graphjs mdg --no-export dynamic_lookup.js
  obj[#7] --< P(*) >--> obj.*[#9]
  foo[#8] --< D >--> obj.*[#9]
  obj.*[#9] --< P(*) >--> obj.*.*[#12]
  foo[#10] --< D >--> obj.*[#9]
  bar[#11] --< D >--> obj.*.*[#12]
  obj.*.*[#12] -
  $v4[#13] --< D >--> obj.*[#9]
  10[#14] --< D >--> $v6[#16]
  "abc"[#15] --< D >--> $v6[#16]
  $v6[#16] --< D >--> obj.*[#9]
  bar[#17] --< D >--> obj.*[#9]
  $v9[#18] --< D >--> obj.*.*[#12]
  undef[#19] --< P(*) >--> undef.*[#21]
  bar[#20] --< D >--> undef.*[#21]
  undef.*[#21] -

Graph.js MDG Builder: static update
  $ graphjs mdg --no-export static_update.js
  obj[#7] --< V(foo) >--> obj[#9]
  obj[#7] --< P(bar) >--> obj.bar[#12]
  10[#8] -
  obj[#9] --< P(foo) >--> 10[#8]
  obj[#9] --< V(bar) >--> obj[#11]
  $v1[#10] --< V(baz) >--> $v1[#14]
  obj[#11] --< P(bar) >--> $v1[#10]
  obj[#11] --< V(10) >--> obj[#16]
  obj.bar[#12] -
  10[#13] -
  $v1[#14] --< P(baz) >--> 10[#13]
  10[#15] -
  obj[#16] --< P(10) >--> 10[#15]
  obj[#16] --< V(abc) >--> obj[#18]
  10[#17] -
  obj[#18] --< P(abc) >--> 10[#17]
  obj[#18] --< V(null) >--> obj[#20]
  10[#19] -
  obj[#20] --< P(null) >--> 10[#19]
  undef[#21] --< V(foo) >--> undef[#23]
  10[#22] -
  undef[#23] --< P(foo) >--> 10[#22]

Graph.js MDG Builder: dynamic update
  $ graphjs mdg --no-export dynamic_update.js
  obj[#7] --< V(*) >--> obj[#10]
  obj[#7] --< P(*) >--> obj.*[#15]
  foo[#8] --< D >--> obj[#10]
  10[#9] --< V(*) >--> $v2[#18]
  obj[#10] --< P(*) >--> 10[#9]
  obj[#10] --< V(*) >--> obj[#13]
  $v1[#11] --< V(*) >--> $v2[#18]
  bar[#12] --< D >--> obj[#13]
  obj[#13] --< P(*) >--> $v1[#11]
  obj[#13] --< V(*) >--> obj[#21]
  foo[#14] --< D >--> obj.*[#15]
  obj.*[#15] --< V(*) >--> $v2[#18]
  bar[#16] --< D >--> $v2[#18]
  10[#17] -
  $v2[#18] --< P(*) >--> 10[#17]
  $v2[#18] --< V(*) >--> $v5[#30]
  $v3[#19] --< D >--> obj[#21]
  10[#20] --< V(*) >--> $v5[#30]
  obj[#21] --< P(*) >--> 10[#20]
  obj[#21] --< V(*) >--> obj[#26]
  10[#22] --< D >--> $v4[#24]
  "abc"[#23] --< D >--> $v4[#24]
  $v4[#24] --< D >--> obj[#26]
  true[#25] --< V(*) >--> $v5[#30]
  obj[#26] --< P(*) >--> true[#25]
  baz[#27] --< D >--> obj.*[#15]
  $v6[#28] --< D >--> $v5[#30]
  10[#29] -
  $v5[#30] --< P(*) >--> 10[#29]
  undef[#31] --< V(*) >--> undef[#34]
  foo[#32] --< D >--> undef[#34]
  10[#33] -
  undef[#34] --< P(*) >--> 10[#33]

Graph.js MDG Builder: static access
  $ graphjs mdg --no-export static_access.js
  obj[#7] --< V(foo) >--> obj[#9]
  obj[#7] --< P(baz) >--> obj.baz[#12]
  obj[#7] --< P(foo) >--> obj.foo[#15]
  obj[#7] --< P(bar) >--> obj.bar[#17]
  10[#8] -
  obj[#9] --< P(foo) >--> 10[#8]
  obj[#9] --< V(bar) >--> obj[#11]
  $v1[#10] -
  obj[#11] --< P(bar) >--> $v1[#10]
  obj[#11] --< V(qux) >--> obj[#16]
  obj.baz[#12] --< V(p) >--> obj.baz[#14]
  10[#13] -
  obj.baz[#14] --< P(p) >--> 10[#13]
  obj.foo[#15] -
  obj[#16] --< P(qux) >--> 10[#8]
  obj[#16] --< V(qux) >--> obj[#18]
  obj.bar[#17] -
  obj[#18] --< P(qux) >--> $v1[#10]

Graph.js MDG Builder: dynamic access
  $ graphjs mdg --no-export dynamic_access.js
  obj[#7] --< V(*) >--> obj[#10]
  obj[#7] --< P(*) >--> obj.*[#15]
  foo[#8] --< D >--> obj[#10]
  10[#9] --< V(*) >--> $v2[#18]
  obj[#10] --< P(*) >--> 10[#9]
  obj[#10] --< V(*) >--> obj[#13]
  $v1[#11] --< V(*) >--> $v2[#18]
  bar[#12] --< D >--> obj[#13]
  obj[#13] --< P(*) >--> $v1[#11]
  obj[#13] --< V(*) >--> obj[#21]
  baz[#14] --< D >--> obj.*[#15]
  obj.*[#15] --< V(*) >--> $v2[#18]
  p[#16] --< D >--> $v2[#18]
  10[#17] -
  $v2[#18] --< P(*) >--> 10[#17]
  foo[#19] --< D >--> obj.*[#15]
  qux[#20] --< D >--> obj[#21]
  obj[#21] --< P(*) >--> $v2[#18]
  obj[#21] --< V(*) >--> obj[#24]
  bar[#22] --< D >--> obj.*[#15]
  qux[#23] --< D >--> obj[#24]
  obj[#24] --< P(*) >--> $v2[#18]

Graph.js MDG Builder: static method
  $ graphjs mdg --no-export static_method.js
  obj[#7] --< V(foo) >--> obj[#11]
  obj[#7] --< P(foo) >--> obj.foo[#19]
  obj[#7] --< P(bar) >--> obj.bar[#25]
  obj[#7] --< P(baz) >--> obj.baz[#29]
  [[function]] $v1[#8] --< Param(0) >--> this[#9]
  [[function]] $v1[#8] --< Param(1) >--> x1[#10]
  this[#9] -
  x1[#10] -
  obj[#11] --< P(foo) >--> [[function]] $v1[#8]
  obj[#11] --< V(bar) >--> obj[#17]
  [[function]] $v2[#12] --< Param(0) >--> this[#13]
  [[function]] $v2[#12] --< Param(1) >--> y1[#14]
  [[function]] $v2[#12] --< Param(2) >--> y2[#15]
  [[function]] $v2[#12] --< Param(3) >--> y3[#16]
  this[#13] -
  y1[#14] -
  y2[#15] -
  y3[#16] -
  obj[#17] --< P(bar) >--> [[function]] $v2[#12]
  obj[#17] --< Arg(0) >--> obj.foo(...)[#20]
  obj[#17] --< Arg(0) >--> obj.bar(...)[#26]
  obj[#17] --< Arg(0) >--> obj.baz(...)[#30]
  10[#18] --< Arg(1) >--> obj.foo(...)[#20]
  obj.foo[#19] -
  obj.foo(...)[#20] --< Call >--> [[function]] $v1[#8]
  obj.foo(...)[#20] --< D >--> $v3[#21]
  $v3[#21] -
  10[#22] --< Arg(1) >--> obj.bar(...)[#26]
  "abc"[#23] --< Arg(2) >--> obj.bar(...)[#26]
  true[#24] --< Arg(3) >--> obj.bar(...)[#26]
  obj.bar[#25] -
  obj.bar(...)[#26] --< Call >--> [[function]] $v2[#12]
  obj.bar(...)[#26] --< D >--> $v4[#27]
  $v4[#27] -
  10[#28] --< Arg(1) >--> obj.baz(...)[#30]
  obj.baz[#29] -
  obj.baz(...)[#30] --< Call >--> obj.baz[#29]
  obj.baz(...)[#30] --< D >--> $v5[#31]
  $v5[#31] -
  undef[#32] --< P(foo) >--> undef.foo[#33]
  undef.foo[#33] -

Graph.js MDG Builder: dynamic method
  $ graphjs mdg --no-export dynamic_method.js
  obj[#7] --< V(foo) >--> obj[#11]
  obj[#7] --< P(*) >--> foo[#18]
  [[function]] $v1[#8] --< Param(0) >--> this[#9]
  [[function]] $v1[#8] --< Param(1) >--> x1[#10]
  [[function]] $v1[#8] --< P(*) >--> $v9.*[#41]
  [[function]] $v1[#8] --< Arg(0) >--> $v9.*(...)[#42]
  this[#9] -
  x1[#10] -
  obj[#11] --< P(foo) >--> [[function]] $v1[#8]
  obj[#11] --< V(bar) >--> obj[#17]
  [[function]] $v2[#12] --< Param(0) >--> this[#13]
  [[function]] $v2[#12] --< Param(1) >--> y1[#14]
  [[function]] $v2[#12] --< Param(2) >--> y2[#15]
  [[function]] $v2[#12] --< Param(3) >--> y3[#16]
  [[function]] $v2[#12] --< P(*) >--> $v9.*[#41]
  [[function]] $v2[#12] --< Arg(0) >--> $v9.*(...)[#42]
  this[#13] -
  y1[#14] -
  y2[#15] -
  y3[#16] -
  obj[#17] --< P(bar) >--> [[function]] $v2[#12]
  obj[#17] --< Arg(0) >--> obj.*(...)[#20]
  obj[#17] --< Arg(0) >--> obj.*(...)[#26]
  obj[#17] --< Arg(0) >--> obj.*(...)[#30]
  obj[#17] --< Arg(0) >--> obj.*(...)[#36]
  foo[#18] --< D >--> foo[#18]
  foo[#18] --< P(*) >--> $v9.*[#41]
  foo[#18] --< Arg(0) >--> $v9.*(...)[#42]
  10[#19] --< Arg(1) >--> obj.*(...)[#20]
  obj.*(...)[#20] --< Call >--> [[function]] $v1[#8]
  obj.*(...)[#20] --< Call >--> [[function]] $v2[#12]
  obj.*(...)[#20] --< Call >--> foo[#18]
  obj.*(...)[#20] --< D >--> $v3[#21]
  $v3[#21] -
  bar[#22] --< D >--> foo[#18]
  10[#23] --< Arg(1) >--> obj.*(...)[#26]
  "abc"[#24] --< Arg(2) >--> obj.*(...)[#26]
  true[#25] --< Arg(3) >--> obj.*(...)[#26]
  obj.*(...)[#26] --< Call >--> [[function]] $v1[#8]
  obj.*(...)[#26] --< Call >--> [[function]] $v2[#12]
  obj.*(...)[#26] --< Call >--> foo[#18]
  obj.*(...)[#26] --< D >--> $v4[#27]
  $v4[#27] -
  $v5[#28] --< D >--> foo[#18]
  10[#29] --< Arg(1) >--> obj.*(...)[#30]
  obj.*(...)[#30] --< Call >--> [[function]] $v1[#8]
  obj.*(...)[#30] --< Call >--> [[function]] $v2[#12]
  obj.*(...)[#30] --< Call >--> foo[#18]
  obj.*(...)[#30] --< D >--> $v6[#31]
  $v6[#31] -
  10[#32] --< D >--> $v7[#34]
  "abc"[#33] --< D >--> $v7[#34]
  $v7[#34] --< D >--> foo[#18]
  true[#35] --< Arg(1) >--> obj.*(...)[#36]
  obj.*(...)[#36] --< Call >--> [[function]] $v1[#8]
  obj.*(...)[#36] --< Call >--> [[function]] $v2[#12]
  obj.*(...)[#36] --< Call >--> foo[#18]
  obj.*(...)[#36] --< D >--> $v8[#37]
  $v8[#37] -
  baz[#38] --< D >--> foo[#18]
  $v10[#39] --< D >--> $v9.*[#41]
  10[#40] --< Arg(1) >--> $v9.*(...)[#42]
  $v9.*[#41] -
  $v9.*(...)[#42] --< Call >--> $v9.*[#41]
  $v9.*(...)[#42] --< D >--> $v11[#43]
  $v11[#43] -
  undef[#44] --< P(*) >--> undef.*[#46]
  bar[#45] --< D >--> undef.*[#46]
  undef.*[#46] -
