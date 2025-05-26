Graph.js MDG Builder: static lookup
  $ graphjs mdg --no-export static_lookup.js
  obj[#10] --< P(foo) >--> obj.foo[#11]
  obj[#10] --< P(bar) >--> obj.bar[#12]
  obj[#10] --< P(10) >--> obj.10[#14]
  obj[#10] --< P(abc) >--> obj.abc[#15]
  obj[#10] --< P(null) >--> obj.null[#16]
  obj.foo[#11] -
  obj.bar[#12] --< P(baz) >--> obj.bar.baz[#13]
  obj.bar.baz[#13] -
  obj.10[#14] -
  obj.abc[#15] -
  obj.null[#16] -
  undef[#17] --< P(foo) >--> undef.foo[#18]
  undef.foo[#18] -

Graph.js MDG Builder: dynamic lookup
  $ graphjs mdg --no-export dynamic_lookup.js
  obj[#10] --< P(*) >--> obj.*[#12]
  foo[#11] --< D >--> obj.*[#12]
  obj.*[#12] --< P(*) >--> obj.*.*[#15]
  foo[#13] --< D >--> obj.*[#12]
  bar[#14] --< D >--> obj.*.*[#15]
  obj.*.*[#15] -
  $v4[#16] --< D >--> obj.*[#12]
  10[#17] --< D >--> $v6[#19]
  "abc"[#18] --< D >--> $v6[#19]
  $v6[#19] --< D >--> obj.*[#12]
  bar[#20] --< D >--> obj.*[#12]
  $v9[#21] --< D >--> obj.*.*[#15]
  undef[#22] --< P(*) >--> undef.*[#24]
  bar[#23] --< D >--> undef.*[#24]
  undef.*[#24] -

Graph.js MDG Builder: static update
  $ graphjs mdg --no-export static_update.js
  obj[#10] --< V(foo) >--> obj[#12]
  obj[#10] --< P(bar) >--> obj.bar[#15]
  10[#11] -
  obj[#12] --< P(foo) >--> 10[#11]
  obj[#12] --< V(bar) >--> obj[#14]
  $v1[#13] --< V(baz) >--> $v1[#17]
  obj[#14] --< P(bar) >--> $v1[#13]
  obj[#14] --< V(10) >--> obj[#19]
  obj.bar[#15] -
  10[#16] -
  $v1[#17] --< P(baz) >--> 10[#16]
  10[#18] -
  obj[#19] --< P(10) >--> 10[#18]
  obj[#19] --< V(abc) >--> obj[#21]
  10[#20] -
  obj[#21] --< P(abc) >--> 10[#20]
  obj[#21] --< V(null) >--> obj[#23]
  10[#22] -
  obj[#23] --< P(null) >--> 10[#22]
  undef[#24] --< V(foo) >--> undef[#26]
  10[#25] -
  undef[#26] --< P(foo) >--> 10[#25]

Graph.js MDG Builder: dynamic update
  $ graphjs mdg --no-export dynamic_update.js
  obj[#10] --< V(*) >--> obj[#13]
  obj[#10] --< P(*) >--> obj.*[#18]
  foo[#11] --< D >--> obj[#13]
  10[#12] --< V(*) >--> $v2[#21]
  obj[#13] --< P(*) >--> 10[#12]
  obj[#13] --< V(*) >--> obj[#16]
  $v1[#14] --< V(*) >--> $v2[#21]
  bar[#15] --< D >--> obj[#16]
  obj[#16] --< P(*) >--> $v1[#14]
  obj[#16] --< V(*) >--> obj[#24]
  foo[#17] --< D >--> obj.*[#18]
  obj.*[#18] --< V(*) >--> $v2[#21]
  bar[#19] --< D >--> $v2[#21]
  10[#20] -
  $v2[#21] --< P(*) >--> 10[#20]
  $v2[#21] --< V(*) >--> $v5[#33]
  $v3[#22] --< D >--> obj[#24]
  10[#23] --< V(*) >--> $v5[#33]
  obj[#24] --< P(*) >--> 10[#23]
  obj[#24] --< V(*) >--> obj[#29]
  10[#25] --< D >--> $v4[#27]
  "abc"[#26] --< D >--> $v4[#27]
  $v4[#27] --< D >--> obj[#29]
  true[#28] --< V(*) >--> $v5[#33]
  obj[#29] --< P(*) >--> true[#28]
  baz[#30] --< D >--> obj.*[#18]
  $v6[#31] --< D >--> $v5[#33]
  10[#32] -
  $v5[#33] --< P(*) >--> 10[#32]
  undef[#34] --< V(*) >--> undef[#37]
  foo[#35] --< D >--> undef[#37]
  10[#36] -
  undef[#37] --< P(*) >--> 10[#36]

Graph.js MDG Builder: static access
  $ graphjs mdg --no-export static_access.js
  obj[#10] --< V(foo) >--> obj[#12]
  obj[#10] --< P(baz) >--> obj.baz[#15]
  obj[#10] --< P(foo) >--> obj.foo[#18]
  obj[#10] --< P(bar) >--> obj.bar[#20]
  10[#11] -
  obj[#12] --< P(foo) >--> 10[#11]
  obj[#12] --< V(bar) >--> obj[#14]
  $v1[#13] -
  obj[#14] --< P(bar) >--> $v1[#13]
  obj[#14] --< V(qux) >--> obj[#19]
  obj.baz[#15] --< V(p) >--> obj.baz[#17]
  10[#16] -
  obj.baz[#17] --< P(p) >--> 10[#16]
  obj.foo[#18] -
  obj[#19] --< P(qux) >--> 10[#11]
  obj[#19] --< V(qux) >--> obj[#21]
  obj.bar[#20] -
  obj[#21] --< P(qux) >--> $v1[#13]

Graph.js MDG Builder: dynamic access
  $ graphjs mdg --no-export dynamic_access.js
  obj[#10] --< V(*) >--> obj[#13]
  obj[#10] --< P(*) >--> obj.*[#18]
  foo[#11] --< D >--> obj[#13]
  10[#12] --< V(*) >--> $v2[#21]
  obj[#13] --< P(*) >--> 10[#12]
  obj[#13] --< V(*) >--> obj[#16]
  $v1[#14] --< V(*) >--> $v2[#21]
  bar[#15] --< D >--> obj[#16]
  obj[#16] --< P(*) >--> $v1[#14]
  obj[#16] --< V(*) >--> obj[#24]
  baz[#17] --< D >--> obj.*[#18]
  obj.*[#18] --< V(*) >--> $v2[#21]
  p[#19] --< D >--> $v2[#21]
  10[#20] -
  $v2[#21] --< P(*) >--> 10[#20]
  foo[#22] --< D >--> obj.*[#18]
  qux[#23] --< D >--> obj[#24]
  obj[#24] --< P(*) >--> $v2[#21]
  obj[#24] --< V(*) >--> obj[#27]
  bar[#25] --< D >--> obj.*[#18]
  qux[#26] --< D >--> obj[#27]
  obj[#27] --< P(*) >--> $v2[#21]

Graph.js MDG Builder: static method
  $ graphjs mdg --no-export static_method.js
  obj[#10] --< V(foo) >--> obj[#14]
  obj[#10] --< P(foo) >--> obj.foo[#22]
  obj[#10] --< P(bar) >--> obj.bar[#28]
  obj[#10] --< P(baz) >--> obj.baz[#32]
  [[function]] $v1[#11] --< Param(0) >--> this[#12]
  [[function]] $v1[#11] --< Param(1) >--> x1[#13]
  this[#12] -
  x1[#13] -
  obj[#14] --< P(foo) >--> [[function]] $v1[#11]
  obj[#14] --< V(bar) >--> obj[#20]
  [[function]] $v2[#15] --< Param(0) >--> this[#16]
  [[function]] $v2[#15] --< Param(1) >--> y1[#17]
  [[function]] $v2[#15] --< Param(2) >--> y2[#18]
  [[function]] $v2[#15] --< Param(3) >--> y3[#19]
  this[#16] -
  y1[#17] -
  y2[#18] -
  y3[#19] -
  obj[#20] --< P(bar) >--> [[function]] $v2[#15]
  obj[#20] --< Arg(0) >--> obj.foo(...)[#23]
  obj[#20] --< Arg(0) >--> obj.bar(...)[#29]
  obj[#20] --< Arg(0) >--> obj.baz(...)[#33]
  10[#21] --< Arg(1) >--> obj.foo(...)[#23]
  obj.foo[#22] -
  obj.foo(...)[#23] --< Call >--> [[function]] $v1[#11]
  obj.foo(...)[#23] --< D >--> $v3[#24]
  $v3[#24] -
  10[#25] --< Arg(1) >--> obj.bar(...)[#29]
  "abc"[#26] --< Arg(2) >--> obj.bar(...)[#29]
  true[#27] --< Arg(3) >--> obj.bar(...)[#29]
  obj.bar[#28] -
  obj.bar(...)[#29] --< Call >--> [[function]] $v2[#15]
  obj.bar(...)[#29] --< D >--> $v4[#30]
  $v4[#30] -
  10[#31] --< Arg(1) >--> obj.baz(...)[#33]
  obj.baz[#32] -
  obj.baz(...)[#33] --< Call >--> obj.baz[#32]
  obj.baz(...)[#33] --< D >--> $v5[#34]
  $v5[#34] -
  undef[#35] --< P(foo) >--> undef.foo[#36]
  undef.foo[#36] -

Graph.js MDG Builder: dynamic method
  $ graphjs mdg --no-export dynamic_method.js
  obj[#10] --< V(foo) >--> obj[#14]
  obj[#10] --< P(*) >--> foo[#21]
  [[function]] $v1[#11] --< Param(0) >--> this[#12]
  [[function]] $v1[#11] --< Param(1) >--> x1[#13]
  [[function]] $v1[#11] --< P(*) >--> $v9.*[#44]
  [[function]] $v1[#11] --< Arg(0) >--> $v9.*(...)[#45]
  this[#12] -
  x1[#13] -
  obj[#14] --< P(foo) >--> [[function]] $v1[#11]
  obj[#14] --< V(bar) >--> obj[#20]
  [[function]] $v2[#15] --< Param(0) >--> this[#16]
  [[function]] $v2[#15] --< Param(1) >--> y1[#17]
  [[function]] $v2[#15] --< Param(2) >--> y2[#18]
  [[function]] $v2[#15] --< Param(3) >--> y3[#19]
  [[function]] $v2[#15] --< P(*) >--> $v9.*[#44]
  [[function]] $v2[#15] --< Arg(0) >--> $v9.*(...)[#45]
  this[#16] -
  y1[#17] -
  y2[#18] -
  y3[#19] -
  obj[#20] --< P(bar) >--> [[function]] $v2[#15]
  obj[#20] --< Arg(0) >--> obj.*(...)[#23]
  obj[#20] --< Arg(0) >--> obj.*(...)[#29]
  obj[#20] --< Arg(0) >--> obj.*(...)[#33]
  obj[#20] --< Arg(0) >--> obj.*(...)[#39]
  foo[#21] --< D >--> foo[#21]
  foo[#21] --< P(*) >--> $v9.*[#44]
  foo[#21] --< Arg(0) >--> $v9.*(...)[#45]
  10[#22] --< Arg(1) >--> obj.*(...)[#23]
  obj.*(...)[#23] --< Call >--> [[function]] $v1[#11]
  obj.*(...)[#23] --< Call >--> [[function]] $v2[#15]
  obj.*(...)[#23] --< Call >--> foo[#21]
  obj.*(...)[#23] --< D >--> $v3[#24]
  $v3[#24] -
  bar[#25] --< D >--> foo[#21]
  10[#26] --< Arg(1) >--> obj.*(...)[#29]
  "abc"[#27] --< Arg(2) >--> obj.*(...)[#29]
  true[#28] --< Arg(3) >--> obj.*(...)[#29]
  obj.*(...)[#29] --< Call >--> [[function]] $v1[#11]
  obj.*(...)[#29] --< Call >--> [[function]] $v2[#15]
  obj.*(...)[#29] --< Call >--> foo[#21]
  obj.*(...)[#29] --< D >--> $v4[#30]
  $v4[#30] -
  $v5[#31] --< D >--> foo[#21]
  10[#32] --< Arg(1) >--> obj.*(...)[#33]
  obj.*(...)[#33] --< Call >--> [[function]] $v1[#11]
  obj.*(...)[#33] --< Call >--> [[function]] $v2[#15]
  obj.*(...)[#33] --< Call >--> foo[#21]
  obj.*(...)[#33] --< D >--> $v6[#34]
  $v6[#34] -
  10[#35] --< D >--> $v7[#37]
  "abc"[#36] --< D >--> $v7[#37]
  $v7[#37] --< D >--> foo[#21]
  true[#38] --< Arg(1) >--> obj.*(...)[#39]
  obj.*(...)[#39] --< Call >--> [[function]] $v1[#11]
  obj.*(...)[#39] --< Call >--> [[function]] $v2[#15]
  obj.*(...)[#39] --< Call >--> foo[#21]
  obj.*(...)[#39] --< D >--> $v8[#40]
  $v8[#40] -
  baz[#41] --< D >--> foo[#21]
  $v10[#42] --< D >--> $v9.*[#44]
  10[#43] --< Arg(1) >--> $v9.*(...)[#45]
  $v9.*[#44] -
  $v9.*(...)[#45] --< Call >--> $v9.*[#44]
  $v9.*(...)[#45] --< D >--> $v11[#46]
  $v11[#46] -
  undef[#47] --< P(*) >--> undef.*[#49]
  bar[#48] --< D >--> undef.*[#49]
  undef.*[#49] -
